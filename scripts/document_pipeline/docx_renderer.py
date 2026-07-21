"""Deterministic OOXML renderer with optional in-place template styling."""
from __future__ import annotations

from copy import deepcopy
from pathlib import Path
import re
from zipfile import ZIP_DEFLATED, ZipFile
from xml.etree import ElementTree as ET
from xml.sax.saxutils import escape

from .config import DEFAULT_STYLE, load_config
from .models import DocumentModel, Section


W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
W = f"{{{W_NS}}}"
R_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
ET.register_namespace("w", W_NS)

CONTENT_TYPES = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/docProps/custom.xml" ContentType="application/vnd.openxmlformats-officedocument.custom-properties+xml"/></Types>'''
RELS = '''<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>'''


def _p(text, style=None):
    prop = f'<w:pPr><w:pStyle w:val="{style}"/></w:pPr>' if style else ""
    return f'<w:p>{prop}<w:r><w:t xml:space="preserve">{escape(text)}</w:t></w:r></w:p>'


def _paragraph(text: str, style: str | None = None) -> ET.Element:
    paragraph = ET.Element(W + "p")
    if style:
        properties = ET.SubElement(paragraph, W + "pPr")
        ET.SubElement(properties, W + "pStyle", {W + "val": style})
    run = ET.SubElement(paragraph, W + "r")
    node = ET.SubElement(run, W + "t", {"{http://www.w3.org/XML/1998/namespace}space": "preserve"})
    node.text = text
    return paragraph


def _plain_markdown(text: str) -> str:
    text = re.sub(r"\[([^]]+)]\(([^)]+)\)", r"\1 (\2)", text)
    return text.replace("**", "").replace("__", "").replace("`", "").replace("<br>", "; ")


def _table_rows(lines: list[str]) -> list[list[str]] | None:
    if len(lines) < 2 or not all(line.strip().startswith("|") and line.strip().endswith("|") for line in lines):
        return None
    rows = [[_plain_markdown(cell.strip()) for cell in line.strip().strip("|").split("|")] for line in lines]
    if not all(re.fullmatch(r":?-{3,}:?", cell.replace(" ", "")) for cell in rows[1]):
        return None
    return [rows[0], *rows[2:]]


def _set_cell_text(cell: ET.Element, text: str) -> None:
    properties = cell.find(W + "tcPr")
    for child in list(cell):
        if child is not properties:
            cell.remove(child)
    cell.append(_paragraph(text, "TableParagraph"))


def _set_paragraph_text(paragraph: ET.Element, text: str) -> None:
    properties = paragraph.find(W + "pPr")
    first_run = paragraph.find(W + "r")
    run_properties = deepcopy(first_run.find(W + "rPr")) if first_run is not None and first_run.find(W + "rPr") is not None else None
    for child in list(paragraph):
        if child is not properties:
            paragraph.remove(child)
    run = ET.SubElement(paragraph, W + "r")
    if run_properties is not None:
        run.append(run_properties)
    node = ET.SubElement(run, W + "t", {"{http://www.w3.org/XML/1998/namespace}space": "preserve"})
    node.text = text


def _table(rows: list[list[str]], templates: list[ET.Element]) -> ET.Element:
    columns = max(len(row) for row in rows)
    source = next(
        (table for table in templates if max((len(row.findall(W + "tc")) for row in table.findall(W + "tr")), default=0) == columns),
        None,
    )
    if source is None:
        table = ET.Element(W + "tbl")
        header_source = body_source = None
    else:
        table = deepcopy(source)
        source_rows = table.findall(W + "tr")
        header_source = source_rows[0] if source_rows else None
        body_source = source_rows[1] if len(source_rows) > 1 else header_source
        for row in source_rows:
            table.remove(row)
    for index, values in enumerate(rows):
        row_source = header_source if index == 0 else body_source
        row = deepcopy(row_source) if row_source is not None else ET.Element(W + "tr")
        cells = row.findall(W + "tc")
        while len(cells) < columns:
            cells.append(ET.SubElement(row, W + "tc"))
        for position, cell in enumerate(cells):
            _set_cell_text(cell, values[position] if position < len(values) else "")
        table.append(row)
    return table


def _content_elements(content: str, table_templates: list[ET.Element]) -> list[ET.Element]:
    result: list[ET.Element] = []
    lines = content.splitlines()
    index = 0
    in_code = False
    code: list[str] = []
    paragraph: list[str] = []

    def flush_paragraph():
        if paragraph:
            result.append(_paragraph(_plain_markdown(" ".join(paragraph)), "BodyText"))
            paragraph.clear()

    while index < len(lines):
        stripped = lines[index].strip()
        if stripped.startswith("```"):
            flush_paragraph()
            if in_code:
                result.append(_paragraph("\n".join(code), "BodyText"))
                code.clear()
            in_code = not in_code
            index += 1
            continue
        if in_code:
            code.append(lines[index])
            index += 1
            continue
        if stripped.startswith("|"):
            flush_paragraph()
            end = index
            while end < len(lines) and lines[end].strip().startswith("|"):
                end += 1
            rows = _table_rows(lines[index:end])
            if rows:
                result.append(_table(rows, table_templates))
                index = end
                continue
        if not stripped or stripped == "---":
            flush_paragraph()
        elif re.match(r"^[-*]\s+", stripped):
            flush_paragraph()
            result.append(_paragraph("• " + _plain_markdown(re.sub(r"^[-*]\s+", "", stripped)), "ListParagraph"))
        elif re.match(r"^\d+[.)]\s+", stripped):
            flush_paragraph()
            result.append(_paragraph(_plain_markdown(stripped), "ListParagraph"))
        elif stripped.startswith(">"):
            flush_paragraph()
            result.append(_paragraph(_plain_markdown(stripped.lstrip("> ")), "BodyText"))
        else:
            paragraph.append(stripped)
        index += 1
    flush_paragraph()
    if code:
        result.append(_paragraph("\n".join(code), "BodyText"))
    return result


def _template_document(model: DocumentModel, document_xml: bytes) -> tuple[bytes, str, str]:
    root = ET.fromstring(document_xml)
    body = root.find(W + "body")
    if body is None:
        raise ValueError("DOCX template has no document body")
    original = list(body)
    table_templates = root.findall(".//" + W + "tbl")
    first_heading = next(
        (
            index
            for index, node in enumerate(original)
            if node.tag == W + "p"
            and (style := node.find("./" + W + "pPr/" + W + "pStyle")) is not None
            and style.get(W + "val") == "Heading1"
        ),
        len(original),
    )
    prefix = original[:first_heading]
    final_section = next((deepcopy(node) for node in reversed(original) if node.tag == W + "sectPr"), None)
    top_title = model.sections[0].title if model.sections else model.metadata.solution_name or model.metadata.project_id
    display_match = re.search(r"\b(Supabase)\b", top_title, re.IGNORECASE)
    display_name = display_match.group(1) if display_match else (model.metadata.project_id.split("-")[0] or "Solution")
    preamble = "\n".join(item.content for item in model.sections[0].items) if model.sections else ""
    plain_preamble = _plain_markdown(preamble).replace(">", "")
    version_match = re.search(r"文档版本[：:]\s*(\S+)", plain_preamble)
    date_match = re.search(r"发布日期[：:]\s*(\d{4}-\d{2}-\d{2})", plain_preamble)
    cover_replaced = False

    for node in prefix:
        text = "".join(part.text or "" for part in node.iter(W + "t"))
        if node.tag == W + "p" and "LiteLLM" in text and not cover_replaced:
            _set_paragraph_text(node, top_title)
            cover_replaced = True
        elif node.tag == W + "p" and text.startswith("文档版本") and version_match:
            _set_paragraph_text(node, f"文档版本\t{version_match.group(1)}")
        elif node.tag == W + "p" and text.startswith("发布日期") and date_match:
            _set_paragraph_text(node, f"发布日期\t{date_match.group(1)}")
        elif "LiteLLM" in text:
            for part in node.iter(W + "t"):
                if part.text:
                    part.text = part.text.replace("LiteLLM", display_name)

    for node in list(body):
        body.remove(node)
    body.extend(prefix)

    sections = model.sections
    if sections and ("部署指南" in sections[0].title or "Deployment Guide" in sections[0].title):
        sections = sections[0].children

    def emit(section: Section, level: int = 1):
        body.append(_paragraph(section.title, f"Heading{min(level, 5)}"))
        for item in section.items:
            body.extend(_content_elements(item.content, table_templates))
        for child in section.children:
            emit(child, level + 1)

    for section in sections:
        emit(section)
    if final_section is not None:
        body.append(final_section)
    return ET.tostring(root, encoding="utf-8", xml_declaration=True), display_name, top_title


def _render_from_template(model: DocumentModel, output: Path, template: Path) -> Path:
    with ZipFile(template) as source:
        document, display_name, top_title = _template_document(model, source.read("word/document.xml"))
        replacements = {"word/document.xml": document}
        used_relationships = {
            value
            for node in ET.fromstring(document).iter()
            for attribute, value in node.attrib.items()
            if attribute.startswith(f"{{{R_NS}}}")
        }
        if "word/_rels/document.xml.rels" in source.namelist():
            relationships = ET.fromstring(source.read("word/_rels/document.xml.rels"))
            for relationship in list(relationships):
                if relationship.get("Type", "").endswith("/hyperlink") and relationship.get("Id") not in used_relationships:
                    relationships.remove(relationship)
            replacements["word/_rels/document.xml.rels"] = ET.tostring(
                relationships, encoding="utf-8", xml_declaration=True
            )
        for name in source.namelist():
            if name.startswith("word/header") and name.endswith(".xml") or name == "docProps/core.xml":
                replacements[name] = (
                    source.read(name)
                    .replace("LiteLLM，统一的 AI 管理网关".encode(), top_title.encode())
                    .replace(b"LiteLLM", display_name.encode())
                )
        with ZipFile(output, "w", ZIP_DEFLATED) as target:
            for info in source.infolist():
                target.writestr(info, replacements.get(info.filename, source.read(info.filename)))
    return output


def render_docx(model: DocumentModel, output, template=None, style_config=None):
    output = Path(output)
    output.parent.mkdir(parents=True, exist_ok=True)
    cfg = {**DEFAULT_STYLE, **load_config(style_config)}
    if template:
        template = Path(template)
        if not template.exists():
            raise FileNotFoundError(f"DOCX template not found: {template}")
        return _render_from_template(model, output, template)

    body = [_p(model.metadata.solution_name or model.metadata.project_id, "Title")]

    def emit(sec: Section, level=1):
        body.append(_p(sec.title, f"Heading{min(level, 2)}"))
        for item in sec.items:
            style = "Code" if item.content.strip().startswith("```") else None
            body.append(_p(item.content, style))
        for child in sec.children:
            emit(child, level + 1)

    for sec in model.sections:
        emit(sec)
    margin = cfg["page"]["margin_twips"] if isinstance(cfg.get("page"), dict) else 1440
    document = f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="{W_NS}"><w:body>{''.join(body)}<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="{margin}" w:right="{margin}" w:bottom="{margin}" w:left="{margin}"/></w:sectPr></w:body></w:document>'''
    font = cfg.get("fonts", {}).get(model.metadata.locale, "Arial") if isinstance(cfg.get("fonts"), dict) else "Arial"
    styles = f'''<?xml version="1.0" encoding="UTF-8"?><w:styles xmlns:w="{W_NS}"><w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:rPr><w:rFonts w:ascii="{escape(font)}" w:eastAsia="{escape(font)}"/><w:sz w:val="22"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:rPr><w:b/><w:sz w:val="40"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:rPr><w:b/><w:sz w:val="32"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:rPr><w:b/><w:sz w:val="28"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Code"><w:name w:val="Code"/><w:rPr><w:rFonts w:ascii="Consolas"/><w:sz w:val="18"/></w:rPr></w:style></w:styles>'''
    custom = f'''<?xml version="1.0"?><Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/custom-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"><property fmtid="{{D5CDD505-2E9C-101B-9397-08002B2CF9AE}}" pid="2" name="TemplateVersion"><vt:lpwstr>{escape(model.metadata.template_version)}</vt:lpwstr></property></Properties>'''
    with ZipFile(output, "w", ZIP_DEFLATED) as archive:
        archive.writestr("[Content_Types].xml", CONTENT_TYPES)
        archive.writestr("_rels/.rels", RELS)
        archive.writestr("word/document.xml", document)
        archive.writestr("word/styles.xml", styles)
        archive.writestr("docProps/custom.xml", custom)
    return output
