import json,tempfile,unittest
from collections import Counter
from pathlib import Path
from types import SimpleNamespace
from zipfile import ZipFile
from scripts.document_pipeline.adapters import load_input
from scripts.document_pipeline.bilingual_checker import check_bilingual
from scripts.document_pipeline.docx_renderer import render_docx
from scripts.document_pipeline.docxtpl_renderer import build_company_template,render_markdown_docxtpl
from scripts.document_pipeline.glossary import Glossary
from scripts.document_pipeline.markdown_parser import parse_markdown
from scripts.document_pipeline.markdown_renderer import render_markdown
from scripts.document_pipeline.models import DocumentModel
from scripts.document_pipeline.placeholder_protector import PlaceholderProtector
from scripts.document_pipeline.project_analyzer import analyze_project
from scripts.document_pipeline.quality_checker import check_model
from scripts.document_pipeline.security import scan_sensitive
from scripts.document_pipeline.translator import translate_model
from scripts.document_pipeline.paths import document_filename
from scripts.document_pipeline.cli import _generate_full_set

class PipelineTest(unittest.TestCase):
 def setUp(self): self.t=tempfile.TemporaryDirectory();self.root=Path(self.t.name)
 def tearDown(self): self.t.cleanup()
 def test_markdown_schema_and_render(self):
  p=self.root/"a.md";p.write_text("# 部署指南\n\n## 部署步骤\n\n运行 `docker run -p 8080:80 x/y:1`。\n",encoding="utf-8")
  m=parse_markdown(p);q=self.root/"model.json";m.save(q);self.assertEqual(DocumentModel.load(q).sections[0].title,"部署指南");self.assertIn("docker run",render_markdown(m))
 def test_analyzer_skips_env(self):
  (self.root/"main.tf").write_text('variable "region" {}\n# port = 8080\n',encoding="utf-8");(self.root/".env").write_text("PASSWORD=do-not-read",encoding="utf-8")
  m=analyze_project(self.root);self.assertIn("region",str(m.to_dict()));self.assertNotIn("PASSWORD",str(m.to_dict()))
 def test_docx_valid_and_parseable(self):
  p=self.root/"a.md";p.write_text("# Title\nBody",encoding="utf-8");m=parse_markdown(p);o=render_docx(m,self.root/"a.docx")
  with ZipFile(o) as z:self.assertIn(b"Title",z.read("word/document.xml"))
  self.assertTrue(load_input(o).sections)
 def test_protection_translation_consistency(self):
  text="部署指南 `curl https://example.com/a` /etc/app.yaml APP_TOKEN"
  safe,v=PlaceholderProtector().protect(text);self.assertEqual(PlaceholderProtector().restore(safe,v),text)
  p=self.root/"a.md";p.write_text("# 部署指南\n"+text,encoding="utf-8");src=parse_markdown(p);dst=translate_model(src);self.assertFalse([x for x in check_bilingual(src,dst) if x["severity"]=="error"])
  safe,values=PlaceholderProtector().protect("run `echo ok`");self.assertRaises(ValueError,PlaceholderProtector().restore,safe.replace("⟦SAC_0000⟧",""),values)
 def test_quality_and_sensitive(self):
  p=self.root/"a.md";p.write_text("# Empty\n",encoding="utf-8");m=parse_markdown(p);self.assertIn(check_model(m).status,{"warning","fail"});self.assertTrue(scan_sensitive("token=123456789abcdef"))
 def test_glossary_csv_and_errors(self):
  p=self.root/"g.csv";p.write_text("云,cloud\n",encoding="utf-8");self.assertEqual(Glossary([p]).apply("云"),"cloud")
  bad=self.root/"a.exe";bad.write_bytes(b"x");self.assertRaises(ValueError,load_input,bad)
 def test_contract_filenames(self):
  self.assertEqual(document_filename("Demo","deployment-guide","zh-cn"),"Demo-部署指南_zh.md")
  self.assertEqual(document_filename("Demo","solution-details","en-us","docx"),"Demo-Solution-Details_en.docx")
 def test_generate_respects_site_and_optional_docx(self):
  model=DocumentModel();model.metadata.solution_name="Demo";model.metadata.project_id="demo"
  args=SimpleNamespace(site="intl",docx=False,glossary=[],template=None,style_config=None)
  markdown,docx,_=_generate_full_set(model,self.root,args)
  self.assertEqual(len(markdown),4);self.assertEqual(docx,[])
  self.assertTrue(all("/intl/docs/" in path for path in markdown))
 def test_missing_template_and_pdf_failure_are_explicit(self):
  p=self.root/"a.md";p.write_text("# Title\nBody",encoding="utf-8");model=parse_markdown(p)
  self.assertRaises(FileNotFoundError,render_docx,model,self.root/"a.docx",self.root/"missing.docx")
  bad_pdf=self.root/"bad.pdf";bad_pdf.write_bytes(b"not a pdf")
  with self.assertRaises((RuntimeError,ValueError)): load_input(bad_pdf)
 def test_template_render_replaces_package_members(self):
  p=self.root/"a.md";p.write_text("# Demo 部署指南\n\n## 方案概述\n\n新正文",encoding="utf-8");model=parse_markdown(p)
  template=render_docx(model,self.root/"template.docx")
  output=render_docx(model,self.root/"output.docx",template)
  with ZipFile(output) as z:
   self.assertFalse([name for name,count in Counter(z.namelist()).items() if count>1])
   self.assertIn("新正文",z.read("word/document.xml").decode())
 def test_docxtpl_company_template(self):
  source=Path("assets/doc-templates/LiteLLM，统一的AI管理网关-pdf.docx")
  if not source.exists(): self.skipTest("company template not packaged")
  markdown=self.root/"demo.md";markdown.write_text("# 部署 Demo — 演示 部署指南\n\n> **文档版本：** 01\n> **发布日期：** 2026-07-21\n\n## 1. 方案概述\n\n- 列表项\n\n| A | B |\n|---|---|\n| 1 | 2 |\n",encoding="utf-8")
  template=build_company_template(source,self.root/"template.docx")
  output=render_markdown_docxtpl(markdown,template,source,self.root/"output.docx")
  with ZipFile(output) as z:
   xml=b"\n".join(z.read(name) for name in z.namelist() if name.endswith((".xml",".rels")))
   self.assertNotIn(b"LiteLLM",xml);self.assertNotIn(b"{{",xml)
  rendered=load_input(output);self.assertTrue(rendered.sections)

if __name__=="__main__":unittest.main()
