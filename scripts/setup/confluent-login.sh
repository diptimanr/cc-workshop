#!/bin/bash

# 🔐 Confluent Cloud Authentication Helper Script
# This script helps with Confluent Cloud login and context setup

# Colors for output
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

echo -e "🔐 ${BLUE}Confluent Cloud Authentication Setup${RESET}"
echo "=========================================="

# Check if Confluent CLI is installed
if ! command -v confluent &> /dev/null; then
    echo -e "❌ ${RED}Confluent CLI is not installed${RESET}"
    echo "📥 Please install it first: curl -sL --http1.1 https://cnfl.io/cli | sh -s -- latest"
    exit 1
fi

echo -e "✅ ${GREEN}Confluent CLI found${RESET}"

# Login to Confluent Cloud
echo ""
echo "🔑 Logging into Confluent Cloud..."
confluent login --save

if [ $? -eq 0 ]; then
    echo -e "✅ ${GREEN}Successfully logged into Confluent Cloud${RESET}"
else
    echo -e "❌ ${RED}Login failed. Please check your credentials.${RESET}"
    exit 1
fi

# List organizations
echo ""
echo -e " Available Organizations:"
confluent organization list

# Note: Context is automatically created during login
echo ""
echo -e "🔧 ${YELLOW}Checking current context...${RESET}"
CURRENT_CONTEXT=$(confluent context list | grep '\*' | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')
if [ -n "$CURRENT_CONTEXT" ]; then
    echo -e "✅ ${GREEN}Using context: $CURRENT_CONTEXT${RESET}"
else
    echo -e "⚠️  ${YELLOW}No active context found${RESET}"
fi

# List current contexts
echo ""
echo -e " Current CLI contexts:"
confluent context list

echo ""
echo -e " Authentication setup complete!"
echo -e " Next steps:"
echo "   1. Create an environment: confluent environment create 'cc-workshop-env'"
echo "   2. Create a Kafka cluster: confluent kafka cluster create workshop-cluster --cloud aws --region us-east-1 --type basic"
