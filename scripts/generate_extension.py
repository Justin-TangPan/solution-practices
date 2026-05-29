#!/usr/bin/env python3
"""
.extension 文件生成器
根据 variables.tf 自动生成 .extension 文件（含参数分组）

用法:
    python generate_extension.py <solution_dir>
"""

import os
import sys
import json
import re
import argparse


def parse_variables_tf(variables_path):
    """解析 variables.tf 提取变量名和 metadata"""
    if not os.path.exists(variables_path):
        print(f"未找到 {variables_path}")
        return []

    with open(variables_path, "r", encoding="utf-8") as f:
        content = f.read()

    variables = []
    var_pattern = re.compile(r'variable\s+"(\w+)"\s*{')

    for match in var_pattern.finditer(content):
        var_name = match.group(1)
        start = match.end()
        block = content[start:]

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

        # 提取 metadata.group
        group_match = re.search(r'metadata\s*\{[^}]*group\s*=\s*"(\w+)"', var_block)
        group = group_match.group(1) if group_match else "basic_config"

        # 提取 description
        desc_match = re.search(r'description\s*=\s*"([^"]*)"', var_block)
        description = desc_match.group(1) if desc_match else ""

        # 是否敏感
        is_sensitive = "sensitive = true" in var_block

        variables.append({
            "name": var_name,
            "group": group,
            "description": description,
            "sensitive": is_sensitive,
        })

    return variables


def generate_extension(variables):
    """生成 .extension 配置"""
    # 自动发现分组
    groups = {}
    for v in variables:
        g = v["group"]
        if g not in groups:
            groups[g] = []

        groups[g].append(v)

    # 默认分组标签
    group_labels = {
        "basic_config": "基础配置",
        "network_config": "网络配置",
        "ecs_config": "ECS 配置",
        "rds_config": "数据库配置",
        "elb_config": "负载均衡配置",
        "app_config": "应用配置",
        "storage_config": "存储配置",
        "advanced_config": "高级配置",
    }

    group_descriptions = {
        "basic_config": "配置基础部署信息",
        "network_config": "配置 VPC 网络参数",
        "ecs_config": "配置云服务器规格与登录",
        "rds_config": "配置 RDS 数据库参数",
        "elb_config": "配置负载均衡相关参数",
        "app_config": "配置应用部署参数",
        "storage_config": "配置存储相关参数",
        "advanced_config": "高级配置选项",
    }

    grouping = {}
    for g in groups:
        grouping[g] = {
            "label": group_labels.get(g, g),
            "description": group_descriptions.get(g, f"{g} 配置"),
        }

    result = {
        "variables": {
            "grouping": grouping
        }
    }

    return result


def write_extension(extension_dir, data):
    """写入 .extension 文件"""
    path = os.path.join(extension_dir, ".extension")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"已生成: {path}")
    return path


def main():
    parser = argparse.ArgumentParser(description="生成 .extension 配置文件")
    parser.add_argument("solution_dir", help="解决方案目录路径")
    parser.add_argument("--output", "-o", help="输出路径（默认写入解决方案目录）")
    args = parser.parse_args()

    variables_path = os.path.join(args.solution_dir, "variables.tf")
    variables = parse_variables_tf(variables_path)

    if not variables:
        print("未解析到任何变量")
        sys.exit(1)

    print(f"解析到 {len(variables)} 个变量:")
    for v in variables:
        print(f"  {v['name']} -> group: {v['group']}")

    extension_data = generate_extension(variables)
    output_dir = args.output or args.solution_dir
    write_extension(output_dir, extension_data)

    print(f"\n分组概览:")
    for g in extension_data["variables"]["grouping"]:
        label = extension_data["variables"]["grouping"][g]["label"]
        count = sum(1 for v in variables if v["group"] == g)
        print(f"  {g} ({label}): {count} 个变量")


if __name__ == "__main__":
    main()
