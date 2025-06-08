#!/bin/bash

# Defending Edge Cache with Cloud Armor - Setup Script
# This script automates the initial setup for the Cloud Armor edge security demo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Defending Edge Cache with Cloud Armor Setup ===${NC}"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed${NC}"
    exit 1
fi

# Set project ID
echo -e "${YELLOW}Setting up project environment...${NC}"
export PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: No project ID found. Please run 'gcloud config set project YOUR_PROJECT_ID'${NC}"
    exit 1
fi

echo "Project ID: $PROJECT_ID"
gcloud config set project $PROJECT_ID

# Generate unique bucket name
BUCKET_NAME="${PROJECT_ID}-edge-cache-demo-$(date +%s)"
echo "Bucket name: $BUCKET_NAME"

# Create Cloud Storage bucket
echo -e "${YELLOW}Creating Cloud Storage bucket...${NC}"
gsutil mb -l us-central1 gs://$BUCKET_NAME

# Make bucket publicly readable
echo -e "${YELLOW}Configuring bucket permissions...${NC}"
gsutil iam ch allUsers:objectViewer gs://$BUCKET_NAME

# Download and upload test image
echo -e "${YELLOW}Uploading test content...${NC}"
wget --output-document google.png https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png
gsutil cp google.png gs://$BUCKET_NAME/
rm google.png

echo -e "${GREEN}Setup completed!${NC}"
echo "Bucket created: gs://$BUCKET_NAME"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Create the load balancer using the Google Cloud Console"
echo "2. Use bucket name: $BUCKET_NAME"
echo "3. Follow the README.md for detailed instructions"

# Save bucket name for later use
echo $BUCKET_NAME > .bucket_name