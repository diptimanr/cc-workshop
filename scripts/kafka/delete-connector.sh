#!/bin/bash

# 🗑️ Delete HTTP Source Connector
# This script removes the deployed HTTP Source Connector and cleans up resources

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

CONNECTOR_NAME="coingecko-price-connector"

echo -e "🗑️ ${BLUE}Deleting HTTP Source Connector${RESET}"
echo "=================================="

# First, list all connectors to see what's available
echo -e "📋 ${YELLOW}Listing all connectors...${RESET}"
confluent connect cluster list

echo ""
echo -e "🔍 ${YELLOW}Getting connector ID for '$CONNECTOR_NAME'...${RESET}"
CONNECTOR_ID=$(confluent connect cluster list 2>/dev/null | grep "$CONNECTOR_NAME" | awk '{print $1}')

if [ -z "$CONNECTOR_ID" ]; then
    echo -e "⚠️  ${YELLOW}Connector '$CONNECTOR_NAME' not found${RESET}"
    echo -e "💡 ${BLUE}Connector may already be deleted or never existed${RESET}"
    exit 0
fi

echo -e "✅ ${GREEN}Connector found with ID: $CONNECTOR_ID${RESET}"

# Confirm deletion
echo ""
echo -e "⚠️  ${YELLOW}This will permanently delete the connector and stop data ingestion${RESET}"
read -p "Are you sure you want to delete the connector? (y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "❌ ${BLUE}Deletion cancelled${RESET}"
    exit 0
fi

# Delete the connector using ID
echo ""
echo -e "🗑️ ${YELLOW}Deleting connector '$CONNECTOR_NAME' (ID: $CONNECTOR_ID)...${RESET}"
confluent connect cluster delete "$CONNECTOR_ID"

if [ $? -eq 0 ]; then
    echo -e "✅ ${GREEN}Connector deleted successfully${RESET}"
else
    echo -e "❌ ${RED}Failed to delete connector${RESET}"
    echo -e "🔍 Check your permissions and try again${RESET}"
    exit 1
fi

# Verify deletion by checking if connector ID still exists in list
echo ""
echo -e "🔍 ${YELLOW}Verifying connector deletion...${RESET}"
sleep 5

REMAINING_CONNECTOR=$(confluent connect cluster list 2>/dev/null | grep "$CONNECTOR_ID")
if [ -z "$REMAINING_CONNECTOR" ]; then
    echo -e "✅ ${GREEN}Connector successfully removed${RESET}"
else
    echo -e "⚠️  ${YELLOW}Connector may still be in deletion process${RESET}"
fi

# List remaining connectors
echo ""
echo -e "📋 ${BLUE}Remaining connectors:${RESET}"
confluent connect cluster list

echo ""
echo -e "🎉 ${GREEN}Connector deletion complete!${RESET}"
echo -e "💡 ${BLUE}Note: The 'crypto-prices' topic will remain with existing data${RESET}"
echo -e "💡 ${BLUE}Use 'confluent kafka topic delete crypto-prices' to remove the topic if needed${RESET}"
