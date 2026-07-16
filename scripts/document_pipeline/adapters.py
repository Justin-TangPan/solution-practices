from pathlib import Path
from .markdown_parser import parse_markdown
from .models import ContentItem,DocumentModel,Metadata,Section,SourceRef
from .pdf_parser import parse_pdf
from .word_parser import parse_word

def load_input(path):
    p=Path(path)
    if p.is_dir():
        from .project_analyzer import analyze_project
        return analyze_project(p)
    ext=p.suffix.lower()
    if ext in {".md",".markdown"}: return parse_markdown(p)
    if ext==".docx": return parse_word(p)
    if ext==".pdf": return parse_pdf(p)
    if ext==".json":
        from .models import DocumentModel
        try: return DocumentModel.load(p)
        except (KeyError,TypeError): pass
    if ext not in {".txt",".yaml",".yml",".json"}: raise ValueError(f"Unsupported input type: {ext or '<none>'}")
    text=p.read_text(encoding="utf-8"); m=DocumentModel(Metadata(project_id=p.stem,solution_name=p.stem));m.metadata.source_files=[str(p)];m.sections=[Section("content","Content",[ContentItem(text,[SourceRef(str(p),ext.lstrip('.'))])])];return m
