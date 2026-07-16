import re
from .models import DocumentModel

TOKEN_PATTERNS={"url":r"https?://[^\s)]+","number":r"(?<!\w)\d+(?:\.\d+)?(?:\s?(?:GB|GiB|MB|Mbit/s|vCPU))?","path":r"(?:[A-Za-z]:\\|/)[\w./\\-]+","code":r"```[\s\S]*?```"}
def check_bilingual(source:DocumentModel,target:DocumentModel):
    issues=[]
    def flatten(m):
        out=[]
        def walk(s): out.append((s.title,"\n".join(i.content for i in s.items))); [walk(c) for c in s.children]
        [walk(s) for s in m.sections]; return out
    a,b=flatten(source),flatten(target)
    if len(a)!=len(b): issues.append({"severity":"error","message":"Section count mismatch","blocking":True})
    at="\n".join(x[1] for x in a); bt="\n".join(x[1] for x in b)
    for name,pattern in TOKEN_PATTERNS.items():
        av=re.findall(pattern,at,re.I); bv=re.findall(pattern,bt,re.I)
        if av!=bv: issues.append({"severity":"error","message":f"Protected {name} values differ","source":av,"target":bv,"blocking":True})
    if target.metadata.locale.startswith("en") and re.search(r"[\u4e00-\u9fff]",bt): issues.append({"severity":"warning","message":"Target contains untranslated Chinese","blocking":False})
    return issues
