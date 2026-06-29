#!/usr/bin/env python3
"""
SAC 测试运行器
==============
统一的测试入口，扫描所有 practice 并运行预定义的检查项。

用法:
    python -m scripts.tests.runner                          # 运行所有 checks
    python -m scripts.tests.runner --practice litellm       # 仅检查 litellm
    python -m scripts.tests.runner --check network          # 仅网络检查
    python -m scripts.tests.runner --json                   # JSON 输出

检查维度:
    1. tf_syntax    — Terraform 语法与安全
    2. scripts      — Shell 脚本静态分析
    3. network      — 外部网络依赖可达性扫描
    4. docker       — Docker 镜像验证
    5. consistency  — 跨方案结构一致性
    6. docs         — 文档完整性
"""

import argparse
import glob
import json
import os
import sys
import time
from pathlib import Path
from dataclasses import dataclass, field, asdict
from typing import Optional

ROOT = Path(__file__).resolve().parent.parent.parent
PRACTICES_DIR = ROOT / "practices"


# ── 结果模型 ────────────────────────────────────────────────────────────────

@dataclass
class CheckResult:
    check_name: str
    passed: bool
    severity: str  # "ERROR" | "WARN" | "INFO"
    message: str
    detail: str = ""
    practice: str = ""
    file: str = ""


@dataclass
class PracticeReport:
    practice: str
    checks: list = field(default_factory=list)
    start_time: float = 0.0
    end_time: float = 0.0

    @property
    def duration(self):
        return round(self.end_time - self.start_time, 2)

    @property
    def errors(self):
        return [c for c in self.checks if c.severity == "ERROR"]

    @property
    def warnings(self):
        return [c for c in self.checks if c.severity == "WARN"]

    def add(self, result: CheckResult):
        self.checks.append(result)


# ── 核心逻辑 ────────────────────────────────────────────────────────────────

def discover_practices():
    """发现所有 practice 目录（含 region + deployment type）。"""
    entries = []
    # 模式: practices/{name}/{region}/{deploy-type}/
    for practice_dir in sorted(PRACTICES_DIR.iterdir()):
        if not practice_dir.is_dir():
            continue
        practice_name = practice_dir.name
        for region_dir in sorted(practice_dir.iterdir()):
            if not region_dir.is_dir():
                continue
            for deploy_dir in sorted(region_dir.iterdir()):
                if not deploy_dir.is_dir():
                    continue
                entries.append({
                    "name": practice_name,
                    "region": region_dir.name,
                    "deploy_type": deploy_dir.name,
                    "path": deploy_dir,
                })
    return entries


def run_checks(entries, check_filter=None):
    """运行所有注册的检查项。"""
    # 导入 check 模块
    from .checks import tf_syntax, scripts_audit, consistency, network_audit, documentation

    all_reports = []

    for entry in entries:
        report = PracticeReport(practice=f"{entry['name']}/{entry['region']}/{entry['deploy_type']}")
        report.start_time = time.time()
        practice_path = entry["path"]

        checks_to_run = [
            ("tf_syntax", tf_syntax.run, tf_syntax),
            ("scripts", scripts_audit.run, scripts_audit),
            ("network", network_audit.run, network_audit),
            ("consistency", consistency.run, consistency),
            ("docs", documentation.run, documentation),
        ]

        for name, run_fn, module in checks_to_run:
            if check_filter and name not in check_filter:
                continue
            try:
                results = run_fn(practice_path, entry)
                if isinstance(results, list):
                    for r in results:
                        r.practice = report.practice
                        report.add(r)
            except Exception as e:
                report.add(CheckResult(
                    check_name=name,
                    passed=False,
                    severity="ERROR",
                    message=f"检查模块异常: {e}",
                    practice=report.practice,
                ))

        report.end_time = time.time()
        all_reports.append(report)

    return all_reports


def print_report(reports, json_output=False):
    """输出测试报告。"""
    if json_output:
        output = []
        for r in reports:
            for c in r.checks:
                output.append(asdict(c))
        print(json.dumps(output, ensure_ascii=False, indent=2))
        return

    # 摘要
    total_errors = sum(len(r.errors) for r in reports)
    total_warnings = sum(len(r.warnings) for r in reports)
    total_checks = sum(len(r.checks) for r in reports)

    print("=" * 70)
    print("  SAC 解决方案测试报告")
    print("=" * 70)
    print(f"  检查 practices: {len(reports)}")
    print(f"  总检查项:      {total_checks}")
    print(f"  错误 (ERROR):   {total_errors}")
    print(f"  警告 (WARN):    {total_warnings}")
    print("=" * 70)

    # 逐 practice 详情
    for r in reports:
        if not r.errors and not r.warnings:
            continue
        print(f"\n  [{r.practice}] ({r.duration}s)")
        for c in r.errors:
            print(f"    ✗ [{c.check_name}] {c.message}")
            if c.detail:
                for line in c.detail.split("\n"):
                    print(f"      {line}")
        for c in r.warnings:
            print(f"    ⚠ [{c.check_name}] {c.message}")

    print("\n" + "=" * 70)
    if total_errors == 0:
        print("  结果: ✅ 全部通过")
    else:
        print(f"  结果: ❌ {total_errors} 个错误需要修复")
    print("=" * 70)


def main():
    parser = argparse.ArgumentParser(description="SAC 解决方案测试运行器")
    parser.add_argument("--practice", help="仅检查指定 practice (如 litellm)")
    parser.add_argument("--region", help="仅检查指定区域 (如 cn-north-4)")
    parser.add_argument("--check", nargs="*", help="仅运行指定检查 (tf_syntax scripts network ...)")
    parser.add_argument("--json", action="store_true", help="JSON 格式输出")
    args = parser.parse_args()

    entries = discover_practices()

    # 过滤
    if args.practice:
        entries = [e for e in entries if e["name"] == args.practice]
    if args.region:
        entries = [e for e in entries if e["region"] == args.region]

    if not entries:
        print(f"错误: 未找到匹配的 practice 目录 ({PRACTICES_DIR})")
        sys.exit(1)

    print(f"发现 {len(entries)} 个 practice 实例\n")

    reports = run_checks(entries, args.check)
    print_report(reports, json_output=args.json)

    total_errors = sum(len(r.errors) for r in reports)
    sys.exit(1 if total_errors > 0 else 0)


if __name__ == "__main__":
    main()
