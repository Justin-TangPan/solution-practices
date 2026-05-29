#!/usr/bin/env python3
"""
RFS 模板结构验证器
验证解决方案模板目录的文件完整性、结构正确性

用法:
    python validate_template.py <solution_dir>
"""

import os
import sys
import json
import re


def check_file_exists(dir_path, filename, required=True):
    """检查文件是否存在"""
    path = os.path.join(dir_path, filename)
    exists = os.path.exists(path)
    if required and not exists:
        return False, f"[缺少] 必需文件 {filename} 不存在"
    if not required and not exists:
        return True, f"[可选] 文件 {filename} 不存在（跳过）"
    return True, f"[通过] {filename}"


def check_variables_tf(dir_path):
    """检查 variables.tf 内容"""
    path = os.path.join(dir_path, "variables.tf")
    if not os.path.exists(path):
        return True, []

    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    issues = []

    # 检查每个 variable 是否有 description
    var_pattern = re.compile(r'variable\s+"(\w+)"\s*{')
    desc_pattern = re.compile(r'description\s*=\s*"')
    sensitive_pattern = re.compile(r'sensitive\s*=\s*true')

    for match in var_pattern.finditer(content):
        var_name = match.group(1)
        start = match.end()
        block = content[start:]

        # 找到块结束
        depth = 1
        end = 0
        for i, c in enumerate(block):
            if c == '{':
                depth += 1
            elif c == '}':
                depth -= 1
                if depth == 0:
                    end = i
                    break

        var_block = block[:end]

        if not desc_pattern.search(var_block):
            issues.append(f"[警告] variable '{var_name}' 缺少 description")

        # 检查密码类变量是否标记 sensitive
        if any(kw in var_name.lower() for kw in ["password", "secret", "token", "key"]):
            if not sensitive_pattern.search(var_block):
                issues.append(f"[安全] variable '{var_name}' 可能是敏感信息，建议设置 sensitive = true")

    return True, issues


def check_providers_tf(dir_path):
    """检查 providers.tf 是否有硬编码 AK/SK"""
    path = os.path.join(dir_path, "providers.tf")
    if not os.path.exists(path):
        return True, []

    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    issues = []
    if re.search(r'access_key\s*=\s*["\'](?!\s*var\.)', content):
        issues.append("[安全] providers.tf 中检测到硬编码的 access_key")

    if re.search(r'secret_key\s*=\s*["\'](?!\s*var\.)', content):
        issues.append("[安全] providers.tf 中检测到硬编码的 secret_key")

    return True, issues


def check_utf8_bom(dir_path):
    """检查 .tf.json 文件是否有 BOM 头"""
    issues = []
    for root, _, files in os.walk(dir_path):
        for f in files:
            if f.endswith(".tf.json"):
                path = os.path.join(root, f)
                with open(path, "rb") as fh:
                    first_bytes = fh.read(3)
                    if first_bytes == b'\xef\xbb\xbf':
                        issues.append(f"[错误] {os.path.relpath(path, dir_path)} 包含 BOM 头（不允许）")
    return True, issues


def check_tfvars(dir_path):
    """检查包内是否有 .tfvars 文件"""
    issues = []
    for root, _, files in os.walk(dir_path):
        for f in files:
            if f.endswith(".tfvars"):
                rel = os.path.relpath(os.path.join(root, f), dir_path)
                issues.append(f"[错误] 包内禁止包含 .tfvars 文件: {rel}")
    return True, issues


def check_extension(dir_path):
    """验证 .extension 文件格式"""
    path = os.path.join(dir_path, ".extension")
    if not os.path.exists(path):
        return True, ["[信息] 无 .extension 文件（可选）"]

    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)

        issues = []

        if "variables" not in data:
            issues.append("[警告] .extension 缺少 'variables' 字段")

        if "grouping" in data.get("variables", {}):
            for key, val in data["variables"]["grouping"].items():
                if "label" not in val:
                    issues.append(f"[警告] grouping '{key}' 缺少 label")

        return True, issues
    except json.JSONDecodeError as e:
        return False, [f"[错误] .extension JSON 解析失败: {e}"]


def check_main_tf(dir_path):
    """检查 main.tf 基本结构"""
    path = os.path.join(dir_path, "main.tf")
    if not os.path.exists(path):
        return True, []

    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    issues = []

    # 检查是否有 resource 块
    if not re.search(r'resource\s+"\w+', content):
        issues.append("[错误] main.tf 中未找到任何 resource 定义")

    # 检查是否有使用了未定义的变量引用
    var_refs = re.findall(r'var\.(\w+)', content)
    if not var_refs:
        issues.append("[警告] main.tf 中未引用任何变量")

    # 检查 tags
    if "tags" not in content:
        issues.append("[信息] main.tf 中未发现 tags 标记（建议添加）")

    return True, issues


def validate(solution_dir):
    """主验证流程"""
    if not os.path.isdir(solution_dir):
        print(f"错误: 目录不存在: {solution_dir}")
        sys.exit(1)

    print(f"验证解决方案: {solution_dir}")
    print("=" * 60)

    required_files = [
        "versions.tf",
        "providers.tf",
        "variables.tf",
        "main.tf",
    ]

    optional_files = [
        "outputs.tf",
        ".extension",
        "README.md",
    ]

    all_passed = True

    # 文件存在性检查
    print("\n--- 文件完整性检查 ---")
    for f in required_files:
        ok, msg = check_file_exists(solution_dir, f, required=True)
        if not ok:
            all_passed = False
        print(f"  {msg}")

    for f in optional_files:
        ok, msg = check_file_exists(solution_dir, f, required=False)
        print(f"  {msg}")

    # 内容检查
    print("\n--- 内容检查 ---")
    checks = [
        ("variables.tf 规范", check_variables_tf(solution_dir)),
        ("providers.tf 安全", check_providers_tf(solution_dir)),
        ("编码规范", check_utf8_bom(solution_dir)),
        ("tfvars 排除", check_tfvars(solution_dir)),
        ("extension 格式", check_extension(solution_dir)),
        ("main.tf 结构", check_main_tf(solution_dir)),
    ]

    for name, (ok, issues) in checks:
        status = "通过" if ok else "失败"
        print(f"\n  [{status}] {name}:")
        for issue in issues:
            level = "错误" if issue.startswith("[错误]") else ("安全" if issue.startswith("[安全]") else "警告/信息")
            print(f"    {issue}")
            if issue.startswith("[错误]"):
                all_passed = False

    print("\n" + "=" * 60)
    if all_passed:
        print("验证通过: 模板结构正确")
    else:
        print("验证失败: 存在需要修复的问题")
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("用法: python validate_template.py <solution_dir>")
        sys.exit(1)
    validate(sys.argv[1])
