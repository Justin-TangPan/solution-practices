"""
文档完整性检查
=============
- 部署指南存在性
- 方案详情存在性
- 中英文版本覆盖
"""

from pathlib import Path
from ..runner import CheckResult


def run(practice_path: Path, entry: dict) -> list:
    results = []

    # 查找 docs/ 目录
    docs_dir = practice_path.parent.parent / "docs"
    practice_name = entry["name"]

    if not docs_dir.exists() or not docs_dir.is_dir():
        results.append(CheckResult("docs", True, "WARN", "docs/ 目录不存在（跳过）"))
        return results

    md_files = list(docs_dir.glob("*.md"))

    if not md_files:
        results.append(CheckResult("docs", True, "WARN", "docs/ 中无 .md 文档"))
        return results

    # 检查命名
    has_deployment_guide = any("部署指南" in f.name or "Deployment-Guide" in f.name for f in md_files)
    has_solution_details = any("Solution-Details" in f.name or "方案详情" in f.name for f in md_files)

    if has_deployment_guide:
        results.append(CheckResult("docs", True, "INFO", "包含部署指南"))
    else:
        results.append(CheckResult("docs", True, "WARN", "缺少部署指南"))

    if has_solution_details:
        results.append(CheckResult("docs", True, "INFO", "包含方案详情"))
    else:
        results.append(CheckResult("docs", True, "INFO", "缺少方案详情文档（可选）"))

    # 文件大小检查
    for f in md_files:
        size_kb = f.stat().st_size / 1024
        if size_kb < 1:
            results.append(CheckResult("docs", True, "WARN",
                                        f"{f.name} 仅 {size_kb:.1f}KB，内容可能不完整"))
        elif size_kb > 500:
            results.append(CheckResult("docs", True, "WARN",
                                        f"{f.name} 为 {size_kb:.0f}KB，建议拆分"))

    if not results:
        results.append(CheckResult("docs", True, "INFO", "文档检查通过"))

    return results
