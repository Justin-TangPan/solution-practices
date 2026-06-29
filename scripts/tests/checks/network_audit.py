"""
网络依赖扫描
===========
扫描解决方案脚本中的外部网络依赖，分类分级。

分级规则:
  REACHABLE — 华为云 OBS 域名，无需处理
  NEED_MIRROR — GitHub/Docker Hub/ghcr.io 在国内可能不通
  UNKNOWN — 无法判断，需人工确认
  HIGH_RISK — 裸脚本下载 (curl | bash)

生成依赖矩阵，帮助判断部署时是否需要镜像/代理。
"""

import re
from pathlib import Path
from typing import Optional
from ..runner import CheckResult


# ── 已知安全的华为云域名 ──
HUAWEI_DOMAINS = [
    "myhuaweicloud.com",
    "myhuaweicloud.cn",
    "huaweicloud.com",
    "huaweicloud.cn",
]

# ── 需要镜像的域名 ──
NEED_MIRROR_DOMAINS = [
    "github.com",
    "githubusercontent.com",
    "docker.com",
    "docker.io",
    "ghcr.io",
    "quay.io",
    "k8s.gcr.io",
    "registry.k8s.io",
    "gcr.io",
    "pypi.org",
    "pypi.python.org",
    "npmjs.org",
    "npmjs.com",
    "unpkg.com",
    "cdn.jsdelivr.net",
]

# ── 高危模式 ──
HIGH_RISK_PATTERNS = [
    (r'curl\s+-[a-zA-Z]*s?[a-zA-Z]*\s+https?://\S+\s*\|\s*(?:bash|sh)', "curl | bash 高危管道安装"),
    (r'wget\s+-[a-zA-Z]*[Oo]?\s+https?://\S+\s*\|\s*(?:bash|sh)', "wget | sh 高危管道安装"),
]


def classify_url(url: str) -> str:
    """对外部 URL 进行分级。"""
    for domain in HUAWEI_DOMAINS:
        if domain in url:
            return "REACHABLE"
    for domain in NEED_MIRROR_DOMAINS:
        if domain in url:
            return "NEED_MIRROR"
    return "UNKNOWN"


def extract_urls(content: str) -> list:
    """从文本中提取所有 HTTP(S) URL。"""
    urls = re.findall(r'https?://[a-zA-Z0-9./_%?=&@:#-]+', content)
    return urls


def run(practice_path: Path, entry: dict) -> list:
    results = []
    scripts_dir = practice_path / "scripts"
    tf_dir = practice_path / "terraform"

    all_deps = {}  # url -> list of files

    # 扫描脚本
    if scripts_dir and scripts_dir.exists():
        for sh_file in sorted(scripts_dir.glob("**/*.sh")):
            content = sh_file.read_text(encoding="utf-8-sig", errors="replace")
            urls = extract_urls(content)
            for url in urls:
                if url not in all_deps:
                    all_deps[url] = []
                all_deps[url].append(str(sh_file.relative_to(practice_path)))

    # 扫描 Terraform
    if tf_dir and tf_dir.exists():
        for tf_file in sorted(tf_dir.glob("*.tf")):
            content = tf_file.read_text(encoding="utf-8-sig", errors="replace")
            urls = extract_urls(content)
            for url in urls:
                if url not in all_deps:
                    all_deps[url] = []
                all_deps[url].append(str(tf_file.relative_to(practice_path)))

    if not all_deps:
        results.append(CheckResult("network", True, "INFO", "未发现外部网络依赖"))
        return results

    # 分析每个 URL
    high_risk_found = False
    need_mirror_count = 0

    for url, files in sorted(all_deps.items()):
        classification = classify_url(url)

        # 高危检查
        for pattern, desc in HIGH_RISK_PATTERNS:
            if re.search(pattern, url):
                classification = "HIGH_RISK"
                high_risk_found = True
                break

        if classification == "HIGH_RISK":
            results.append(CheckResult("network", False, "ERROR",
                                        f"高危网络依赖: {url[:100]}",
                                        detail=f"来源: {', '.join(files)}",
                                        file=files[0]))
        elif classification == "NEED_MIRROR":
            need_mirror_count += 1
            results.append(CheckResult("network", True, "WARN",
                                        f"需镜像: {url[:100]}",
                                        detail=f"来源: {', '.join(files)}",
                                        file=files[0]))
        elif classification == "UNKNOWN":
            results.append(CheckResult("network", True, "INFO",
                                        f"未知域名: {url[:100]}",
                                        detail=f"来源: {', '.join(files)}",
                                        file=files[0]))

    # 汇总
    if not high_risk_found and need_mirror_count == 0:
        results.append(CheckResult("network", True, "INFO",
                                    f"共发现 {len(all_deps)} 个外部依赖，均在华为云可控范围内"))

    return results
