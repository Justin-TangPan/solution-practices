"""Small release-blocking security checks for Terraform-backed practices."""

import fnmatch
import re
from pathlib import Path

from ..runner import CheckResult, load_project_config


PUBLIC_RULE = re.compile(
    r'resource\s+"huaweicloud_networking_secgroup_rule"[^}]+?ports?\s*=\s*"?(\d+)[^}]+?'
    r'remote_ip_prefix\s*=\s*"0\.0\.0\.0/0"|'
    r'resource\s+"huaweicloud_networking_secgroup_rule"[^}]+?remote_ip_prefix\s*=\s*"0\.0\.0\.0/0"'
    r'[^}]+?ports?\s*=\s*"?(\d+)',
    re.DOTALL,
)
MUTABLE_IMAGE = re.compile(r'(?im)^\s*(?:image:\s*|docker\s+pull\s+)[^\s"\']+:(latest|main|main-stable)\b')
SENSITIVE_CONTROL = re.compile(r'master_key|basic-auth|basic_auth|dashboard|service_role_key', re.I)
HARDCODED_CREDENTIAL = re.compile(
    r'(?im)\b(?:access_key|secret_key|api_?key|apikey|master_?key|token)\s*[:=]\s*["\']?'
    r'(?!\$\{|\$|var\.|os\.environ(?:\[|/))([A-Za-z0-9_./+-]{12,})'
)


def _public_ports(text: str) -> set[int]:
    return {int(port) for match in PUBLIC_RULE.finditer(text) for port in match.groups() if port}


def run(practice_path: Path, entry: dict) -> list[CheckResult]:
    results: list[CheckResult] = []
    instance = "/".join(filter(None, (
        entry.get("name"), entry.get("site"), entry.get("region"), entry.get("deploy_type")
    )))
    exceptions = load_project_config().get("quality_gate", {}).get("architecture_exceptions", {})
    exception = next((value for pattern, value in exceptions.items()
                      if fnmatch.fnmatch(instance, pattern)), {})
    accepted_risks = set(exception.get("accepted_risks", []))
    for path in sorted((practice_path / "terraform").glob("*.tf")):
        text = path.read_text(encoding="utf-8-sig", errors="replace")
        lower = text.lower()
        ports = _public_ports(text)

        if HARDCODED_CREDENTIAL.search(text) or "-----BEGIN PRIVATE KEY-----" in text:
            results.append(CheckResult("security", False, "ERROR",
                                       f"{path.name}: 疑似硬编码凭证或私钥", file=str(path)))
        dangerous = ports & {22, 3306, 5432, 6379, 27017}
        if dangerous:
            results.append(CheckResult("security", False, "ERROR",
                                       f"{path.name}: 高危端口对 0.0.0.0/0 开放: {sorted(dangerous)}", file=str(path)))

        if ports & {4000, 8000} and "http://" in lower and SENSITIVE_CONTROL.search(text):
            accepted = "public_http_control_plane" in accepted_risks
            results.append(CheckResult(
                "security", accepted, "WARN" if accepted else "ERROR",
                f"{path.name}: 公网 HTTP 暴露敏感 API/管理面（端口 {sorted(ports & {4000, 8000})}）"
                + ("；已确认架构例外" if accepted else ""),
                file=str(path),
            ))
        if 9090 in ports:
            results.append(CheckResult("security", True, "WARN", f"{path.name}: Prometheus 9090 对公网开放", file=str(path)))
        if MUTABLE_IMAGE.search(text):
            results.append(CheckResult("security", True, "WARN", f"{path.name}: 使用可变容器镜像 tag", file=str(path)))
        if "privileged: true" in lower or "/var/run/docker.sock" in lower:
            results.append(CheckResult("security", False, "ERROR", f"{path.name}: 容器使用 privileged 或 Docker socket", file=str(path)))
        if "docker login" in lower:
            results.append(CheckResult("security", False, "ERROR", f"{path.name}: 部署逻辑中包含 docker login", file=str(path)))
        writes_env = re.search(r'(?:cat|install|touch|chmod)\b[^\n]*\.env\b|>\s*\S*\.env\b', text)
        if writes_env and re.search(r'password|master_key|service_role_key', text, re.I):
            if "umask 077" not in text and not re.search(r'chmod\s+0?600\s+\S*\.env', text):
                results.append(CheckResult("security", True, "WARN", f"{path.name}: 敏感 .env 未显式设置 0600", file=str(path)))

    if not results:
        results.append(CheckResult("security", True, "INFO", "安全静态门禁通过"))
    return results
