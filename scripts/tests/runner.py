#!/usr/bin/env python3
"""
SAC 测试运行器
==============
统一的测试入口，扫描所有 practice 并运行预定义的检查项。

用法:
    python -m scripts.tests.runner                          # 运行所有 checks
    python -m scripts.tests.runner --practice litellm       # 仅检查 litellm
    python -m scripts.tests.runner --check tf_syntax        # 仅 TF 语法检查
    python -m scripts.tests.runner --json                   # JSON 输出
"""

import argparse
import json
import os
import sys
import time
from pathlib import Path
from dataclasses import dataclass, field, asdict

ROOT = Path(__file__).resolve().parent.parent.parent
PRACTICES_DIR = ROOT / "practices"
SKIP_DIRS = {"docs", "__pycache__", ".git", ".github"}


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


def discover_practices():
    entries = []
    for practice_dir in sorted(PRACTICES_DIR.iterdir()):
        if not practice_dir.is_dir() or practice_dir.name in SKIP_DIRS:
            continue
        pname = practice_dir.name
        for region_dir in sorted(practice_dir.iterdir()):
            if not region_dir.is_dir() or region_dir.name in SKIP_DIRS:
                continue
            for deploy_dir in sorted(region_dir.iterdir()):
                if not deploy_dir.is_dir() or deploy_dir.name in SKIP_DIRS:
                    continue

                def _has_tf_or_sh(d):
                    return (d / "terraform").is_dir() or (d / "scripts").is_dir()

                if _has_tf_or_sh(deploy_dir):
                    entries.append({
                        "name": pname,
                        "region": region_dir.name,
                        "deploy_type": deploy_dir.name,
                        "path": deploy_dir,
                    })
                else:
                    for sub in sorted(deploy_dir.iterdir()):
                        if sub.is_dir() and sub.name not in SKIP_DIRS and _has_tf_or_sh(sub):
                            entries.append({
                                "name": pname,
                                "region": region_dir.name,
                                "deploy_type": f"{deploy_dir.name}/{sub.name}",
                                "path": sub,
                            })
    return entries


def run_checks(entries, check_filter=None):
    from scripts.tests.checks import tf_syntax, scripts_audit, network_audit, consistency, documentation

    all_reports = []
    for entry in entries:
        report = PracticeReport(practice=f"{entry['name']}/{entry['region']}/{entry['deploy_type']}")
        report.start_time = time.time()
        pp = entry["path"]

        specs = [
            ("tf_syntax",   tf_syntax.run),
            ("scripts",     scripts_audit.run),
            ("network",     network_audit.run),
            ("consistency", consistency.run),
            ("docs",        documentation.run),
        ]
        for cname, fn in specs:
            if check_filter and cname not in check_filter:
                continue
            try:
                results = fn(pp, entry)
                if isinstance(results, list):
                    for r in results:
                        r.practice = report.practice
                        report.add(r)
            except Exception as e:
                report.add(CheckResult(cname, False, "ERROR", f"模块异常: {e}", practice=report.practice))

        report.end_time = time.time()
        all_reports.append(report)
    return all_reports


def print_report(reports, json_output=False):
    if json_output:
        output = []
        for r in reports:
            for c in r.checks:
                output.append(asdict(c))
        print(json.dumps(output, ensure_ascii=False, indent=2))
        return

    total_err = sum(len(r.errors) for r in reports)
    total_warn = sum(len(r.warnings) for r in reports)
    total_check = sum(len(r.checks) for r in reports)

    print("=" * 70)
    print("  SAC Solution Test Report")
    print("=" * 70)
    print(f"  Practices: {len(reports)}")
    print(f"  Checks:    {total_check}")
    print(f"  ERRORS:    {total_err}")
    print(f"  WARNINGS:  {total_warn}")
    print("=" * 70)

    for r in reports:
        if not r.errors and not r.warnings:
            continue
        print(f"\n[{r.practice}] ({r.duration}s)")
        for e in r.errors:
            msg = e.message[:100]
            print(f"  ERR [{e.check_name:12s}] {msg}")
            if e.detail:
                for line in e.detail.split("\n")[:3]:
                    print(f"       {line[:100]}")
        for w in r.warnings[:5]:
            print(f"  WRN [{w.check_name:12s}] {w.message[:100]}")

    print("\n" + "=" * 70)
    if total_err == 0:
        print("  Result: ALL PASSED")
    else:
        print(f"  Result: {total_err} ERRORS, {total_warn} WARNINGS")
    print("=" * 70)


def main():
    parser = argparse.ArgumentParser(description="SAC Solution Test Runner")
    parser.add_argument("--practice", help="Filter by practice name")
    parser.add_argument("--region", help="Filter by region code")
    parser.add_argument("--check", nargs="*", help="Check types to run")
    parser.add_argument("--json", action="store_true", help="JSON output")
    args = parser.parse_args()

    entries = discover_practices()
    if args.practice:
        entries = [e for e in entries if e["name"] == args.practice]
    if args.region:
        entries = [e for e in entries if e["region"] == args.region]

    if not entries:
        print(f"Error: no matching practices in {PRACTICES_DIR}")
        sys.exit(1)

    print(f"Found {len(entries)} practice instances\n")
    reports = run_checks(entries, args.check)
    print_report(reports, json_output=args.json)

    total_err = sum(len(r.errors) for r in reports)
    sys.exit(1 if total_err > 0 else 0)


if __name__ == "__main__":
    main()
