#!/bin/bash
set -e

echo "🚀 Setting up Tusk Drift Python Demo environment..."

# Verify Python version (pre-installed in image)
echo "📦 Python version: $(python --version)"
echo "📦 pip version: $(pip --version)"

APT_UPDATED=0
SANDBOX_COMMANDS=(bwrap socat newuidmap newgidmap)

have() {
  command -v "$1" >/dev/null 2>&1
}

run_privileged() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
    return 0
  fi

  if have sudo; then
    sudo "$@"
    return 0
  fi

  echo "❌ Root privileges are required to install or repair Linux sandbox prerequisites."
  return 1
}

apt_install() {
  if ! have apt-get; then
    echo "❌ apt-get is unavailable, so install these packages manually: $*"
    return 1
  fi

  if [ "$APT_UPDATED" -eq 0 ]; then
    run_privileged apt-get update
    APT_UPDATED=1
  fi

  run_privileged env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

verify_linux_sandbox_commands() {
  local missing=0

  echo "🔍 Verifying Linux sandbox dependencies..."
  for cmd in "${SANDBOX_COMMANDS[@]}"; do
    if have "$cmd"; then
      echo "✅ Found $cmd at $(command -v "$cmd")"
    else
      echo "❌ Missing $cmd"
      missing=1
    fi
  done

  return "$missing"
}

run_linux_sandbox_preflight() {
  bwrap \
    --ro-bind / / \
    --unshare-user \
    --uid 0 \
    --gid 0 \
    -- \
    /bin/true >/dev/null 2>&1
}

install_linux_sandbox_packages() {
  local packages=()

  if ! have bwrap; then
    packages+=("bubblewrap")
  fi

  if ! have socat; then
    packages+=("socat")
  fi

  if ! have newuidmap || ! have newgidmap; then
    packages+=("uidmap")
  fi

  if [ "${#packages[@]}" -eq 0 ]; then
    echo "🔒 Linux sandbox dependencies already installed."
  else
    echo "🔒 Installing Linux sandbox dependencies: ${packages[*]}"
    apt_install "${packages[@]}"
    run_privileged rm -rf /var/lib/apt/lists/*
  fi

  verify_linux_sandbox_commands
}

ensure_subid_entry() {
  local file_path="$1"
  local user_name
  local block_size=65536
  local min_start=100000
  local start

  user_name="$(id -un)"

  run_privileged touch "$file_path"
  if run_privileged grep -q "^${user_name}:" "$file_path"; then
    return 0
  fi

  start="$(
    run_privileged awk -F: -v block_size="$block_size" -v min_start="$min_start" '
      BEGIN { max = min_start - 1 }
      NF >= 3 {
        start = $2 + 0
        count = $3 + 0
        end = start + count - 1
        if (end > max) {
          max = end
        }
      }
      END {
        candidate_start = max + 1
        if (candidate_start < min_start) {
          candidate_start = min_start
        }
        rem = candidate_start % block_size
        if (rem != 0) {
          candidate_start += block_size - rem
        }
        print candidate_start
      }
    ' "$file_path"
  )"

  echo "🔧 Adding $(id -un) entry to $file_path"
  printf '%s\n' "${user_name}:${start}:${block_size}" | run_privileged tee -a "$file_path" >/dev/null
}

ensure_bwrap_setuid() {
  local bwrap_path

  bwrap_path="$(command -v bwrap || true)"
  if [ -z "$bwrap_path" ]; then
    echo "❌ bwrap not found after package install"
    return 1
  fi

  if [ -u "$bwrap_path" ]; then
    echo "🔒 bwrap already has the setuid bit."
    return 0
  fi

  echo "🔧 Enabling setuid on $bwrap_path"
  run_privileged chmod u+s "$bwrap_path"
}

ensure_linux_sandbox() {
  if [ "$(uname -s)" != "Linux" ]; then
    return 0
  fi

  install_linux_sandbox_packages

  echo "🔍 Running Linux sandbox preflight..."
  if run_linux_sandbox_preflight; then
    echo "✅ Linux sandbox preflight passed."
    return 0
  fi

  echo "⚠️ Linux sandbox preflight failed; repairing common prerequisites..."
  ensure_subid_entry /etc/subuid
  ensure_subid_entry /etc/subgid
  ensure_bwrap_setuid

  echo "🔍 Re-running Linux sandbox preflight..."
  if run_linux_sandbox_preflight; then
    echo "✅ Linux sandbox preflight passed after repair."
    return 0
  fi

  echo "⚠️ Linux sandbox preflight still failed."
  echo "   This container runtime may block the required namespaces."
  echo "   Replay sandbox may require '--sandbox-mode auto' or '--sandbox-mode off'."
}

ensure_linux_sandbox

# Install pip dependencies
echo "📦 Installing pip dependencies..."
pip install --user -r requirements.txt

# Install Tusk CLI
echo "🔧 Installing Tusk CLI..."
curl -fsSL https://raw.githubusercontent.com/Use-Tusk/tusk-cli/main/install.sh | sh

# Explicitly add Tusk to PATH (the installer installs to ~/.local/bin)
export PATH="$HOME/.local/bin:$PATH"

# Source shell config if it exists (in case installer modified it)
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc" 2>/dev/null || true

# Verify Tusk installation
echo "🔍 Verifying Tusk CLI installation..."
if [ -f "$HOME/.local/bin/tusk" ]; then
  echo "✅ Tusk CLI installed successfully!"
  tusk --version 2>&1 || echo "(Tusk CLI installed but version check failed)"
  
  INTERNAL_USERS="jy-tan sohil-kshirsagar sohankshirsagar marcel-tan podocarp"
  if [[ " $INTERNAL_USERS " =~ " $GITHUB_USER " ]]; then
    echo 'export TUSK_ANALYTICS_DISABLED=1' >> "$HOME/.bashrc"
    echo 'export TUSK_ANALYTICS_DISABLED=1' >> "$HOME/.profile"
  fi
else
  echo "❌ Tusk CLI binary not found at $HOME/.local/bin/tusk"
  echo "    Installation may have failed. Try manual installation."
fi

# Display helpful information
echo ""
echo "✅ Setup complete!"
echo ""
echo "📚 Quick Start Guide:"
echo "  1. Run pre-recorded tests:      tusk drift run"
echo "  2. See Tusk CLI commands:       tusk --help"
echo "  3. Start server in record mode: TUSK_DRIFT_MODE=record python server.py"
echo "  4. Check out buggy branch:      git checkout buggy-branch"
echo ""
echo "🎉 Ready to explore Tusk Drift!"
