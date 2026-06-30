"""
文档完整性检查
=============
- 部署指南存在性
- 方案详情存在性
- 文件大小合理性
"""

from pathlib import Path
from ..runner import CheckResult


def run(practice_path: Path, entry: dict) -> list:
    results = []
    docs_dir = practice_path.parent.parent / "docs"

    if not docs_dir.exists():
        results.append(CheckResult("docs", True, "INFO", "docs/ 目录不存在（跳过）"))
        return results

    md_files = list(docs_dir.glob("*.md"))
    if not md_files:
        results.append(CheckResult("docs", True, "WARN", "docs/ 中无 .md 文档"))
        return results

    has_deploy = any("部署" in f.name or "Deployment" in f.name for f in md_files)
    has_detail = any("Solution-Details" in f.name or "方案详情" in f.name for f in md_files)

    if has_deploy:
        results.append(CheckResult("docs", True, "INFO", "包含部署指南"))
    else:
        results.append(CheckResult("docs", True, "WARN", "缺少部署指南文档"))

    if has_detail:
        results.append(CheckResult("docs", True, "INFO", "包含方案详情"))

    for f in md_files:
        size = f.stat().st_size / 1024
        if size > 500:
            results.append(CheckResult("docs", True, "WARN",
                                        f"{f.name} 为 {size:.0f}KB，建议拆分"))

    return results
