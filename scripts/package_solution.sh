#!/usr/bin/env bash
# 解决方案打包脚本
# 将解决方案目录打包为 RFS 可用的 zip 包
# 用法: ./package_solution.sh <solution_dir> [output_name]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOLUTION_DIR="${1:-}"
OUTPUT_NAME="${2:-}"

if [ -z "$SOLUTION_DIR" ]; then
    echo "用法: $0 <solution_dir> [output_name]"
    echo "示例: $0 ./solutions/my-web-app my-web-app-v1.0"
    exit 1
fi

if [ ! -d "$SOLUTION_DIR" ]; then
    echo "错误: 目录不存在: $SOLUTION_DIR"
    exit 1
fi

SOLUTION_DIR="$(cd "$SOLUTION_DIR" && pwd)"
SOLUTION_NAME="$(basename "$SOLUTION_DIR")"

if [ -z "$OUTPUT_NAME" ]; then
    OUTPUT_NAME="${SOLUTION_NAME}-$(date +%Y%m%d)"
fi

OUTPUT_FILE="${OUTPUT_NAME}.zip"

echo "=== 解决方案打包 ==="
echo "来源: $SOLUTION_DIR"
echo "输出: $OUTPUT_FILE"
echo ""

# 检查必需文件
echo "--- 检查必需文件 ---"
REQUIRED_FILES=("versions.tf" "providers.tf" "variables.tf" "main.tf")
MISSING=0
for f in "${REQUIRED_FILES[@]}"; do
    if [ -f "$SOLUTION_DIR/$f" ]; then
        echo "  [OK] $f"
    else
        echo "  [MISS] $f (必需)"
        MISSING=1
    fi
done

if [ $MISSING -eq 1 ]; then
    echo "错误: 缺少必需文件，取消打包"
    exit 1
fi

# 检查 .tfvars 文件
echo ""
echo "--- 检查禁止文件 ---"
TFVARS_COUNT=$(find "$SOLUTION_DIR" -name "*.tfvars" 2>/dev/null | wc -l)
if [ "$TFVARS_COUNT" -gt 0 ]; then
    echo "  [WARN] 发现 $TFVARS_COUNT 个 .tfvars 文件（打包时会排除）"
fi

# 检查文件数量
echo ""
echo "--- 检查文件数量 ---"
FILE_COUNT=$(find "$SOLUTION_DIR" -type f | wc -l)
echo "  文件总数: $FILE_COUNT"
if [ "$FILE_COUNT" -gt 100 ]; then
    echo "  [WARN] 超过 100 个文件限制"
fi

# 检查总大小
echo ""
echo "--- 检查大小 ---"
SIZE_KB=$(du -sk "$SOLUTION_DIR" | cut -f1)
echo "  目录大小: ${SIZE_KB}KB"
if [ "$SIZE_KB" -gt 1024 ]; then
    echo "  [WARN] 超过 1MB 限制（压缩后可能仍会超限）"
fi

# 创建 zip（排除 .tfvars）
echo ""
echo "--- 创建压缩包 ---"
cd "$(dirname "$SOLUTION_DIR")"
zip -r "$OUTPUT_FILE" "$SOLUTION_NAME" -x "*.tfvars" > /dev/null
cd - > /dev/null

FINAL_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
echo "  打包完成: $OUTPUT_FILE ($FINAL_SIZE)"
echo ""
echo "=== 打包成功 ==="
