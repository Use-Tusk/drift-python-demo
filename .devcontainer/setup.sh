#!/bin/bash
set -e

echo "🚀 Setting up Tusk Drift Python Demo environment..."

# Verify Python version (pre-installed in image)
echo "📦 Python version: $(python --version)"
echo "📦 pip version: $(pip --version)"

# Install pip dependencies
echo "📦 Installing pip dependencies..."
pip install --user -r requirements.txt

# Install Tusk CLI
echo "🔧 Installing Tusk CLI..."
curl -fsSL https://raw.githubusercontent.com/Use-Tusk/tusk-drift-cli/main/install.sh | sh

# Explicitly add Tusk to PATH (the installer installs to ~/.local/bin)
export PATH="$HOME/.local/bin:$PATH"

# Source shell config if it exists (in case installer modified it)
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc" 2>/dev/null || true

# Verify Tusk installation
echo "🔍 Verifying Tusk CLI installation..."
if [ -f "$HOME/.local/bin/tusk" ]; then
  echo "✅ Tusk CLI installed successfully!"
  tusk --version 2>&1 || echo "(Tusk CLI installed but version check failed)"
  
  INTERNAL_USERS="jy-tan sohil-kshirsagar sohankshirsagar marceltan podocarp"
  if [[ " $INTERNAL_USERS " =~ " $GITHUB_USER " ]]; then
    tusk analytics disable 2>/dev/null || true
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
echo "  1. Run pre-recorded tests:      tusk run"
echo "  2. See Tusk CLI commands:       tusk --help"
echo "  3. Start server in record mode: TUSK_DRIFT_MODE=record python server.py"
echo "  4. Check out buggy branch:      git checkout buggy-branch"
echo ""
echo "🎉 Ready to explore Tusk Drift!"
