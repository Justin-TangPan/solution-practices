"""Deterministic minimal OOXML renderer; accepts an optional neutral DOCX template."""
from __future__ import annotations
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile
from xml.sax.saxutils import escape
import shutil
from .config import DEFAULT_STYLE, load_config
from .models import DocumentModel, Section

CONTENT_TYPES='''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/docProps/custom.xml" ContentType="application/vnd.openxmlformats-officedocument.custom-properties+xml"/></Types>'''
RELS='''<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>'''

def _p(text,style=None):
    prop=f'<w:pPr><w:pStyle w:val="{style}"/></w:pPr>' if style else ""
    return f'<w:p>{prop}<w:r><w:t xml:space="preserve">{escape(text)}</w:t></w:r></w:p>'
def render_docx(model:DocumentModel,output,template=None,style_config=None):
    output=Path(output); output.parent.mkdir(parents=True,exist_ok=True); cfg={**DEFAULT_STYLE,**load_config(style_config)}
    if template:
        template=Path(template)
        if not template.exists(): raise FileNotFoundError(f"DOCX template not found: {template}")
        shutil.copyfile(template,output)
    body=[_p(model.metadata.solution_name or model.metadata.project_id,"Title")]
    def emit(sec:Section,level=1):
        body.append(_p(sec.title,f"Heading{min(level,2)}"))
        for i in sec.items:
            style="Code" if i.content.strip().startswith("```") else None
            body.append(_p(i.content,style))
        for child in sec.children: emit(child,level+1)
    for sec in model.sections: emit(sec)
    m=cfg["page"]["margin_twips"] if isinstance(cfg.get("page"),dict) else 1440
    document=f'''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>{''.join(body)}<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="{m}" w:right="{m}" w:bottom="{m}" w:left="{m}"/></w:sectPr></w:body></w:document>'''
    font=cfg.get("fonts",{}).get(model.metadata.locale,"Arial") if isinstance(cfg.get("fonts"),dict) else "Arial"
    styles=f'''<?xml version="1.0" encoding="UTF-8"?><w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:rPr><w:rFonts w:ascii="{escape(font)}" w:eastAsia="{escape(font)}"/><w:sz w:val="22"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:rPr><w:b/><w:sz w:val="40"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:rPr><w:b/><w:sz w:val="32"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:rPr><w:b/><w:sz w:val="28"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Code"><w:name w:val="Code"/><w:rPr><w:rFonts w:ascii="Consolas"/><w:sz w:val="18"/></w:rPr></w:style></w:styles>'''
    custom=f'''<?xml version="1.0"?><Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/custom-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"><property fmtid="{{D5CDD505-2E9C-101B-9397-08002B2CF9AE}}" pid="2" name="TemplateVersion"><vt:lpwstr>{escape(model.metadata.template_version)}</vt:lpwstr></property></Properties>'''
    mode="a" if template else "w"
    with ZipFile(output,mode,ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml",CONTENT_TYPES); z.writestr("_rels/.rels",RELS); z.writestr("word/document.xml",document); z.writestr("word/styles.xml",styles); z.writestr("docProps/custom.xml",custom)
    return output
