from pathlib import Path
import json

DEFAULT_STYLE={"template_version":"idp-neutral-v1","page":{"width_twips":11906,"height_twips":16838,"margin_twips":1440},"fonts":{"zh-cn":"Microsoft YaHei","en-us":"Arial","code":"Consolas"},"sizes":{"normal":22,"title":40,"heading1":32,"heading2":28}}
def load_config(path=None, default=None):
    if not path: return dict(default or {})
    p=Path(path); text=p.read_text(encoding="utf-8")
    if p.suffix.lower()==".json": return json.loads(text)
    # Safe flat YAML subset for offline configs; JSON is recommended for nested values.
    out={}
    for raw in text.splitlines():
        line=raw.split("#",1)[0].strip()
        if not line or ":" not in line: continue
        k,v=line.split(":",1); v=v.strip().strip("'\"")
        out[k.strip()]=v
    return out
