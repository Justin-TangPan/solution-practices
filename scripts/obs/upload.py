#!/usr/bin/env python3
"""
OBS 私有桶交付上传
==================
把单个 practice 的交付产物上传到华为云 OBS 私有桶。

凭证只从环境变量读，绝不落盘、绝不打印：
    OBS_AK        访问密钥 ID
    OBS_SK        访问密钥
    OBS_ENDPOINT  桶 endpoint（如 obs.cn-north-4.myhuaweicloud.com）
    OBS_BUCKET    桶名

用法:
    python -m scripts.obs.upload --practice litellm --region cn-north-4 \\
        --version 0.3.2 --deploy-type standard --dry-run

规范见 scripts/obs/spec.md
"""

import argparse
import hashlib
import json
import os
import subprocess
import sys
import time
import zipfile
import io
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
PRACTICES_DIR = ROOT / "practices"

ENV_VARS = ["OBS_AK", "OBS_SK", "OBS_ENDPOINT", "OBS_BUCKET"]

# 打包时排除的模式（路径片段匹配）
EXCLUDE_FRAGMENTS = [
    ".git", "__pycache__", "node_modules", ".next", ".terraform",
    ".DS_Store", "package-lock.json",
]
EXCLUDE_SUFFIXES = [".pyc", ".pyo", ".env", ".tfstate", ".tfstate.backup"]

# OBS 对象前缀
OBS_PREFIX = "sac"


# ── 凭证 ─────────────────────────────────────────────────────────────────────

def load_creds():
    """从环境变量加载凭证。缺任一即报错退出，绝不打印已有值。"""
    creds = {}
    missing = []
    for v in ENV_VARS:
        val = os.environ.get(v)
        if not val:
            missing.append(v)
        else:
            creds[v] = val
    if missing:
        print(f"[ERROR] 缺少环境变量: {', '.join(missing)}", file=sys.stderr)
        print(f"请先设置: export {'=*** '.join(ENV_VARS)}=***", file=sys.stderr)
        print("凭证不会写入仓库，也不会出现在任何日志中。", file=sys.stderr)
        sys.exit(2)
    return creds


# ── 定位 practice ────────────────────────────────────────────────────────────

def format_entry(entry: dict) -> str:
    parts = [entry["name"], entry.get("site", ""), entry.get("locale", ""), entry["region"], entry["deploy_type"]]
    return "/".join(p for p in parts if p)


def find_practice(practice: str, region: str, deploy_type: str, locale: str = ""):
    """复用测试框架的 discover_practices 定位目标目录。"""
    sys.path.insert(0, str(ROOT))
    from scripts.tests.runner import discover_practices
    entries = discover_practices()

    matches = [
        e for e in entries
        if e["name"] == practice
        and e["region"] == region
        and e["deploy_type"] == deploy_type
        and (not locale or e.get("locale") == locale)
    ]
    if len(matches) == 1:
        return matches[0]
    if len(matches) > 1:
        print(f"[ERROR] 匹配到多个实例，请使用 --locale 指定语言版本: {practice} {region}/{deploy_type}", file=sys.stderr)
        for e in matches:
            print(f"  {format_entry(e)}", file=sys.stderr)
        sys.exit(1)

    print(f"[ERROR] 找不到 practice: {practice} {region}/{deploy_type}", file=sys.stderr)
    same_name = [e for e in entries if e["name"] == practice]
    if same_name:
        print(f"\n{practice} 可用实例:", file=sys.stderr)
        for e in same_name:
            locale_arg = f" --locale {e.get('locale')}" if e.get("locale") else ""
            print(f"  --region {e['region']} --deploy-type {e['deploy_type']}{locale_arg}", file=sys.stderr)
    else:
        all_names = sorted({e["name"] for e in entries})
        print(f"\n可用 practice: {', '.join(all_names)}", file=sys.stderr)
    sys.exit(1)


# ── 预上传密钥扫描 ────────────────────────────────────────────────────────────

def scan_for_secrets(entry: dict):
    """复用测试框架的 tf_syntax + scripts 检查，扫到 ERROR 即返回。"""
    sys.path.insert(0, str(ROOT))
    from scripts.tests.runner import run_checks
    reports = run_checks([entry], check_filter=["tf_syntax", "scripts"])
    errors = []
    for r in reports:
        for c in r.checks:
            if c.severity == "ERROR":
                errors.append(c)
    return errors


# ── 打包 ─────────────────────────────────────────────────────────────────────

def should_exclude(path: Path) -> bool:
    parts = path.parts
    for frag in EXCLUDE_FRAGMENTS:
        if frag in parts:
            return True
    for suf in EXCLUDE_SUFFIXES:
        if path.name.endswith(suf):
            return True
    return False


def collect_files(src: Path):
    """收集要打包的文件，返回相对路径列表。"""
    files = []
    for p in sorted(src.rglob("*")):
        if p.is_file() and not should_exclude(p):
            files.append(p)
    return files


def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def git_commit() -> str:
    try:
        out = subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, stderr=subprocess.DEVNULL
        )
        return out.decode().strip()
    except Exception:
        return "unknown"


def build_manifest(practice, region, deploy_type, version, files, src):
    return {
        "practice": practice,
        "region": region,
        "deploy_type": deploy_type,
        "version": version,
        "git_commit": git_commit(),
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime()) + "Z",
        "file_count": len(files),
        "files": [
            {
                "path": str(p.relative_to(src).as_posix()),
                "size": p.stat().st_size,
                "sha256": sha256_of(p),
            }
            for p in files
        ],
    }


def make_zip(zip_name: str, files, src: Path, manifest: dict) -> bytes:
    """在内存中打 zip，含 manifest.json + 所有文件。"""
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("manifest.json", json.dumps(manifest, ensure_ascii=False, indent=2))
        for p in files:
            arcname = p.relative_to(src).as_posix()
            zf.write(p, arcname)
    return buf.getvalue()


# ── OBS 操作 ─────────────────────────────────────────────────────────────────

def obs_key(practice, region, deploy_type, version, filename):
    return f"{OBS_PREFIX}/{practice}/{region}/{deploy_type}/{version}/{filename}"


def obs_url(bucket, key):
    return f"obs://{bucket}/{key}"


def connect_obs(creds):
    from obs import ObsClient
    client = ObsClient(
        access_key_id=creds["OBS_AK"],
        secret_access_key=creds["OBS_SK"],
        server=creds["OBS_ENDPOINT"],
    )
    return client


def object_exists(client, bucket, key) -> bool:
    resp = client.headObject(bucket, key)
    return resp.status < 300


def download_text(client, bucket, key) -> str:
    resp = client.getObject(bucket, key, loadStreamInMS=False)
    if resp.status < 300:
        return resp.body.response.read().decode("utf-8")
    return None


def upload_bytes(client, bucket, key, data: bytes, content_type: str = "application/octet-stream"):
    from obs import PutObjectHeader
    headers = PutObjectHeader()
    headers.contentType = content_type
    resp = client.putObject(bucket, key, content=data, headers=headers)
    if resp.status >= 300:
        raise RuntimeError(f"OBS 上传失败 status={resp.status} reason={resp.reason}")


# ── 差异对比 ─────────────────────────────────────────────────────────────────

def diff_manifests(local: dict, remote: dict):
    local_files = {f["path"]: f["sha256"] for f in local["files"]}
    remote_files = {f["path"]: f["sha256"] for f in remote.get("files", [])}
    added = [p for p in local_files if p not in remote_files]
    removed = [p for p in remote_files if p not in local_files]
    modified = [p for p in local_files if p in remote_files and local_files[p] != remote_files[p]]
    unchanged = [p for p in local_files if p in remote_files and local_files[p] == remote_files[p]]
    return added, removed, modified, unchanged


# ── 主流程 ───────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(description="上传 practice 交付产物到 OBS 私有桶")
    ap.add_argument("--practice", required=True, help="方案名（如 litellm）")
    ap.add_argument("--region", required=True, help="区域（如 cn-north-4）")
    ap.add_argument("--version", required=True, help="版本号（如 0.3.2）")
    ap.add_argument("--deploy-type", default="standard", help="部署形态 standard|ha")
    ap.add_argument("--locale", default="", help="语言版本（intl 多语言实例可用，如 en-us 或 zh-cn）")
    ap.add_argument("--dry-run", action="store_true", help="只打印将传什么，不连 OBS")
    ap.add_argument("--force", action="store_true", help="已存在时直接覆盖，不询问")
    args = ap.parse_args()

    # 1. 定位
    entry = find_practice(args.practice, args.region, args.deploy_type, args.locale)
    src: Path = entry["path"]
    print(f"[1/5] 定位: {format_entry(entry)}  ←  {src.relative_to(ROOT)}")

    # 2. 密钥扫描
    print("[2/5] 预上传密钥扫描...")
    errors = scan_for_secrets(entry)
    if errors:
        print(f"[ERROR] 扫描发现 {len(errors)} 个高危问题，中止上传:", file=sys.stderr)
        for e in errors[:10]:
            print(f"  ! [{e.check_name}] {e.message}", file=sys.stderr)
        sys.exit(3)
    print("      扫描通过，无硬编码密钥")

    # 3. 打包
    files = collect_files(src)
    manifest = build_manifest(args.practice, args.region, args.deploy_type, args.version, files, src)
    zip_name = f"{args.practice}-{args.version}-{args.region}-{args.deploy_type}.zip"
    zip_key = obs_key(args.practice, args.region, args.deploy_type, args.version, zip_name)
    manifest_key = obs_key(args.practice, args.region, args.deploy_type, args.version, "manifest.json")
    print(f"[3/5] 打包: {len(files)} 个文件 → {zip_name}")

    if args.dry_run:
        print("\n=== DRY RUN ===")
        print(f"将上传 {len(files)} 个文件:")
        for p in files[:20]:
            print(f"  {p.relative_to(src).as_posix()}")
        if len(files) > 20:
            print(f"  ... 还有 {len(files)-20} 个")
        print(f"\n目标路径:")
        print(f"  {zip_name}  →  obs://<bucket>/{zip_key}")
        print(f"  manifest.json →  obs://<bucket>/{manifest_key}")
        print(f"\nmanifest 预览:")
        print(json.dumps({k: v for k, v in manifest.items() if k != "files"}, ensure_ascii=False, indent=2))
        print("\n[dry-run] 未连接 OBS，未上传任何内容。")
        return

    # 4. 连 OBS + 检查已存在
    creds = load_creds()
    bucket = creds["OBS_BUCKET"]
    print("[4/5] 连接 OBS...")
    client = connect_obs(creds)

    if object_exists(client, bucket, manifest_key):
        print("      远端已存在同版本 manifest")
        if not args.force:
            try:
                remote_manifest_text = download_text(client, bucket, manifest_key)
                remote_manifest = json.loads(remote_manifest_text) if remote_manifest_text else {}
                added, removed, modified, unchanged = diff_manifests(manifest, remote_manifest)
                print(f"\n      与远端差异: 新增 {len(added)} / 删除 {len(removed)} / 修改 {len(modified)} / 未变 {len(unchanged)}")
                if added:
                    print(f"      新增: {added[:5]}")
                if modified:
                    print(f"      修改: {modified[:5]}")
            except Exception as e:
                print(f"      (无法读取远端 manifest: {e})")
            ans = input("\n      远端已存在，确认覆盖? 输入 yes 继续: ").strip()
            if ans != "yes":
                print("      已取消。")
                return
            print("      确认覆盖，继续上传...")
        else:
            print("      --force 已指定，直接覆盖")

    # 5. 上传
    print("[5/5] 上传...")
    zip_data = make_zip(zip_name, files, src, manifest)
    upload_bytes(client, bucket, zip_key, zip_data, content_type="application/zip")
    print(f"      ✓ {zip_name} ({len(zip_data)/1024:.1f} KB)")
    manifest_bytes = json.dumps(manifest, ensure_ascii=False, indent=2).encode("utf-8")
    upload_bytes(client, bucket, manifest_key, manifest_bytes, content_type="application/json")
    print(f"      ✓ manifest.json")

    print("\n=== 上传完成 ===")
    print(f"  zip:      {obs_url(bucket, zip_key)}")
    print(f"  manifest: {obs_url(bucket, manifest_key)}")
    print("  (私有桶，需凭证访问)")


if __name__ == "__main__":
    main()
