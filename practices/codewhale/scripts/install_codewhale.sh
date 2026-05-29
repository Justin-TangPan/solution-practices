#!/bin/bash
# ================================================
# CodeWhale — DeepSeek V4 AI 编程助手 部署脚本
# 模式: 从 OBS 拉取预编译二进制，本地安装
# 适用环境: Ubuntu 22.04 / Huawei Cloud ECS
# 用法: bash install_codewhale.sh
# ================================================

LOGFILE="/var/log/codewhale-install.log"
exec 1>"$LOGFILE" 2>&1
trap '{ set +x; } 2>/dev/null; echo -n "[$(date -Is)]  "; set -x' DEBUG

echo "========================================="
echo "[$(date)] CodeWhale deploy START"
echo "========================================="

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
APT_OPTS="-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"
dpkg --configure -a 2>/dev/null || true

HOST_IP=$(curl -s --connect-timeout 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "")
OBS_BASE="https://tp-00940108.obs.cn-south-1.myhuaweicloud.com"

# ============ 1. 系统初始化 ============
echo "[STEP] System prepare..."
apt-get $APT_OPTS update
apt-get $APT_OPTS install ca-certificates curl gnupg lsb-release cron tar
echo "[OK] System ready"

# ============ 2. 下载并安装 CodeWhale ============
echo "[STEP] Download CodeWhale from OBS..."
cd /tmp

# 从 OBS 拉取预编译二进制（国内加速）
if curl -fsSL -o codewhale-linux-x64.tar.gz "${OBS_BASE}/codewhale-linux-x64.tar.gz" 2>&1 && [ -s codewhale-linux-x64.tar.gz ]; then
  echo "[OK] Binary archive downloaded from OBS"
  tar -xzf codewhale-linux-x64.tar.gz 2>&1
  EXTRACT_DIR=$(find /tmp -maxdepth 2 -name "codewhale" -type f 2>/dev/null | head -1)
  if [ -n "$EXTRACT_DIR" ]; then
    BIN_DIR=$(dirname "$EXTRACT_DIR")
    echo "[OK] Extracted to $BIN_DIR"
    cp -f "$BIN_DIR/codewhale" /usr/local/bin/codewhale
    chmod +x /usr/local/bin/codewhale
    if [ -f "$BIN_DIR/codewhale-tui" ]; then
      cp -f "$BIN_DIR/codewhale-tui" /usr/local/bin/codewhale-tui
      chmod +x /usr/local/bin/codewhale-tui
    fi
    [ -f "$BIN_DIR/install.sh" ] && bash "$BIN_DIR/install.sh" 2>&1
  else
    echo "[WARN] Binary not found after extraction"
    ls -la /tmp/codewhale-*/ 2>&1
  fi
  rm -rf /tmp/codewhale-* 2>/dev/null
else
  echo "[WARN] OBS download failed, trying GitHub release..."
  curl -fsSL -o codewhale-linux-x64.tar.gz \
    "https://github.com/Hmbown/CodeWhale/releases/download/v0.8.47/codewhale-linux-x64.tar.gz" 2>&1
  if [ $? -eq 0 ] && [ -s codewhale-linux-x64.tar.gz ]; then
    tar -xzf codewhale-linux-x64.tar.gz
    EXTRACT_DIR=$(find /tmp -maxdepth 2 -name "codewhale" -type f 2>/dev/null | head -1)
    if [ -n "$EXTRACT_DIR" ]; then
      BIN_DIR=$(dirname "$EXTRACT_DIR")
      cp -f "$BIN_DIR/codewhale" /usr/local/bin/codewhale && chmod +x /usr/local/bin/codewhale
      [ -f "$BIN_DIR/codewhale-tui" ] && cp -f "$BIN_DIR/codewhale-tui" /usr/local/bin/codewhale-tui && chmod +x /usr/local/bin/codewhale-tui
      [ -f "$BIN_DIR/install.sh" ] && bash "$BIN_DIR/install.sh"
    fi
    rm -rf /tmp/codewhale-* 2>/dev/null
  else
    echo "[FATAL] Cannot download CodeWhale binary."
    exit 1
  fi
fi

# 验证安装
if command -v codewhale &>/dev/null; then
  echo "[OK] CodeWhale installed: $(codewhale --version 2>&1 | head -1)"
else
  echo "[WARN] codewhale binary not found in PATH"
fi

# ============ 3. 验证与帮助信息 ============
# 验证二进制是否可用（GLIBC 兼容性检查）
if command -v codewhale &>/dev/null; then
  codewhale --version &>/dev/null
  if [ $? -ne 0 ]; then
    echo "[WARN] Binary incompatible (GLIBC mismatch). Building from source..."
    # 从 OBS 拉取源码编译
    apt-get $APT_OPTS install build-essential pkg-config libdbus-1-dev curl
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>&1 | tail -3
    source "$HOME/.cargo/env"
    cd /tmp
    curl -fsSL -o codewhale-src.tar.gz "${OBS_BASE}/codewhale-src.tar.gz" 2>&1
    tar -xzf codewhale-src.tar.gz -C /opt/ 2>&1
    cd /opt/CodeWhale
    echo "[BUILD] Compiling CodeWhale (this may take 15-30 minutes)..."
    cargo build --release --locked -p codewhale-cli -p codewhale-tui 2>&1 | tail -5
    if [ -f target/release/codewhale ]; then
      cp target/release/codewhale /usr/local/bin/codewhale
      cp target/release/codewhale-tui /usr/local/bin/codewhale-tui
      echo "[OK] Source build complete"
    else
      echo "[FATAL] Source build failed"
    fi
    rm -rf /tmp/codewhale-src.tar.gz
  fi
fi

echo "========================================="
echo "[$(date)] CodeWhale deploy COMPLETE"
echo ""
echo "  使用方式:"
echo "    codewhale                            # 交互式 TUI"
echo '    codewhale "写一个 Python 脚本"        # 一次性任务'
echo "    codewhale --yolo                     # 自动批准模式"
echo ""
echo "  首次使用前配置 API Key:"
echo "    export DEEPSEEK_API_KEY=\"你的密钥\""
echo "    codewhale auth set --provider deepseek"
echo ""
echo "  更多帮助:"
echo "    codewhale --help"
echo "    https://github.com/Hmbown/CodeWhale"
echo ""
echo "  Install log: $LOGFILE"
echo "========================================="
