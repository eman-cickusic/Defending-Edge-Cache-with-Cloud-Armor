#!/bin/bash

# Test script for Cloud Armor edge security policy
# Usage: ./test_edge_policy.sh [LOAD_BALANCER_IP]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

if [ $# -eq 0 ]; then
    echo -e "${RED}Usage: $0 [LOAD_BALANCER_IP]${NC}"
    echo "Example: $0 34.98.81.123"
    exit 1
fi

LOAD_BALANCER_IP=$1
TEST_URL="http://$LOAD_BALANCER_IP/google.png"

echo -e "${BLUE}=== Cloud Armor Edge Policy Testing ===${NC}"
echo "Testing URL: $TEST_URL"
echo ""

# Function to test URL and return status code
test_url() {
    local url=$1
    local expected_code=$2
    local description=$3
    
    echo -e "${YELLOW}Testing: $description${NC}"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$response" -eq "$expected_code" ]; then
        echo -e "${GREEN}✓ SUCCESS: Got expected $expected_code response${NC}"
        return 0
    else
        echo -e "${RED}✗ FAILED: Expected $expected_code, got $response${NC}"
        return 1
    fi
}

# Function to generate load
generate_load() {
    local url=$1
    local count=$2
    
    echo -e "${YELLOW}Generating $count requests to populate CDN cache...${NC}"
    for i in $(seq 1 $count); do
        curl -s "$url" > /dev/null
        if [ $((i % 10)) -eq 0 ]; then
            echo -n "."
        fi
    done
    echo ""
    echo -e "${GREEN}Load generation completed${NC}"
}

# Test 1: Initial connectivity (should work)
echo -e "${BLUE}--- Test 1: Baseline Connectivity ---${NC}"
test_url "$TEST_URL" 200 "Initial load balancer connectivity"
echo ""

# Test 2: Generate load to populate CDN
echo -e "${BLUE}--- Test 2: CDN Cache Population ---${NC}"
generate_load "$TEST_URL" 20
echo ""

# Test 3: Test with detailed output
echo -e "${BLUE}--- Test 3: Detailed Response Analysis ---${NC}"
echo -e "${YELLOW}Full response details:${NC}"
curl -svo /dev/null "$TEST_URL" 2>&1 | head -20
echo ""

# Test 4: Policy enforcement check
echo -e "${BLUE}--- Test 4: Security Policy Status ---${NC}"
echo -e "${YELLOW}Checking if Cloud Armor policy is active...${NC}"
response_code=$(curl -s -o /dev/null -w "%{http_code}" "$TEST_URL")

if [ "$response_code" -eq 403 ]; then
    echo -e "${GREEN}✓ Cloud Armor policy is ACTIVE (403 Forbidden)${NC}"
    echo -e "${YELLOW}This indicates the edge security policy is working${NC}"
elif [ "$response_code" -eq 200 ]; then
    echo -e "${YELLOW}⚠ Cloud Armor policy is INACTIVE (200 OK)${NC}"
    echo -e "${YELLOW}Content is being served normally${NC}"
else
    echo -e "${RED}✗ Unexpected response code: $response_code${NC}"
fi
echo ""

# Test 5: Cache verification
echo -e "${BLUE}--- Test 5: CDN Cache Verification ---${NC}"
echo -e "${YELLOW}Checking cache headers...${NC}"
curl -s -I "$TEST_URL" | grep -E "(Cache-Control|Age|X-Cache|Server)" || true
echo ""

# Test 6: Multiple requests timing
echo -e "${BLUE}--- Test 6: Response Time Analysis ---${NC}"
echo -e "${YELLOW}Testing response times (5 requests):${NC}"
for i in $(seq 1 5); do
    time_total=$(curl -s -o /dev/null -w "%{time_total}" "$TEST_URL")
    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$TEST_URL")
    echo "Request $i: ${time_total}s (HTTP $response_code)"
done
echo ""

echo -e "${BLUE}=== Test Summary ===${NC}"
echo "Load Balancer IP: $LOAD_BALANCER_IP"
echo "Test URL: $TEST_URL"
echo ""
echo -e "${YELLOW}Expected behaviors:${NC}"
echo "• HTTP 200: Policy inactive, content served from CDN"
echo "• HTTP 403: Policy active, access denied at edge"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Check Cloud Armor policies in the Console"
echo "2. Review logs in Cloud Logging"
echo "3. Monitor CDN hit ratios in Cloud CDN"