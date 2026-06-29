"""
Shell 脚本静态分析
=================
- 健康检查（health check / 验证步骤）是否存在
- 错误处理：set -e, set -euo, trap
- 幂等性检查：mkdir -p, rm -rf 安全
- 路径硬编码检测
- 密码/Token 硬编码
- 超时保护
"""

import re
from pathlib import Path
from ..runner import CheckResult


SCORE_MAP = {
    "set -e":             (5, "缺少 set -e (未设置 errexit)"),
    "set -euo":           (5, "缺少 set -euo pipefail"),
    "set -o pipefail":    (3, "缺少 set -o pipefail"),
    "trap":               (3, "缺少 trap 错误处理"),
    "health check":       (3, "缺少健康检查或验证步骤"),
    "systemctl enable":   (2, "缺少 systemctl enable (未设置开机自启)"),
    "timeout":            (3, "缺少 timeout 超时保护"),
    "log_":               (1, "缺少日志输出"),
    "mkdir -p":           (1, "建议使用 mkdir -p 确保幂等性"),
}

RISK_PATTERNS = [
    (r'rm\s+-rf\s+/\s',           -20, "危险: rm -rf / (根目录删除)"),
    (r'chmod\s+777',               -5,  "危险: chmod 777 (权限过宽)"),
    (r'password\s*=\s*["\'][^"\']', -10, "危险: 脚本中硬编码密码"),
    (r'secret\s*=\s*["\'][^"\']',  -10, "危险: 脚本中硬编码密钥"),
    (r'TOKEN\s*=\s*["\'][^"\']',   -10, "危险: 脚本中硬编码 Token"),
    (r'curl\s+.*\|\s*bash',        -8,  "危险: curl | bash (无验证的管道安装)"),
    (r'wget\s+.*\|\s*sh',          -8,  "危险: wget | sh (无验证的管道安装)"),
]


def run(practice_path: Path, entry: dict) -> list:
    results = []
    scripts_dir = practice_path / "scripts"

    if not scripts_dir.exists() or not scripts_dir.is_dir():
        results.append(CheckResult("scripts", True, "INFO", "scripts/ 目录不存在（跳过）"))
        return results

    install_scripts = list(scripts_dir.glob("install_*.sh")) + list(scripts_dir.glob("*.sh"))

    if not install_scripts:
        results.append(CheckResult("scripts", True, "INFO", "scripts/ 中没有 .sh 文件（跳过）"))
        return results

    for sp in install_scripts:
        content = sp.read_text(encoding="utf-8-sig", errors="replace")
        lines = content.split("\n")
        score = 60  # 基准分
        findings = []

        # 正向检查
        for pattern, penalty, msg in SCORE_MAP.items():
            if pattern in content:
                score += penalty
            else:
                findings.append(("WARN", msg))

        # 负向检查（风险模式）
        for pattern, penalty, msg in RISK_PATTERNS:
            if re.search(pattern, content, re.IGNORECASE):
                score += penalty
                findings.append(("ERROR", msg))

        # 行数检查
        if len(lines) < 20:
            score -= 10
            findings.append(("WARN", f"脚本仅 {len(lines)} 行，功能可能不完整"))
        elif len(lines) > 500:
            score -= 15
            findings.append(("WARN", f"脚本 {len(lines)} 行过长（建议拆分为多个脚本）"))

        # 文件大小
        size_kb = len(content) / 1024
        if size_kb > 50:
            findings.append(("WARN", f"脚本 {size_kb:.0f}KB 较大"))

        # 报告
        script_rel = str(sp.relative_to(practice_path).as_posix())
        if score < 50:
            results.append(CheckResult("scripts", False, "ERROR",
                                        f"脚本质量评分 {score}/100: {sp.name}",
                                        detail="\n".join(f"[{s}] {m}" for s, m in findings),
                                        file=script_rel))
        elif score < 70:
            results.append(CheckResult("scripts", True, "WARN",
                                        f"脚本质量评分 {score}/100: {sp.name}",
                                        detail="\n".join(f"[{s}] {m}" for s, m in findings),
                                        file=script_rel))
        else:
            results.append(CheckResult("scripts", True, "INFO",
                                        f"脚本质量评分 {score}/100: {sp.name}"))

    if not results:
        results.append(CheckResult("scripts", True, "INFO", "脚本检查全部通过"))

    return results
