from pathlib import Path
from .models import DocumentModel, Section

def render_markdown(model: DocumentModel, output=None):
    lines=[f"# {model.metadata.solution_name or model.metadata.project_id}",""]
    def emit(sec: Section, level=2):
        lines.extend(["#"*min(level,6)+" "+sec.title,""])
        for item in sec.items: lines.extend([item.content,"", *( ["> ⚠ 待人工确认",""] if item.manual_confirmation else [] )])
        for child in sec.children: emit(child,level+1)
    for sec in model.sections: emit(sec)
    value="\n".join(lines).rstrip()+"\n"
    if output:
        p=Path(output); p.parent.mkdir(parents=True,exist_ok=True); p.write_text(value,encoding="utf-8")
    return value
