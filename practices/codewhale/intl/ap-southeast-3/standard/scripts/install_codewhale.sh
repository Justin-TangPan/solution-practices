#!/bin/bash
# ================================================
# CodeWhale — DeepSeek V4 AI Programming Assistant Deploy Script
# Mode: Download pre-compiled binary from OBS, local install
# Environment: Ubuntu 24.04 / Huawei Cloud ECS
# Usage: bash install_codewhale.sh [version]
# ================================================

set -euo pipefail

APP="codewhale"
LOG_DIR="/var/log/${APP}-deploy"
mkdir -p "$LOG_DIR"

# Main log (all stages)
RUN_LOG="${LOG_DIR}/run-all.log"
exec > >(tee -a "$RUN_LOG") 2>&1

echo "========================================="
echo "[$(date)] CodeWhale deploy START"
echo "========================================="

export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
APT_OPTS="-y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"

OBS_BASE="${OBS_BASE_URL:-https://tp-00940108.obs.ap-southeast-3.myhuaweicloud.com}"
VERSION="${1:-latest}"
# latest maps to current recommended version
[ "$VERSION" = "latest" ] && VERSION="v0.8.47"

# ============ Stage 1: System Prepare ============
echo "[$(date)][STAGE 1/4] System prepare..."
exec > >(tee -a "${LOG_DIR}/01-prepare.log") 2>&1
dpkg --configure -a 2>/dev/null || true
apt-get $APT_OPTS update
apt-get $APT_OPTS install ca-certificates curl gnupg lsb-release cron tar
echo "[OK] Stage 1 complete"

# ============ Stage 2: Download CodeWhale ============
echo "[$(date)][STAGE 2/4] Download CodeWhale..."
exec > >(tee -a "${LOG_DIR}/02-download.log") 2>&1
cd /tmp
rm -rf codewhale-linux-x64.tar.gz codewhale-*

# Priority: OBS (faster from Huawei Cloud)
if curl -fsSL --connect-timeout 10 --max-time 60 -o codewhale-linux-x64.tar.gz \
  "${OBS_BASE}/codewhale-linux-x64.tar.gz" 2>&1 && [ -s codewhale-linux-x64.tar.gz ]; then
  echo "[OK] Downloaded from OBS mirror"
# Fallback: GitHub Release
elif curl -fsSL --connect-timeout 10 --max-time 120 -o codewhale-linux-x64.tar.gz \
  "https://github.com/Hmbown/CodeWhale/releases/download/${VERSION}/codewhale-linux-x64.tar.gz" 2>&1 && [ -s codewhale-linux-x64.tar.gz ]; then
  echo "[OK] Downloaded from GitHub releases"
else
  echo "[FATAL] Cannot download CodeWhale binary from any source."
  exit 1
fi

tar -xzf codewhale-linux-x64.tar.gz 2>&1
EXTRACT_DIR=$(find /tmp -maxdepth 2 -name "codewhale" -type f 2>/dev/null | head -1)
if [ -z "$EXTRACT_DIR" ]; then
  echo "[FATAL] Binary not found after extraction"
  ls -la /tmp/ 2>&1
  exit 1
fi
echo "[OK] Stage 2 complete"

# ============ Stage 3: Install & Configure ============
echo "[$(date)][STAGE 3/4] Install & configure..."
exec > >(tee -a "${LOG_DIR}/03-setup.log") 2>&1

BIN_DIR=$(dirname "$EXTRACT_DIR")
cp -f "$BIN_DIR/codewhale" /usr/local/bin/codewhale
chmod +x /usr/local/bin/codewhale
if [ -f "$BIN_DIR/codewhale-tui" ]; then
  cp -f "$BIN_DIR/codewhale-tui" /usr/local/bin/codewhale-tui
  chmod +x /usr/local/bin/codewhale-tui
fi

# Run built-in install script if present
[ -f "$BIN_DIR/install.sh" ] && bash "$BIN_DIR/install.sh" 2>&1

rm -rf /tmp/codewhale-* /tmp/codewhale-linux-x64.tar.gz

# Verify installation
if command -v codewhale &>/dev/null; then
  echo "[OK] CodeWhale installed: $(codewhale --version 2>&1 | head -1)"
else
  echo "[FATAL] codewhale binary not found in PATH"
  exit 1
fi

# GLIBC compatibility check: build from source if binary incompatible
if ! codewhale --version &>/dev/null; then
  echo "[WARN] Binary incompatible with current GLIBC. Building from source..."
  cd /tmp

  # Install build dependencies
  apt-get $APT_OPTS install build-essential pkg-config libdbus-1-dev curl

  # Install Rust
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>&1 | tail -3
  source "$HOME/.cargo/env"

  # Download source from OBS
  if curl -fsSL --connect-timeout 10 --max-time 120 -o codewhale-src.tar.gz \
    "${OBS_BASE}/codewhale-src.tar.gz" 2>&1 && [ -s codewhale-src.tar.gz ]; then
    echo "[OK] Source archive downloaded from OBS"
    tar -xzf codewhale-src.tar.gz -C /opt/ 2>&1
    SRC_DIR=$(find /opt -maxdepth 2 -name "Cargo.toml" -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null)
    if [ -n "$SRC_DIR" ]; then
      cd "$SRC_DIR"
      echo "[BUILD] Compiling CodeWhale from source (this may take 15-30 minutes)..."
      cargo build --release --locked -p codewhale-cli -p codewhale-tui 2>&1 | tail -5
      if [ -f target/release/codewhale ]; then
        cp -f target/release/codewhale /usr/local/bin/codewhale
        [ -f target/release/codewhale-tui ] && cp -f target/release/codewhale-tui /usr/local/bin/codewhale-tui
        echo "[OK] Source build complete"
      else
        echo "[FATAL] Source build failed"
        exit 1
      fi
    else
      echo "[FATAL] Cannot find Cargo.toml in extracted source"
      exit 1
    fi
  else
    echo "[FATAL] Cannot download source archive"
    exit 1
  fi
  rm -rf /tmp/codewhale-src.tar.gz

  # Final verification
  if ! codewhale --version &>/dev/null; then
    echo "[FATAL] CodeWhale still not working after source build"
    exit 1
  fi
  echo "[OK] CodeWhale built from source: $(codewhale --version 2>&1 | head -1)"
fi

# --- systemd service ---
cat > /etc/systemd/system/codewhale.service << 'SERVICEEOF'
[Unit]
Description=CodeWhale AI Coding Agent (API Server)
Documentation=https://github.com/Hmbown/CodeWhale
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/codewhale serve --http
Restart=on-failure
RestartSec=10
User=root
EnvironmentFile=-/etc/default/codewhale

[Install]
WantedBy=multi-user.target
SERVICEEOF

# Environment config template
cat > /etc/default/codewhale << 'ENVEOF'
# CodeWhale environment config
# Please configure DEEPSEEK_API_KEY after installation
# DEEPSEEK_API_KEY=your-key-here
ENVEOF

systemctl daemon-reload
# Do not auto-start — user needs to configure API Key first
echo "[OK] systemd unit created: /etc/systemd/system/codewhale.service"
echo "[INFO] To enable: export DEEPSEEK_API_KEY=... && systemctl enable --now codewhale"

# --- Auto-upgrade crontab (weekly Sunday 3AM) ---
cat > /etc/cron.weekly/codewhale-upgrade << 'CRONEOF'
#!/bin/bash
# CodeWhale auto-upgrade script (weekly)
LOG="/var/log/codewhale-deploy/upgrade.log"
exec > >(tee -a "$LOG") 2>&1
echo "[$(date)] CodeWhale auto-upgrade check"
/usr/local/bin/codewhale --version 2>/dev/null || true
# Upgrade via npm if available
if command -v npm &>/dev/null; then
  npm update -g codewhale 2>&1 || true
fi
echo "[$(date)] Check complete"
CRONEOF
chmod +x /etc/cron.weekly/codewhale-upgrade
echo "[OK] Weekly auto-upgrade cron installed"

# --- shell completion (optional) ---
if command -v codewhale &>/dev/null; then
  codewhale completion bash > /usr/share/bash-completion/completions/codewhale 2>/dev/null || true
fi

echo "[OK] Stage 3 complete"

# ============ Stage 4: Final Verification ============
echo "[$(date)][STAGE 4/4] Final verification..."
exec > >(tee -a "${LOG_DIR}/04-verify.log") 2>&1

echo "--- Binary ---"
codewhale --version 2>&1 || echo "WARN: version check failed"
codewhale --help 2>&1 | head -5 || true

echo "--- System ---"
echo "OS: $(lsb_release -ds 2>/dev/null || uname -a)"
echo "Kernel: $(uname -r)"
echo "Arch: $(uname -m)"
echo "Disk: $(df -h / | tail -1)"

echo "--- systemd ---"
systemctl is-enabled codewhale 2>/dev/null || echo "codewhale service not enabled"
systemctl status codewhale 2>&1 | head -5 || true

echo "--- Cron ---"
ls -la /etc/cron.weekly/codewhale-upgrade 2>&1

echo "[OK] Stage 4 complete"

# ============ Summary ============
echo ""
echo "========================================="
echo "[$(date)] CodeWhale deploy COMPLETE"
echo "========================================="
echo ""
echo "  Architecture: 1 x Flexus X instance (x1.2u.4g)"
echo "  Service: CodeWhale CLI + API Server"
echo ""
echo "  Usage:"
echo "    codewhale                            # Interactive TUI"
echo '    codewhale "write a Python script"    # One-shot task'
echo "    codewhale --yolo                     # Auto-approve mode"
echo ""
echo "  First-time setup:"
echo '    export DEEPSEEK_API_KEY="your-key"'
echo "    codewhale auth set --provider deepseek"
echo ""
echo "  Start API Server:"
echo '    export DEEPSEEK_API_KEY="your-key"'
echo "    systemctl enable --now codewhale"
echo ""
echo "  Auto-upgrade: Weekly check every Sunday 3AM"
echo ""
echo "  Deploy logs: ${LOG_DIR}/"
echo "    ├── 01-prepare.log"
echo "    ├── 02-download.log"
echo "    ├── 03-setup.log"
echo "    ├── 04-verify.log"
echo "    └── run-all.log"
echo ""
echo "========================================="
