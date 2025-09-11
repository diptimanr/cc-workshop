#!/bin/bash

# Confluent Cloud Workshop - Resource Validation Script
# This script validates that all workshop resources have been properly deleted
# Based on guides/05-teardown-resources.adoc verification steps

# Color definitions for output
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
RESET='\033[0m'

# Exit codes
SUCCESS=0
WARNING=1
ERROR=2

# Global variables
ISSUES_FOUND=0
WARNINGS_FOUND=0

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS")
            echo -e "${GREEN}✅ $message${RESET}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  $message${RESET}"
            WARNINGS_FOUND=$((WARNINGS_FOUND + 1))
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${RESET}"
            ISSUES_FOUND=$((ISSUES_FOUND + 1))
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${RESET}"
            ;;
        "HEADER")
            echo -e "${CYAN}🔍 $message${RESET}"
            ;;
    esac
}

# Function to check if confluent CLI is available
check_cli() {
    if ! command -v confluent &> /dev/null; then
        print_status "ERROR" "Confluent CLI not found. Please install it first."
        exit $ERROR
    fi
    
    # Check if user is logged in
    if ! confluent context list &> /dev/null; then
        print_status "ERROR" "Not logged into Confluent Cloud. Run 'confluent login' first."
        exit $ERROR
    fi
}

# Function to check Flink resources (HIGH COST)
check_flink_resources() {
    print_status "HEADER" "Checking Flink Resources (High Cost Priority)"
    
    # Check Flink compute pools
    local pools_output
    pools_output=$(confluent flink compute-pool list --output json 2>/dev/null)
    local pools_count
    pools_count=$(echo "$pools_output" | jq '. | length' 2>/dev/null || echo "0")
    
    if [[ "$pools_count" -gt 0 ]]; then
        print_status "ERROR" "Found $pools_count Flink compute pool(s) - these generate ongoing charges!"
        echo "$pools_output" | jq -r '.[] | "  - Pool ID: \(.id), Name: \(.name), Status: \(.status)"' 2>/dev/null
    else
        print_status "SUCCESS" "No Flink compute pools found"
    fi
    
    # Check Flink statements/applications
    local statements_output
    statements_output=$(confluent flink statement list --output json 2>/dev/null)
    local statements_count
    statements_count=$(echo "$statements_output" | jq '. | length' 2>/dev/null || echo "0")
    
    if [[ "$statements_count" -gt 0 ]]; then
        print_status "ERROR" "Found $statements_count Flink statement(s) still running!"
        echo "$statements_output" | jq -r '.[] | "  - Statement: \(.name // "unnamed"), Status: \(.status // "unknown")"' 2>/dev/null
    else
        print_status "SUCCESS" "No Flink statements found"
    fi
}

# Function to check Tableflow resources (MEDIUM COST)
check_tableflow_resources() {
    print_status "HEADER" "Checking Tableflow Resources (Medium Cost Priority)"
    
    # Check Tableflow catalog integrations
    local catalogs_output
    catalogs_output=$(confluent tableflow catalog-integration list --output json 2>/dev/null)
    local catalogs_count
    catalogs_count=$(echo "$catalogs_output" | jq '. | length' 2>/dev/null || echo "0")
    
    if [[ "$catalogs_count" -gt 0 ]]; then
        print_status "ERROR" "Found $catalogs_count Tableflow catalog integration(s) - these incur storage costs!"
        echo "$catalogs_output" | jq -r '.[] | "  - Catalog ID: \(.id // "unknown"), Name: \(.display_name // "unknown"), Status: \(.status // "unknown")"' 2>/dev/null
    else
        print_status "SUCCESS" "No Tableflow catalog integrations found"
    fi
    
    # Check Tableflow topic enablement
    if [ -n "$CC_KAFKA_CLUSTER" ]; then
        local tableflow_topics_output
        tableflow_topics_output=$(confluent tableflow topic list --cluster "$CC_KAFKA_CLUSTER" --output json 2>/dev/null)
        local tableflow_topics_count
        tableflow_topics_count=$(echo "$tableflow_topics_output" | jq '. | length' 2>/dev/null || echo "0")
        
        if [[ "$tableflow_topics_count" -gt 0 ]]; then
            print_status "ERROR" "Found $tableflow_topics_count Tableflow-enabled topic(s)!"
            echo "$tableflow_topics_output" | jq -r '.[] | "  - Topic: \(.topic_name), Phase: \(.phase), Suspended: \(.suspended)"' 2>/dev/null
        else
            print_status "SUCCESS" "No Tableflow-enabled topics found"
        fi
    else
        print_status "WARNING" "CC_KAFKA_CLUSTER not set, skipping Tableflow topic check"
    fi
}

# Function to check connectors
check_connectors() {
    print_status "HEADER" "Checking Connectors"
    
    local connectors_output
    connectors_output=$(confluent connect connector list --output json 2>/dev/null)
    local connectors_count
    connectors_count=$(echo "$connectors_output" | jq '. | length' 2>/dev/null || echo "0")
    
    if [[ "$connectors_count" -gt 0 ]]; then
        # Check for workshop-specific topics
        local expected_topics=("crypto-prices" "price-alerts" "crypto-prices-exploded" "crypto-trends")
        local found_topics=()
        
        for topic in "${expected_topics[@]}"; do
            if echo "$topics_output" | jq -e --arg topic "$topic" '.[] | select(.name == $topic)' >/dev/null 2>&1; then
                found_topics+=("$topic")
            fi
        done
        
        if [[ ${#found_topics[@]} -gt 0 ]]; then
            print_status "WARNING" "Found workshop-related topic(s):"
            for topic in "${found_topics[@]}"; do
                echo "  - $topic"
            done
        fi
        
        # Check for workshop-specific connectors
        local workshop_connectors
        workshop_connectors=$(echo "$connectors_output" | jq -r '.[] | select(.name | contains("coingecko") or contains("workshop")) | .name' 2>/dev/null)
        
        if [[ -n "$workshop_connectors" ]]; then
            print_status "ERROR" "Found workshop-related connector(s):"
            echo "$workshop_connectors" | while read -r connector; do
                echo "  - $connector"
            done
        else
            print_status "INFO" "Found $connectors_count connector(s), but none appear workshop-related"
        fi
    else
        print_status "SUCCESS" "No connectors found"
    fi
}

# Function to check Kafka clusters
check_kafka_clusters() {
    print_status "HEADER" "Checking Kafka Clusters"
    
    local clusters_output
    clusters_output=$(confluent kafka cluster list --output json 2>/dev/null)
    local clusters_count
    clusters_count=$(echo "$clusters_output" | jq '. | length' 2>/dev/null || echo "0")
    
    if [[ "$clusters_count" -gt 0 ]]; then
        # Check for non-Basic clusters (which incur charges)
        local paid_clusters
        paid_clusters=$(echo "$clusters_output" | jq -r '.[] | select(.type != "BASIC") | "\(.id) (\(.type))"' 2>/dev/null)
        
        if [[ -n "$paid_clusters" ]]; then
            print_status "ERROR" "Found paid cluster(s) - these generate charges:"
            echo "$paid_clusters" | while read -r cluster; do
                echo "  - Cluster: $cluster"
            done
        fi
        
        # Check for workshop-named clusters
        local workshop_clusters
        workshop_clusters=$(echo "$clusters_output" | jq -r '.[] | select(.name | contains("workshop")) | "\(.name) (\(.type))"' 2>/dev/null)
        
        if [[ -n "$workshop_clusters" ]]; then
            print_status "WARNING" "Found workshop-named cluster(s):"
            echo "$workshop_clusters" | while read -r cluster; do
                echo "  - $cluster"
            done
        fi
        
        if [[ -z "$paid_clusters" && -z "$workshop_clusters" ]]; then
            print_status "SUCCESS" "Found $clusters_count cluster(s), all appear to be Basic (free) tier"
        fi
    else
        print_status "SUCCESS" "No Kafka clusters found"
    fi
}

# Function to check API keys
check_api_keys() {
    print_status "HEADER" "Checking API Keys"
    
    local keys_output
    keys_output=$(confluent api-key list --output json 2>/dev/null)
    local keys_count
    keys_count=$(echo "$keys_output" | jq '. | length' 2>/dev/null || echo "0")
    
    if [[ "$keys_count" -gt 0 ]]; then
        # Check for workshop-related API keys
        local workshop_keys
        workshop_keys=$(echo "$keys_output" | jq -r '.[] | select(.description | contains("workshop") or contains("Workshop")) | "\(.key) - \(.description)"' 2>/dev/null)
        
        if [[ -n "$workshop_keys" ]]; then
            print_status "WARNING" "Found workshop-related API key(s):"
            echo "$workshop_keys" | while read -r key; do
                echo "  - $key"
            done
        else
            print_status "INFO" "Found $keys_count API key(s), none appear workshop-related"
        fi
    else
        print_status "SUCCESS" "No API keys found"
    fi
}

# Function to check environments
check_environments() {
    print_status "HEADER" "Checking Environments"
    
    local envs_output
    envs_output=$(confluent environment list --output json 2>/dev/null)
    local workshop_envs
    workshop_envs=$(echo "$envs_output" | jq -r '.[] | select(.name | contains("workshop") or contains("cc-workshop")) | "\(.id) - \(.name)"' 2>/dev/null)
    
    if [[ -n "$workshop_envs" ]]; then
        print_status "WARNING" "Found workshop-related environment(s):"
        echo "$workshop_envs" | while read -r env; do
            echo "  - $env"
        done
    else
        print_status "SUCCESS" "No workshop-related environments found"
    fi
}

# Function to provide cost monitoring guidance
provide_cost_guidance() {
    print_status "HEADER" "Cost Monitoring Guidance"
    
    echo -e "${BLUE}🌐 Please verify in Confluent Cloud Console:${RESET}"
    echo "1. Go to: https://confluent.cloud"
    echo "2. Navigate to: Billing & Payment → Usage"
    echo "3. Verify: No active Flink or Tableflow charges"
    echo "4. Check: Only Basic cluster (free) or expected resources remain"
    echo ""
    
    if [[ $ISSUES_FOUND -gt 0 ]]; then
        echo -e "${RED}💰 URGENT: You have $ISSUES_FOUND critical issue(s) that may generate charges!${RESET}"
        echo "Run the emergency cleanup script from the teardown guide immediately."
    elif [[ $WARNINGS_FOUND -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  You have $WARNINGS_FOUND warning(s) to review.${RESET}"
        echo "Consider cleaning up these resources if they're no longer needed."
    else
        echo -e "${GREEN}🎉 Excellent! No cost-generating resources found.${RESET}"
    fi
}

# Main execution
main() {
    echo -e "${CYAN}🧹 Confluent Cloud Workshop - Resource Validation${RESET}"
    echo -e "${CYAN}=================================================${RESET}"
    echo "Checking for remaining billable resources..."
    echo ""
    
    # Check CLI availability
    check_cli
    
    # Check resources in order of cost priority
    check_flink_resources
    echo ""
    
    check_tableflow_resources
    echo ""
    
    check_connectors
    echo ""
    
    check_kafka_clusters
    echo ""
    
    check_api_keys
    echo ""
    
    check_environments
    echo ""
    
    # Provide guidance
    provide_cost_guidance
    
    # Exit with appropriate code
    if [[ $ISSUES_FOUND -gt 0 ]]; then
        exit $ERROR
    elif [[ $WARNINGS_FOUND -gt 0 ]]; then
        exit $WARNING
    else
        exit $SUCCESS
    fi
}

# Run main function
main "$@"
