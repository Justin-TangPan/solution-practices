"""Static fact extraction; skips secrets and never evaluates project code."""
from __future__ import annotations
import re
from pathlib import Path
from .models import ContentItem, DocumentModel, Metadata, Section, SourceRef

SKIP_NAMES={".env",".secrets",".git","node_modules","__pycache__",".terraform"}
ALLOWED={".tf",".hcl",".yaml",".yml",".json",".md",".txt",".sh",".py",".js",".ts",".toml",".ini"}

def analyze_project(root: str | Path) -> DocumentModel:
    root=Path(root).resolve()
    model=DocumentModel(Metadata(project_id=root.name,solution_name=root.name))
    facts={"entrypoints":set(),"commands":set(),"ports":set(),"environment_variables":set(),"terraform_variables":set(),"images":set()}
    for p in sorted(root.rglob("*")):
        if not p.is_file() or p.suffix.lower() not in ALLOWED or any(x in SKIP_NAMES or x.startswith(".env") for x in p.parts): continue
        try: text=p.read_text(encoding="utf-8",errors="strict")
        except (UnicodeError,OSError): continue
        rel=str(p.relative_to(root)); model.metadata.source_files.append(rel)
        if p.name.lower() in {"dockerfile","compose.yaml","docker-compose.yml","main.py","app.py","main.tf"}: facts["entrypoints"].add(rel)
        facts["ports"].update(re.findall(r"(?<![\w.])(?:port\s*[:=]\s*|EXPOSE\s+)(\d{2,5})",text,re.I))
        facts["environment_variables"].update(re.findall(r"\b(?:os\.environ\[|getenv\(|\$\{?)([A-Z][A-Z0-9_]{2,})(?:['\"}\)]|\b)",text))
        facts["terraform_variables"].update(re.findall(r'variable\s+"([A-Za-z0-9_-]+)"',text))
        facts["images"].update(re.findall(r"(?:image\s*[:=]\s*|FROM\s+)([\w./:-]+)",text,re.I))
        facts["commands"].update(x.strip() for x in re.findall(r"(?m)^\s*(?:command\s*:\s*|RUN\s+)([^\n]+)",text))
    for key, values in facts.items():
        sec=Section(key,key.replace("_"," ").title())
        for value in sorted(values):
            sec.items.append(ContentItem(str(value),[SourceRef("project scan",key,True)],manual_confirmation=key in {"ports","commands"},confidence=.9))
        if sec.items: model.sections.append(sec)
    if not model.sections: model.review.missing_items.append("No supported technical facts found")
    return model
