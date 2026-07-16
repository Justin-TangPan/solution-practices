from __future__ import annotations
import re
from pathlib import Path
from .models import ContentItem, DocumentModel, Metadata, Section, SourceRef


def parse_markdown(path: str | Path, metadata: Metadata | None = None) -> DocumentModel:
    p = Path(path); text = p.read_text(encoding="utf-8")
    model = DocumentModel(metadata or Metadata(project_id=p.stem, solution_name=p.stem))
    model.metadata.source_files.append(str(p))
    stack: list[tuple[int, Section]] = []
    current: Section | None = None
    buffer: list[str] = []
    in_code = False
    def flush():
        nonlocal buffer
        content = "\n".join(buffer).strip()
        if content:
            target = current or Section("summary", "Summary")
            if current is None and target not in model.sections: model.sections.append(target)
            target.items.append(ContentItem(content, [SourceRef(str(p), "markdown", False)]))
        buffer = []
    for line in text.splitlines():
        if line.strip().startswith("```"): in_code = not in_code
        m = None if in_code else re.match(r"^(#{1,6})\s+(.+?)\s*$", line)
        if m:
            flush(); level=len(m.group(1)); title=m.group(2); sec=Section(re.sub(r"\W+", "-", title.lower()).strip("-") or "section", title)
            while stack and stack[-1][0] >= level: stack.pop()
            (stack[-1][1].children if stack else model.sections).append(sec); stack.append((level,sec)); current=sec
        else: buffer.append(line)
    flush()
    return model
