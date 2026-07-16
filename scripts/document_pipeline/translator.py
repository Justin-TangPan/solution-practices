from __future__ import annotations
from typing import Protocol
from .glossary import Glossary
from .models import ContentItem, DocumentModel, Metadata, Review, Section
from .placeholder_protector import PlaceholderProtector

class TranslationProvider(Protocol):
    name: str
    def translate(self,text:str,source_locale:str,target_locale:str)->str: ...
class OfflineRuleProvider:
    name="offline-rules-v1"
    BASIC={"部署指南":"Deployment Guide","解决方案概述":"Solution Overview","架构":"Architecture","前提条件":"Prerequisites","部署步骤":"Deployment Steps","验证步骤":"Verification Steps","卸载步骤":"Uninstall Steps","限制":"Limitations","故障排除":"Troubleshooting"}
    def translate(self,text,source_locale,target_locale):
        for a,b in sorted(self.BASIC.items(),key=lambda x:len(x[0]),reverse=True): text=text.replace(a,b)
        return text
def translate_model(model:DocumentModel,target_locale="en-us",provider=None,glossary=None):
    provider=provider or OfflineRuleProvider(); glossary=glossary or Glossary(); protector=PlaceholderProtector()
    def trans(text):
        safe,values=protector.protect(glossary.apply(text)); return protector.restore(provider.translate(safe,model.metadata.locale,target_locale),values)
    def section(s): return Section(s.key,trans(s.title),[ContentItem(trans(i.content),i.sources,i.inferred,i.manual_confirmation,target_locale,i.confidence,i.quality_status) for i in s.items],[section(c) for c in s.children])
    md=Metadata(**model.metadata.__dict__); md.locale=target_locale; md.site="intl"; md.model_version=provider.name
    result=DocumentModel(md,[section(s) for s in model.sections],model.assets.copy(),Review(**model.review.__dict__))
    if isinstance(provider,OfflineRuleProvider): result.review.manual_confirmation_items.append("Offline rules do not provide full natural-language translation; review remaining source-language text")
    return result
