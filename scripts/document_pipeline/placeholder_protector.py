import re

PATTERNS=[r"```[\s\S]*?```",r"`[^`\n]+`",r"https?://[^\s)]+",r"(?:[A-Za-z]:\\|/)[\w./\\-]+",r"\b[A-Z][A-Z0-9_]{2,}\b",r"\b(?:\d{1,3}\.){3}\d{1,3}(?::\d+)?\b",r"\b[0-9a-f]{8}-[0-9a-f-]{27,}\b"]
class PlaceholderProtector:
    def protect(self,text):
        values=[]
        def repl(m): values.append(m.group(0)); return f"⟦SAC_{len(values)-1:04d}⟧"
        # One pass prevents later patterns from matching placeholders introduced
        # by earlier patterns (for example SAC_0001 as an environment variable).
        return re.sub("(?:"+"|".join(PATTERNS)+")",repl,text,flags=re.I),values
    def restore(self,text,values):
        for i,value in enumerate(values):
            token=f"⟦SAC_{i:04d}⟧"
            if text.count(token)!=1:
                raise ValueError(f"Translation placeholder integrity failure: {token}")
            text=text.replace(token,value)
        if "⟦SAC_" in text: raise ValueError("Unrestored translation placeholder")
        return text
