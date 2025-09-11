#!/bin/bash

# 🔍 Validate HTTP Source Connector Status
# This script checks the status and configuration of the deployed connector

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

CONNECTOR_NAME="coingecko-price-connector"

echo -e "🔍 ${BLUE}Validating HTTP Source Connector Status${RESET}"
echo "=============================================="

# First, list all connectors to see what's available
echo -e "📋 ${YELLOW}Listing all connectors...${RESET}"
confluent connect cluster list

echo ""
echo -e "📋 ${YELLOW}Checking connector status...${RESET}"

# Extract connector ID from the list output
echo -e "📋 ${YELLOW}Getting connector ID...${RESET}"
CONNECTOR_ID=$(confluent connect cluster list 2>/dev/null | grep "$CONNECTOR_NAME" | awk '{print $1}')

if [ -z "$CONNECTOR_ID" ]; then
    echo -e "❌ ${RED}Connector '$CONNECTOR_NAME' not found${RESET}"
    echo -e "💡 ${BLUE}Available connectors listed above${RESET}"
    echo -e "💡 ${BLUE}Run 'deploy-connector.sh' to deploy the connector first${RESET}"
    exit 1
fi

echo -e "✅ ${GREEN}Connector '$CONNECTOR_NAME' found with ID: $CONNECTOR_ID${RESET}"

# Try to get detailed connector information using ID
echo ""
echo -e "📊 ${YELLOW}Getting connector details...${RESET}"
confluent connect cluster describe "$CONNECTOR_ID" 2>/dev/null || {
    echo -e "⚠️  ${YELLOW}Could not get detailed connector status${RESET}"
    echo -e "💡 ${BLUE}This might be normal - connector may still be initializing${RESET}"
}

echo ""
echo -e "🔄 ${YELLOW}Re-checking connector status after initialization...${RESET}"
confluent connect cluster list | grep "$CONNECTOR_NAME" || {
    echo -e "⚠️  ${YELLOW}Connector not visible in list${RESET}"
}

echo ""
echo -e "✅ ${GREEN}Connector validation complete!${RESET}"
echo -e "💡 ${BLUE}Use Confluent Extension for VSCode to validate data flow${RESET}"
