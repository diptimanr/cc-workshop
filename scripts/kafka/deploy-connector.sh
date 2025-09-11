#!/bin/bash

# 🚀 Deploy HTTP Source Connector for CoinGecko API
# This script deploys the HTTP Source Connector to stream cryptocurrency price data

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

CONNECTOR_NAME="coingecko-price-connector"

# Source environment variables from .env file if it exists
if [ -f ".env" ]; then
    echo -e " ${BLUE}Loading environment variables from .env file...${RESET}"
    source .env
fi

echo -e " ${BLUE}Deploying HTTP Source Connector${RESET}"
echo "=================================="

# Check for required environment variables
echo -e " ${YELLOW}Checking environment variables...${RESET}"
if [ -z "$KAFKA_API_KEY" ] || [ -z "$KAFKA_API_SECRET" ]; then
    echo -e " ${RED}Missing required environment variables${RESET}"
    echo -e " ${BLUE}Please set the following environment variables or create .env file:${RESET}"
    echo -e "   export KAFKA_API_KEY=\"your-api-key\""
    echo -e "   export KAFKA_API_SECRET=\"your-api-secret\""
    echo -e " ${BLUE}Or run: source .env${RESET}"
    exit 1
fi

# Use existing config file or create from template
CONFIG_FILE="../configs/connector-configs/http-source-coingecko.json"
TEMP_CONFIG="/tmp/coingecko-connector.json"

if [ -f "$CONFIG_FILE" ]; then
    echo -e "📝 ${YELLOW}Using existing connector configuration...${RESET}"
    # Substitute environment variables in the config
    envsubst < "$CONFIG_FILE" > "$TEMP_CONFIG"
else
    echo -e "📝 ${YELLOW}Creating connector configuration...${RESET}"
    
    cat > "$TEMP_CONFIG" << EOF
{
  "name": "coingecko-price-connector",
  "config": {
    "connector.class": "HttpSource",
    "kafka.auth.mode": "KAFKA_API_KEY",
    "kafka.api.key": "${KAFKA_API_KEY}",
    "kafka.api.secret": "${KAFKA_API_SECRET}",
    "topic.name.pattern": "crypto-prices",
    "url": "https://api.coingecko.com/api/v3/simple/price",
    "http.request.parameters": "ids=bitcoin,ethereum,binancecoin,cardano,solana&vs_currencies=usd&include_market_cap=true&include_24hr_vol=true&include_24hr_change=true&include_last_updated_at=true",
    "request.interval.ms": "60000",
    "output.data.format": "AVRO",
    "tasks.max": "1",
    "http.initial.offset": "0"
  }
}
EOF
fi

echo -e "✅ ${GREEN}Connector configuration ready${RESET}"

# Deploy the connector
echo ""
echo -e "🚀 ${YELLOW}Deploying HTTP Source Connector...${RESET}"

confluent connect cluster create --config-file "$TEMP_CONFIG"

if [ $? -eq 0 ]; then
    echo -e "✅ ${GREEN}Connector deployed successfully${RESET}"
    echo -e "💡 ${BLUE}Use 'validate-connector.sh' to check connector status${RESET}"
    echo -e "📊 ${BLUE}Use Confluent Extension for VSCode to validate data flow${RESET}"
else
    echo -e "❌ ${RED}Failed to deploy connector${RESET}"
    echo -e "🔍 Check your API credentials and cluster configuration"
    exit 1
fi

# Cleanup
rm -f "$TEMP_CONFIG"

echo ""
echo -e "🎉 ${GREEN}Connector deployment complete!${RESET}"
