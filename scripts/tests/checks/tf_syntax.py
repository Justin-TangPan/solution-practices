"""
Terraform 语法与安全检查
=======================
接受单文件（deploying-xxx.tf）或 4 文件拆分两种模式。
检查内容：
- 安全组过宽检测（SSH/3389 对 0.0.0.0/0）→ ERROR
- 硬编码 AK/SK 检测 → ERROR
- 敏感变量 missing sensitive=true → WARN
- 变量 description 覆盖率 → WARN
- BOM 头检测 → ERROR
- EIP 带宽成本预警 → WARN
"""

import re
from pathlib import Path
from ..runner import CheckResult


def run(practice_path: Path, entry: dict) -> list:
    results = []
    tf_path = practice_path / "terraform"

    if not tf_path.exists():
        results.append(CheckResult("tf_syntax", False, "ERROR", "terraform/ 目录不存在"))
        return results

    tf_files = list(tf_path.glob("*.tf"))
    if not tf_files:
        results.append(CheckResult("tf_syntax", False, "ERROR", "terraform/ 中没有 .tf 文件"))
        return results

    # 检测模式：单文件 vs 拆分
    is_single_file = len(tf_files) <= 2 and any("deploying-" in f.name for f in tf_files)
    if is_single_file:
        results.append(CheckResult("tf_syntax", True, "INFO", f"单文件模式 ({len(tf_files)} 个 .tf)"))
    else:
        results.append(CheckResult("tf_syntax", True, "INFO", f"拆分模式 ({len(tf_files)} 个 .tf)"))

    # ── 扫描所有 .tf 文件内容 ──
    for f in tf_files:
        content = f.read_text(encoding="utf-8-sig", errors="replace")

        # 硬编码 AK/SK
        if re.search(r'access_key\s*=\s*["\'][^"\']+["\'](?!.*var\.)', content):
            results.append(CheckResult("tf_syntax", False, "ERROR", f"{f.name}: 可能包含硬编码 access_key"))
        if re.search(r'secret_key\s*=\s*["\'][^"\']+["\'](?!.*var\.)', content):
            results.append(CheckResult("tf_syntax", False, "ERROR", f"{f.name}: 可能包含硬编码 secret_key"))

        # 安全组过宽检测 (SSH/3389 对 0.0.0.0/0)
        for block in re.findall(r'resource\s+"huaweicloud_networking_secgroup_rule"[^}]+}', content, re.DOTALL):
            cidr = re.search(r'(?:remote_ip_prefix|cidr)\s*=\s*"([^"]+)"', block)
            port = re.search(r'ports?\s*=\s*(\d+)', block)
            if cidr and cidr.group(1) == "0.0.0.0/0" and port and port.group(1) in ["22", "3389"]:
                results.append(CheckResult("tf_syntax", False, "ERROR",
                    f"{f.name}: 端口 {port.group(1)} 对 0.0.0.0/0 开放 (高危)"))

        # EIP 带宽预警
        for block in re.findall(r'resource\s+"huaweicloud_vpc_eip".*?\n}', content, re.DOTALL):
            bw = re.search(r'bandwidth\s*\{.*?size\s*=\s*(\d+)', block, re.DOTALL)
            if bw and int(bw.group(1)) > 100:
                results.append(CheckResult("tf_syntax", True, "WARN",
                    f"{f.name}: EIP 带宽 {bw.group(1)}Mbps 较大，请确认成本"))

        # 变量描述 + sensitive 标记
        var_pattern = re.compile(r'variable\s+"(\w+)"')
        desc_pattern = re.compile(r'description\s*=')
        for match in var_pattern.finditer(content):
            var_name = match.group(1)
            block = content[match.end():]
            depth, end = 1, 0
            for i, c in enumerate(block):
                if c == '{': depth += 1
                elif c == '}':
                    depth -= 1
                    if depth == 0: end = i; break
            var_block = block[:end]
            if not desc_pattern.search(var_block):
                results.append(CheckResult("tf_syntax", True, "WARN",
                    f"variable '{var_name}' 缺少 description"))
            if any(kw in var_name.lower() for kw in ["password", "secret", "token", "key", "ak", "sk"]):
                if 'sensitive' not in var_block:
                    results.append(CheckResult("tf_syntax", True, "WARN",
                        f"variable '{var_name}' 建议设置 sensitive=true"))

    # BOM 头检测
    for f in tf_files:
        raw = f.read_bytes()
        if raw[:3] == b'\xef\xbb\xbf':
            results.append(CheckResult("tf_syntax", False, "ERROR", f"{f.name}: 包含 BOM 头（RFS 不允许）"))

    if not any(r.severity in ("ERROR", "WARN") for r in results):
        results.append(CheckResult("tf_syntax", True, "INFO", "Terraform 检查全部通过"))

    return results
