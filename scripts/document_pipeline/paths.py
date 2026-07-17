"""Canonical site-level document paths."""
from pathlib import Path

def docs_dir(practice,site="cn",locale="zh-cn",create=False):
    root=Path(practice)
    if site=="cn": candidates=[root/"cn"/"docs"]
    else: candidates=[root/"intl"/"docs"/locale,root/"intl"/locale/"docs"]
    chosen=next((p for p in candidates if p.is_dir()),candidates[0])
    if create: chosen.mkdir(parents=True,exist_ok=True)
    return chosen
def document_filename(name,document_type,locale,extension="md"):
    if document_type=="deployment-guide": suffix="Deployment-Guide" if locale.startswith("en") else "部署指南"
    else: suffix="Solution-Details" if locale.startswith("en") else "方案详情"
    language_suffix="_en" if locale.startswith("en") else "_zh"
    return f"{name}-{suffix}{language_suffix}.{extension}"
