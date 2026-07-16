import re

RULES={"private_key":r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----","cloud_access_key":r"\b(?:AKIA|ASIA)[A-Z0-9]{16}\b","credential_assignment":r"(?i)\b(?:password|passwd|secret|token|access[_-]?key)\s*[:=]\s*['\"]?(?!\$\{|<|\*{3}|example|changeme)([^\s'\"]{8,})"}
def scan_sensitive(text):
    return [{"severity":"error","kind":name,"message":f"Potential sensitive value detected: {name}","blocking":True} for name,pattern in RULES.items() if re.search(pattern,text)]
