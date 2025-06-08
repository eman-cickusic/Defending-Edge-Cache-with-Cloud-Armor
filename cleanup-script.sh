#!/bin/bash

# Cleanup script for Cloud Armor edge security demo
# This script removes all resources created during the demo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Cloud Armor Edge Security Demo Cleanup ===${NC}"

# Get project ID
PROJECT_ID=$(gcloud config get-value project)
echo "Project ID: $PROJECT_ID"
echo ""

# Read bucket name if available
if [ -f ".bucket_name" ]; then
    BUCKET_NAME=$(cat .bucket_name)
    echo "Found bucket name: $BUCKET_NAME"
else
    echo -e "${YELLOW}Bucket name file not found. Please provide bucket name manually.${NC}"
    read -p "Enter bucket name (or press Enter to skip): " BUCKET_NAME
fi

# Confirmation prompt
echo -e "${YELLOW}This will delete the following resources:${NC}"
echo "• Load balancer: edge-cache-lb"
echo "• Backend bucket: lb-backend-bucket"
echo "• Cloud Armor policy: edge-security-policy"
if [ ! -z "$BUCKET_NAME" ]; then
    echo "• Cloud Storage bucket: $BUCKET_NAME"
fi
echo ""

read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 1
fi

echo -e "${YELLOW}Starting cleanup process...${NC}"

# Function to safely delete resource
safe_delete() {
    local command="$1"
    local resource_name="$2"
    
    echo -e "${YELLOW}Deleting $resource_name...${NC}"
    
    if eval "$command" 2>/dev/null; then
        echo -e "${GREEN}✓ Successfully deleted $resource_name${NC}"
    else
        echo -e "${YELLOW}⚠ $resource_name not found or already deleted${NC}"
    fi
}

# Delete Cloud Armor security policy
echo -e "${BLUE}--- Cleaning up Cloud Armor policy ---${NC}"
safe_delete "gcloud compute security-policies delete edge-security-policy --quiet" "edge-security-policy"
echo ""

# Delete load balancer components
echo -e "${BLUE}--- Cleaning up Load Balancer ---${NC}"

# Delete URL map
safe_delete "gcloud compute url-maps delete edge-cache-lb --quiet" "URL map edge-cache-lb"

# Delete backend bucket
safe_delete "gcloud compute backend-buckets delete lb-backend-bucket --quiet" "backend bucket lb-backend-bucket"

# Delete target HTTP proxy
safe_delete "gcloud compute target-http-proxies delete edge-cache-lb-target-proxy --quiet" "target HTTP proxy"

# Delete forwarding rule
safe_delete "gcloud compute forwarding-rules delete edge-cache-lb-forwarding-rule --global --quiet" "forwarding rule"

echo ""

# Delete Cloud Storage bucket
if [ ! -z "$BUCKET_NAME" ]; then
    echo -e "${BLUE}--- Cleaning up Cloud Storage ---${NC}"
    
    # Check if bucket exists and has objects
    if gsutil ls gs://$BUCKET_NAME >/dev/null 2>&1; then
        echo -e "${YELLOW}Removing all objects from bucket...${NC}"
        gsutil rm -r gs://$BUCKET_NAME/* 2>/dev/null || true
        
        echo -e "${YELLOW}Deleting bucket...${NC}"
        if gsutil rb gs://$BUCKET_NAME; then
            echo -e "${GREEN}✓ Successfully deleted bucket $BUCKET_NAME${NC}"
        else
            echo -e "${RED}✗ Failed to delete bucket $BUCKET_NAME${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Bucket $BUCKET_NAME not found${NC}"
    fi
    echo ""
fi

# Clean up local files
echo -e "${BLUE}--- Cleaning up local files ---${NC}"
if [ -f ".bucket_name" ]; then
    rm .bucket_name
    echo -e "${GREEN}✓ Removed .bucket_name file${NC}"
fi

echo ""
echo -e "${GREEN}=== Cleanup Complete ===${NC}"
echo -e "${YELLOW}Summary:${NC}"
echo "• All Cloud Armor policies removed"
echo "• Load balancer and related resources deleted"
echo "• Cloud Storage bucket cleaned up"
echo "• Local temporary files removed"
echo ""
echo -e "${BLUE}Note: It may take a few minutes for all resources to be fully removed.${NC}"

# Optional: Check for any remaining resources
echo ""
read -p "Would you like to check for any remaining resources? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Checking for remaining resources...${NC}"
    
    echo "Load balancers:"
    gcloud compute url-maps list --filter="name:edge-cache-lb" || true
    
    echo "Backend buckets:"
    gcloud compute backend-buckets list --filter="name:lb-backend-bucket" || true
    
    echo "Security policies:"
    gcloud compute security-policies list --filter="name:edge-security-policy" || true
    
    echo "Storage buckets:"
    gsutil ls | grep -i edge-cache || echo "No edge-cache buckets found"
fi