from pathlib import Path
import shutil, subprocess
from .models import ContentItem, DocumentModel, Metadata, Section, SourceRef

def parse_pdf(path):
    p=Path(path)
    if not shutil.which("pdftotext"): raise RuntimeError("Offline PDF parser unavailable: install pdftotext; no online fallback is used")
    proc=subprocess.run(["pdftotext","-layout",str(p),"-"],capture_output=True,text=True,timeout=60)
    if proc.returncode: raise ValueError("PDF extraction failed: "+proc.stderr.strip()[:300])
    model=DocumentModel(Metadata(project_id=p.stem,solution_name=p.stem)); model.metadata.source_files=[str(p)]
    sec=Section("recovered-content","Recovered content")
    for page_no,page in enumerate(proc.stdout.split("\f"),1):
        if page.strip(): sec.items.append(ContentItem(page.strip(),[SourceRef(str(p),"pdf",False,f"page {page_no}")],manual_confirmation=True,confidence=.6))
    model.sections=[sec]; model.review.manual_confirmation_items.append("Verify PDF structure, tables, images, headers and footers against source pages")
    return model
