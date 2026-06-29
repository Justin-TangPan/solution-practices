"""
Terraform 语法与安全检查
=======================
- 文件完整性（versions.tf, providers.tf, variables.tf, main.tf, outputs.tf）
- 安全组过宽检测（SSH:RDP 对 0.0.0.0/0）
- 硬编码 AK/SK 检测
- 变量 description 覆盖率
- 敏感变量标记检查
- BOM 头检测
- EIP 带宽预警
"""

import re
from pathlib import Path
from ..runner import CheckResult


def run(practice_path: Path, entry: dict) -> list:
    results = []
    tf_path = practice_path / "terraform"

    if not tf_path.exists():
        results.append(CheckResult("tf_syntax", False, "ERROR",
                                    "terraform/ 目录不存在"))
        return results

    # ── 1. 必需文件检查 ──
    required = ["versions.tf", "providers.tf", "variables.tf", "main.tf"]
    optional = ["outputs.tf"]
    found_any = False

    for fname in required:
        fpath = tf_path / fname
        if fpath.exists():
            found_any = True
            results.append(CheckResult("tf_syntax", True, "INFO",
                                        f"terraform/{fname} 存在"))
        else:
            results.append(CheckResult("tf_syntax", False, "ERROR",
                                        f"缺少必需文件 terraform/{fname}"))

    for fname in optional:
        fpath = tf_path / fname
        if fpath.exists():
            results.append(CheckResult("tf_syntax", True, "INFO",
                                        f"terraform/{fname} 存在（可选）"))

    if not found_any:
        return results

    # ── 2. 内容扫描 ──
    for fname in ["main.tf", "variables.tf", "providers.tf"]:
        fpath = tf_path / fname
        if not fpath.exists():
            continue
        content = fpath.read_text(encoding="utf-8-sig", errors="replace")

        # 硬编码 AK/SK
        if re.search(r'access_key\s*=\s*["\'][^"\']+["\'](?!.*var\.)', content):
            results.append(CheckResult("tf_syntax", False, "ERROR",
                                        f"terraform/{fname} 可能包含硬编码 access_key",
                                        file=str(fpath)))
        if re.search(r'secret_key\s*=\s*["\'][^"\']+["\'](?!.*var\.)', content):
            results.append(CheckResult("tf_syntax", False, "ERROR",
                                        f"terraform/{fname} 可能包含硬编码 secret_key",
                                        file=str(fpath)))

    # ── 3. variables.tf 规范 ──
    vf = tf_path / "variables.tf"
    if vf.exists():
        content = vf.read_text(encoding="utf-8-sig", errors="replace")
        var_pattern = re.compile(r'variable\s+"(\w+)"')
        desc_pattern = re.compile(r'description\s*=')

        for match in var_pattern.finditer(content):
            var_name = match.group(1)
            block = content[match.end():]
            depth = 1
            end = 0
            for i, c in enumerate(block):
                if c == '{': depth += 1
                elif c == '}':
                    depth -= 1
                    if depth == 0: end = i; break
            var_block = block[:end]

            if not desc_pattern.search(var_block):
                results.append(CheckResult("tf_syntax", True, "WARN",
                                            f"variable '{var_name}' 缺少 description",
                                            file=str(vf)))

            if any(kw in var_name.lower() for kw in ["password", "secret", "token", "key", "ak", "sk"]):
                if 'sensitive' not in var_block:
                    results.append(CheckResult("tf_syntax", True, "WARN",
                                                f"variable '{var_name}' 建议设置 sensitive = true",
                                                file=str(vf)))

    # ── 4. 安全组过宽检测 + EIP 带宽 ──
    mf = tf_path / "main.tf"
    if mf.exists():
        content = mf.read_text(encoding="utf-8-sig", errors="replace")

        sg_blocks = re.findall(
            r'resource\s+"huaweicloud_networking_secgroup_rule"[^}]+}',
            content, re.DOTALL)

        for block in sg_blocks:
            cidr = re.search(r'cidr\s*=\s*"([^"]+)"', block)
            port = re.search(r'port\s*=\s*(\d+)', block)
            if cidr and cidr.group(1) == "0.0.0.0/0" and port and port.group(1) in ["22", "3389"]:
                results.append(CheckResult("tf_syntax", False, "ERROR",
                                            f"安全组端口 {port.group(1)} 对 0.0.0.0/0 开放 (高危)",
                                            file=str(mf)))

        # EIP 带宽预警
        for block in re.findall(r'resource\s+"huaweicloud_vpc_eip"[^}]+}', content, re.DOTALL):
            bw = re.search(r'bandwidth\s*=\s*(\d+)', block)
            if bw and int(bw.group(1)) > 100:
                results.append(CheckResult("tf_syntax", True, "WARN",
                                            f"EIP 带宽 {bw.group(1)}Mbps 较大，请确认成本合理",
                                            file=str(mf)))

        # resource 数量合理性
        resources = re.findall(r'resource\s+"(\w+)', content)
        if len(resources) < 2:
            results.append(CheckResult("tf_syntax", True, "WARN",
                                        f"main.tf 仅有 {len(resources)} 个 resource"))

    # ── 5. BOM 头检测 ──
    for f in tf_path.glob("*.tf"):
        raw = f.read_bytes()
        if raw[:3] == b'\xef\xbb\xbf':
            results.append(CheckResult("tf_syntax", False, "ERROR",
                                        f"{f.name} 包含 BOM 头（不允许）",
                                        file=str(f)))

    if not any(r.severity in ("ERROR", "WARN") for r in results):
        results.append(CheckResult("tf_syntax", True, "INFO", "Terraform 检查全部通过"))

    return results
