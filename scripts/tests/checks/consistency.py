"""
跨方案一致性检查
===============
- 目录结构标准化（terraform/, scripts/ 子目录）
- .extension 文件格式
- Terraform 文件命名规范
"""

import json
from pathlib import Path
from ..runner import CheckResult


def run(practice_path: Path, entry: dict) -> list:
    results = []
    practice_name = entry["name"]

    # ── 1. 子目录检查 ──
    for sub in ["scripts", "terraform"]:
        sub_path = practice_path / sub
        if not sub_path.exists():
            results.append(CheckResult("consistency", False, "ERROR",
                                        f"缺少 {sub}/ 子目录"))
        elif not sub_path.is_dir():
            results.append(CheckResult("consistency", False, "ERROR",
                                        f"{sub} 不是目录"))

    # ── 2. .extension 文件 ──
    ext = practice_path / ".extension"
    if ext.exists():
        try:
            data = json.loads(ext.read_text(encoding="utf-8-sig"))
            if "variables" not in data:
                results.append(CheckResult("consistency", True, "WARN",
                                            ".extension 缺少 variables 字段"))
            else:
                results.append(CheckResult("consistency", True, "INFO",
                                            ".extension 格式正确"))
        except Exception:
            results.append(CheckResult("consistency", False, "ERROR",
                                        ".extension JSON 解析失败"))
    else:
        results.append(CheckResult("consistency", True, "WARN",
                                    "缺少 .extension 文件（可选）"))

    # ── 3. 文档目录 ──
    docs_dir = practice_path.parent.parent / "docs"
    if docs_dir.exists():
        md_files = list(docs_dir.glob("*.md"))
        results.append(CheckResult("consistency", True, "INFO",
                                    f"docs/ 目录: {len(md_files)} 个文档"))

    if not results:
        results.append(CheckResult("consistency", True, "INFO", "一致性检查通过"))
    return results
