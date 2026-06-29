"""
跨方案一致性检查
===============
- 目录结构标准化（terraform/, scripts/, docs/）
- .extension 文件格式
- Terraform 文件命名规范
- Docker Compose 文件存在性
"""

import json
from pathlib import Path
from ..runner import CheckResult


EXPECTED_SUBDIRS = ["scripts", "terraform"]


def run(practice_path: Path, entry: dict) -> list:
    results = []

    # ── 1. 子目录检查 ──
    for sub in EXPECTED_SUBDIRS:
        sub_path = practice_path / sub
        if not sub_path.exists():
            results.append(CheckResult("consistency", False, "ERROR",
                                        f"缺少 {sub}/ 子目录"))
        elif not sub_path.is_dir():
            results.append(CheckResult("consistency", False, "ERROR",
                                        f"{sub} 不是目录"))

    # ── 2. .extension 文件 ──
    ext_path = practice_path / ".extension"
    if ext_path.exists():
        try:
            ext_data = json.loads(ext_path.read_text(encoding="utf-8-sig", errors="replace"))
            if not isinstance(ext_data, dict) or "variables" not in ext_data:
                results.append(CheckResult("consistency", True, "WARN",
                                            ".extension 缺少 variables 字段"))
            results.append(CheckResult("consistency", True, "INFO",
                                        ".extension 格式正确"))
        except (json.JSONDecodeError, Exception):
            results.append(CheckResult("consistency", False, "ERROR",
                                        ".extension JSON 解析失败"))
    else:
        results.append(CheckResult("consistency", True, "WARN",
                                    "缺少 .extension 文件（可选但建议添加）"))

    # ── 3. Terraform 文件命名 ──
    tf_path = practice_path / "terraform"
    if tf_path.exists():
        tf_files = list(tf_path.glob("*.tf"))
        for f in tf_files:
            # 检查文件名是否包含 practice 名称
            name = entry.get("name", "")
            region = entry.get("region", "")
            if name and region and name not in f.stem and f.stem not in ("versions", "providers", "variables", "main", "outputs"):
                results.append(CheckResult("consistency", True, "WARN",
                                            f"Terraform 文件名 {f.name} 不包含 practice 名称 '{name}'"))

        # 检查是否有 .tf.json 文件
        tf_json_files = list(tf_path.glob("*.tf.json"))
        if tf_json_files:
            results.append(CheckResult("consistency", True, "INFO",
                                        f"发现 {len(tf_json_files)} 个 .tf.json 文件"))

    # ── 4. Docker Compose ──
    compose_files = list(practice_path.glob("**/docker-compose.y*ml"))
    if compose_files:
        results.append(CheckResult("consistency", True, "INFO",
                                    f"包含 Docker Compose: {compose_files[0].name}"))
    else:
        scripts_dir = practice_path / "scripts"
        if scripts_dir.exists():
            for f in scripts_dir.glob("*"):
                if "compose" in f.name.lower() or "docker" in f.name.lower():
                    results.append(CheckResult("consistency", True, "INFO",
                                                f"发现容器相关文件: {f.name}"))
                    break

    if not results:
        results.append(CheckResult("consistency", True, "INFO", "一致性检查通过"))

    return results
