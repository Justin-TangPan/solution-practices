from __future__ import annotations
import argparse,json,sys
from pathlib import Path
from .adapters import load_input
from .bilingual_checker import check_bilingual
from .docx_renderer import render_docx
from .docxtpl_renderer import render_markdown_docxtpl
from .glossary import Glossary
from .markdown_renderer import render_markdown
from .models import DocumentModel
from .paths import docs_dir,document_filename
from .quality_checker import QualityReport,check_model
from .translator import translate_model

def _out(args,name):
    p=Path(args.output or f"output/document-pipeline/{name}");p.mkdir(parents=True,exist_ok=True);return p
def _load(args):
    value=args.input or args.project
    if not args.input and args.project and not Path(value).exists():
        candidate=Path(__file__).resolve().parents[2]/"practices"/args.project
        if candidate.is_dir(): value=candidate
    return load_input(value)
def _copy_model(model): return DocumentModel.from_dict(model.to_dict())

def _generate_full_set(model,out,args):
    """Render the requested contract documents without publishing into practices/."""
    name=model.metadata.solution_name or model.metadata.project_id or "Solution"
    generated_md=[]; generated_docx=[]; reports=[]; locale_models={"zh-cn":model}
    locale_models["en-us"]=translate_model(model,"en-us",glossary=Glossary(args.glossary))
    targets=[]
    if args.site in {"all","cn"}: targets.append(("cn","zh-cn",out/"cn"/"docs"))
    if args.site in {"all","intl"}: targets.extend((("intl","zh-cn",out/"intl"/"docs"/"zh-cn"),("intl","en-us",out/"intl"/"docs"/"en-us")))
    for site,locale,directory in targets:
        directory.mkdir(parents=True,exist_ok=True)
        for document_type in ("deployment-guide","solution-details"):
            current=_copy_model(locale_models[locale]);current.metadata.site=site;current.metadata.locale=locale;current.metadata.document_type=document_type
            md=directory/document_filename(name,document_type,locale,"md")
            render_markdown(current,md);generated_md.append(str(md));checked=[md]
            if args.docx:
                docx=directory/document_filename(name,document_type,locale,"docx")
                render_docx(current,docx,args.template,args.style_config);generated_docx.append(str(docx));checked.append(docx)
            reports.append(check_model(current,checked))
    aggregate=QualityReport(
        errors=[item for report in reports for item in report.errors],
        warnings=[item for report in reports for item in report.warnings],
        info=[item for report in reports for item in report.info],
        manual_review_items=list(dict.fromkeys(item for report in reports for item in report.manual_review_items)),
        generated_files=generated_md+generated_docx,
        checked_sources=list(dict.fromkeys(item for report in reports for item in report.checked_sources)),
    ).finish()
    return generated_md,generated_docx,aggregate
def build_parser():
    p=argparse.ArgumentParser(prog="python -m scripts.document_pipeline",description="Offline-first SAC document pipeline")
    sub=p.add_subparsers(dest="command",required=True)
    for name in ("analyze","generate","translate","render-word","validate","convert"):
        s=sub.add_parser(name);s.add_argument("--project");s.add_argument("--input");s.add_argument("--output");s.add_argument("--locale",default="zh-cn");s.add_argument("--site",default="all",choices=["all","cn","intl"]);s.add_argument("--docx",action="store_true");s.add_argument("--document-type",default="deployment-guide",choices=["deployment-guide","solution-details"]);s.add_argument("--template");s.add_argument("--style-config");s.add_argument("--glossary",action="append",default=[]);s.add_argument("--source")
    return p
def main(argv=None):
    args=build_parser().parse_args(argv)
    if not args.project and not args.input: raise SystemExit("--project or --input is required")
    try:
        model=_load(args);model.metadata.document_type=args.document_type
        out=_out(args,model.metadata.project_id or "document")
        if args.command=="analyze": print(model.save(out/"standard-document.json"));return 0
        if args.command=="translate":
            translated=translate_model(model,args.locale,glossary=Glossary(args.glossary)); translated.save(out/f"standard-document-{args.locale}.json"); print(render_markdown(translated,out/f"document-{args.locale}.md"),end=""); return 0
        if args.command=="render-word":
            if args.template and args.source and args.input and Path(args.input).suffix.lower()==".md":
                print(render_markdown_docxtpl(args.input,args.template,args.source,out/"document.docx",out/"docxtpl-context.json"));return 0
            print(render_docx(model,out/"document.docx",args.template,args.style_config));return 0
        if args.command=="validate":
            report=check_model(model,[args.input] if args.input and Path(args.input).suffix in {".md",".docx"} else []); print(json.dumps(report.__dict__,ensure_ascii=False,indent=2));return 1 if report.status=="fail" else 0
        if args.command=="convert":
            model.save(out/"standard-document.json");render_markdown(model,out/"document.md");render_docx(model,out/"document.docx",args.template,args.style_config);print(out);return 0
        # generate: deterministic requested site/locale set. Offline English is always review-marked.
        standard=model.save(out/"standard-document.json");markdown_files,docx_files,report=_generate_full_set(model,out,args);rp=report.save(out/"quality-report.json");manual=out/"manual-review.json";manual.write_text(json.dumps({"status":"pending","items":report.manual_review_items,"approved":False},ensure_ascii=False,indent=2),encoding="utf-8");print(json.dumps({"standard_document":str(standard),"markdown_files":markdown_files,"docx_files":docx_files,"languages":["zh-cn","en-us"],"quality_report":str(rp),"manual_review":str(manual),"quality_status":report.status,"errors":report.errors,"warnings":report.warnings,"manual_review_items":report.manual_review_items,"ready_for_listing":False},ensure_ascii=False,indent=2));return 1 if report.status=="fail" else 0
    except (OSError,ValueError,RuntimeError) as e:
        print(json.dumps({"status":"fail","errors":[{"message":str(e),"blocking":True}]},ensure_ascii=False),file=sys.stderr);return 2
