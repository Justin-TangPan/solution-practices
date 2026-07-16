from pathlib import Path
from zipfile import ZipFile, BadZipFile
from xml.etree import ElementTree as ET
from .models import ContentItem, DocumentModel, Metadata, Section, SourceRef

W="{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
def parse_word(path):
    p=Path(path); model=DocumentModel(Metadata(project_id=p.stem,solution_name=p.stem)); model.metadata.source_files=[str(p)]
    try:
        with ZipFile(p) as z: root=ET.fromstring(z.read("word/document.xml"))
    except (BadZipFile,KeyError,ET.ParseError) as e: raise ValueError(f"Invalid DOCX: {e}") from e
    current=Section("content","Content"); model.sections.append(current)
    for para in root.iter(W+"p"):
        text="".join((n.text or "") for n in para.iter(W+"t")).strip()
        if not text: continue
        style=para.find(".//"+W+"pStyle"); val=style.get(W+"val","") if style is not None else ""
        if val.lower().startswith("heading"):
            current=Section(text.lower().replace(" ","-"),text); model.sections.append(current)
        else: current.items.append(ContentItem(text,[SourceRef(str(p),"docx")]))
    return model
