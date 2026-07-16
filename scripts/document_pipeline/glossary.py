from pathlib import Path
import csv,json
from .config import load_config

class Glossary:
    def __init__(self,layers=()):
        self.terms={}
        for layer in layers: self.terms.update(self._read(layer))
    def _read(self,path):
        p=Path(path)
        if p.suffix.lower()==".csv":
            with p.open(encoding="utf-8",newline="") as f: return {r[0]:r[1] for r in csv.reader(f) if len(r)>=2 and r[0]}
        data=load_config(p)
        return data.get("terms",data) if isinstance(data,dict) else {}
    def apply(self,text):
        for source,target in sorted(self.terms.items(),key=lambda x:len(x[0]),reverse=True): text=text.replace(source,target)
        return text
