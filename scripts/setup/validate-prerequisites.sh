#!/bin/bash

# Prerequisites Validation Script for Confluent Cloud Workshop
# This script validates that all required tools are installed and accessible

set -euo pipefail

# Colors for output
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

# Prerequisites Validation Script for Confluent Cloud Workshop
# This script validates that all required tools are installed and accessible

echo -e "🔍 ${BLUE}Validating Workshop Prerequisites${RESET}"
echo "=================================="

# Track validation status
VALIDATION_PASSED=true

# Function to check command availability
check_command() {
    local cmd=$1
    local name=$2
    local install_url=$3
    
    if command -v "$cmd" &> /dev/null; then
        echo -e "✅ ${GREEN}$name is installed${RESET}"
        return 0
    else
        echo -e "❌ ${RED}$name is NOT installed${RESET}"
        echo "   📥 Install from: $install_url"
        VALIDATION_PASSED=false
        return 1
    fi
}

# Function to check version requirements
check_version() {
    local cmd=$1
    local name=$2
    local min_version=$3
    
    if command -v "$cmd" &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -1)
        echo -e "ℹ️  ${BLUE}$name version: $version${RESET}"
        return 0
    else
        return 1
    fi
}

echo ""
echo -e "🔧 ${YELLOW}Checking Core Tools${RESET}"
echo "----------------------"

# Check VSCode
if command -v code &> /dev/null; then
    echo -e "✅ ${GREEN}VSCode is installed${RESET}"
    
    # Check Confluent extension
    if code --list-extensions | grep -q "confluent"; then
        echo -e "✅ ${GREEN}Confluent VSCode Extension is installed${RESET}"
    else
        echo -e "❌ ${RED}Confluent VSCode Extension is NOT installed${RESET}"
        echo "   📥 Install from VSCode Extensions marketplace"
        VALIDATION_PASSED=false
    fi
else
    echo -e "❌ ${RED}VSCode is NOT installed${RESET}"
    echo "   📥 Install from: https://code.visualstudio.com/"
    VALIDATION_PASSED=false
fi

# Check Confluent CLI
check_command "confluent" "Confluent CLI" "https://docs.confluent.io/confluent-cli/current/install.html"
if command -v confluent &> /dev/null; then
    check_version "confluent" "Confluent CLI" "3.0.0"
fi

# Check DuckDB
check_command "duckdb" "DuckDB" "https://duckdb.org/docs/installation/"
if command -v duckdb &> /dev/null; then
    check_version "duckdb" "DuckDB" "0.8.0"
fi

echo ""
echo -e "🌐 ${YELLOW}Checking Network Connectivity${RESET}"
echo "--------------------------------"

# Check internet connectivity
if curl -s --connect-timeout 5 https://api.coingecko.com/api/v3/ping > /dev/null; then
    echo -e "✅ ${GREEN}CoinGecko API is accessible${RESET}"
else
    echo -e "⚠️  ${YELLOW}CoinGecko API connectivity issue${RESET}"
    echo "   🔍 Check internet connection and firewall settings"
fi

# Check Confluent Cloud connectivity
if curl -s --connect-timeout 5 https://confluent.cloud > /dev/null; then
    echo -e "✅ ${GREEN}Confluent Cloud is accessible${RESET}"
else
    echo -e "⚠️  ${YELLOW}Confluent Cloud connectivity issue${RESET}"
    echo "   🔍 Check internet connection and firewall settings"
fi

echo ""
echo -e "📊 ${YELLOW}System Information${RESET}"
echo "------------------------"

# Display system info
echo "🖥️  OS: $(uname -s) $(uname -r)"
echo "💾 Memory: $(free -h 2>/dev/null | grep '^Mem:' | awk '{print $2}' || echo 'N/A')"
echo "💽 Disk Space: $(df -h . | tail -1 | awk '{print $4}' 2>/dev/null || echo 'N/A') available"

echo ""
echo -e "📋 ${YELLOW}Validation Summary${RESET}"
echo "========================"

if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "🎉 ${GREEN}All prerequisites validated successfully!${RESET}"
    echo "✨ You're ready to start the workshop"
    exit 0
else
    echo -e "⚠️  ${RED}Some prerequisites are missing${RESET}"
    echo "🔧 Please install the missing tools before proceeding"
    echo ""
    echo -e "📚 ${BLUE}Quick Installation Commands:${RESET}"
    echo "   Confluent CLI: curl -sL --http1.1 https://cnfl.io/cli | sh -s -- latest"
    echo "   DuckDB: Visit https://duckdb.org/docs/installation/"
    echo "   VSCode: Visit https://code.visualstudio.com/"
    exit 1
fi
