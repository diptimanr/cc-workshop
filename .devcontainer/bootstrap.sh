#!/bin/bash

# 🚀 Confluent Cloud Workshop Bootstrap Script for GitHub Codespaces
# This script installs all required tools and dependencies

set -euo pipefail

# Colors for output
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

echo -e "🚀 ${BLUE}Bootstrapping Confluent Cloud Workshop Environment${RESET}"
echo "=================================================="

# Update system packages
echo -e "📦 ${YELLOW}Updating system packages...${RESET}"
sudo apt-get update -qq
sudo apt-get install -y curl wget unzip jq git make

# Install Confluent CLI
echo -e "☁️ ${YELLOW}Installing Confluent CLI...${RESET}"
curl -sL --http1.1 https://cnfl.io/cli | sh -s -- latest
# The installer puts the binary in ./bin/confluent, not ~/.confluent/bin/confluent
if [ -f "./bin/confluent" ]; then
    sudo mv ./bin/confluent /usr/local/bin/
elif [ -f "$HOME/.confluent/bin/confluent" ]; then
    sudo mv "$HOME/.confluent/bin/confluent" /usr/local/bin/
else
    # Find where it was installed
    CONFLUENT_PATH=$(find . -name "confluent" -type f 2>/dev/null | head -1)
    if [ -n "$CONFLUENT_PATH" ]; then
        sudo mv "$CONFLUENT_PATH" /usr/local/bin/
    else
        echo -e "❌ ${RED}Could not find confluent binary${RESET}"
        exit 1
    fi
fi
echo -e "✅ ${GREEN}Confluent CLI installed${RESET}"

# Install DuckDB
echo -e "🦆 ${YELLOW}Installing DuckDB...${RESET}"
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    echo -e "   🔧 ${YELLOW}ARM64 detected: using DuckDB v1.2.0 with native ARM64 support${RESET}"
    DUCKDB_VERSION="v1.2.0"
    DUCKDB_ARCH="linux-aarch64"
else
    echo -e "   💻 ${YELLOW}x86_64 detected: using DuckDB v1.3.2${RESET}"
    DUCKDB_VERSION="v1.3.2"
    DUCKDB_ARCH="linux-amd64"
fi
curl -L "https://github.com/duckdb/duckdb/releases/download/${DUCKDB_VERSION}/duckdb_cli-${DUCKDB_ARCH}.zip" -o duckdb.zip
unzip -q duckdb.zip
sudo mv duckdb /usr/local/bin/
rm duckdb.zip
sudo chmod +x /usr/local/bin/duckdb
echo -e "✅ ${GREEN}DuckDB installed${RESET}"

# Install additional Python packages for workshop
echo -e "🐍 ${YELLOW}Installing Python packages...${RESET}"
# Ensure pip is available - devcontainer features should have installed it
if command -v pip3 >/dev/null 2>&1; then
    pip3 install --user confluent-kafka[avro] requests pandas duckdb-engine sqlalchemy
elif command -v pip >/dev/null 2>&1; then
    pip install --user confluent-kafka[avro] requests pandas duckdb-engine sqlalchemy
else
    echo -e "⚠️  ${YELLOW}pip not found, installing via python3 -m pip${RESET}"
    python3 -m pip install --user confluent-kafka[avro] requests pandas duckdb-engine sqlalchemy
fi
echo -e "✅ ${GREEN}Python packages installed${RESET}"

# Install Java dependencies
echo -e "☕ ${YELLOW}Setting up Java environment...${RESET}"
# Maven dependencies will be handled by individual projects
echo -e "✅ ${GREEN}Java environment ready${RESET}"

# Create cache directory
mkdir -p /home/vscode/.cache

# Set up shell aliases and environment
echo -e "🔧 ${YELLOW}Configuring shell environment...${RESET}"
cat >> /home/vscode/.zshrc << 'EOF'

# Confluent Cloud Workshop Aliases
alias cc='confluent'
alias ccenv='confluent environment'
alias cccluster='confluent kafka cluster'
alias cctopic='confluent kafka topic'
alias ccconnector='confluent connect connector'
alias ccflink='confluent flink'

# Workshop environment variables
export WORKSHOP_ENV=codespaces
export CONFLUENT_DISABLE_UPDATES=true
export PATH=$PATH:/usr/local/bin

# Workshop helper functions
workshop-status() {
    echo "🔍 Workshop Environment Status:"
    echo "  Confluent CLI: $(confluent version 2>/dev/null || echo 'Not authenticated')"
    echo "  DuckDB: $(duckdb --version 2>/dev/null || echo 'Not available')"
    echo "  Python: $(python3 --version)"
    echo "  Java: $(java -version 2>&1 | head -1)"
}

workshop-validate() {
    echo "🧪 Running workshop prerequisites validation..."
    if [ -f "./scripts/setup/validate-prerequisites.sh" ]; then
        ./scripts/setup/validate-prerequisites.sh
    else
        echo "❌ Validation script not found. Make sure you're in the workshop root directory."
    fi
}

workshop-login() {
    echo "🔐 Starting Confluent Cloud login..."
    if [ -f "./scripts/setup/confluent-login.sh" ]; then
        ./scripts/setup/confluent-login.sh
    else
        echo "❌ Login script not found. Make sure you're in the workshop root directory."
    fi
}

EOF

# Make scripts executable
echo -e "🔐 ${YELLOW}Setting script permissions...${RESET}"
find /workspaces/*/scripts -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true

# VSCode extensions are handled automatically by devcontainer.json
echo -e "🔌 ${YELLOW}VSCode extensions will be installed automatically${RESET}"
echo -e "   📝 Students can validate and install manually if needed${RESET}"

# Create welcome message
cat > /home/vscode/.workshop-welcome << 'EOF'
🎉 Welcome to the Confluent Cloud Workshop!

Quick Start Commands:
  workshop-status     - Check environment status
  workshop-validate   - Run prerequisites validation
  workshop-login      - Login to Confluent Cloud

Workshop Structure:
  📚 guides/          - Step-by-step workshop guides
  🔧 scripts/         - Automation scripts
  📊 data/            - Sample data files
  ⚙️  configs/        - Configuration templates
  🚨 troubleshooting/ - Issue resolution guides

Next Steps:
  1. Run: workshop-validate
  2. Run: workshop-login
  3. Follow guides/01-setup-confluent-cloud.adoc

Happy learning! 🚀
EOF

# Display welcome message on terminal startup
echo 'cat /home/vscode/.workshop-welcome' >> /home/vscode/.zshrc

echo ""
echo -e "🎉 ${GREEN}Bootstrap completed successfully!${RESET}"
echo -e "🔧 ${BLUE}Environment ready for Confluent Cloud Workshop${RESET}"
echo ""
echo -e "📋 ${YELLOW}Installed Tools:${RESET}"
echo "  ✅ Confluent CLI: $(confluent version 2>/dev/null || echo 'Ready for authentication')"
echo "  ✅ DuckDB: $(duckdb --version)"
echo "  ✅ Python: $(python3 --version)"
echo "  ✅ Java: $(java -version 2>&1 | head -1)"
echo ""
echo -e "💡 ${BLUE}Restart your terminal or run 'source ~/.zshrc' to load workshop aliases${RESET}"``