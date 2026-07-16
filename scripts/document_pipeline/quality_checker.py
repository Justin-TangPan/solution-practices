from __future__ import annotations
from dataclasses import asdict,dataclass,field
from pathlib import Path
from zipfile import ZipFile,BadZipFile
import json,re
from .markdown_renderer import render_markdown
from .models import DocumentModel
from .security import scan_sensitive

@dataclass
class QualityReport:
    status:str="pass"; errors:list=field(default_factory=list); warnings:list=field(default_factory=list); info:list=field(default_factory=list); manual_review_items:list=field(default_factory=list); generated_files:list=field(default_factory=list); checked_sources:list=field(default_factory=list)
    def add(self,issue):
        issue=dict(issue)
        issue.setdefault("blocking",issue.get("severity")=="error")
        issue.setdefault("blocks_export",issue["blocking"])
        (self.errors if issue.get("severity")=="error" else self.warnings).append(issue)
    def finish(self): self.status="fail" if self.errors else ("warning" if self.warnings or self.manual_review_items else "pass"); return self
    def save(self,path):
        p=Path(path);p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(asdict(self),ensure_ascii=False,indent=2),encoding="utf-8");return p

REQUIRED={"deployment-guide":["prerequisite","deployment","verification","uninstall","limitation"],"solution-details":["summary","architecture","advantage","limitation"]}
def check_model(model:DocumentModel,files=()):
    r=QualityReport(checked_sources=model.metadata.source_files.copy(),manual_review_items=model.review.manual_confirmation_items.copy())
    all_sections=[]
    def walk(s): all_sections.append(s); [walk(c) for c in s.children]
    [walk(s) for s in model.sections]; joined="\n".join(s.title+"\n"+"\n".join(i.content for i in s.items) for s in all_sections)
    for need in REQUIRED.get(model.metadata.document_type,[]):
        if not any(need in (s.key+" "+s.title).lower() for s in all_sections): r.add({"severity":"warning","section":need,"message":"Required section not found","suggestion":"Add sourced content or mark for manual completion","blocking":False})
    for token in ("TODO","待补充","待技术确认","缺少来源"):
        if token.lower() in joined.lower(): r.add({"severity":"warning","message":f"Unresolved marker: {token}","blocking":False})
    for issue in scan_sensitive(joined): r.add(issue)
    for p in map(Path,files):
        r.generated_files.append(str(p))
        if not p.exists(): r.add({"severity":"error","document":str(p),"message":"Generated file missing","blocking":True}); continue
        if p.suffix.lower()==".md":
            text=p.read_text(encoding="utf-8");
            if text.count("```")%2: r.add({"severity":"error","document":str(p),"message":"Unclosed code fence","blocking":True})
        if p.suffix.lower()==".docx":
            try:
                with ZipFile(p) as z: z.read("word/document.xml")
            except (BadZipFile,KeyError): r.add({"severity":"error","document":str(p),"message":"Invalid DOCX package","blocking":True})
    if not all_sections: r.add({"severity":"error","message":"Document has no sections","blocking":True})
    return r.finish()
