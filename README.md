# Defending Edge Cache with Cloud Armor

A comprehensive guide to implementing Google Cloud Armor edge security policies with Cloud CDN and Cloud Storage to restrict access to cached objects at Google's network edge.

## Overview

This project demonstrates how to use Google Cloud Armor edge security policies to protect cached content on Cloud CDN and Cloud Storage. Edge security policies are deployed at the outermost perimeter of Google's network, upstream of the Cloud CDN cache, providing robust security for content distribution.

### Use Cases
- Restrict access to storage bucket objects from specific geographies
- Filter media distribution based on licensing requirements
- Implement security controls at the network edge before content reaches CDN cache

## Architecture

```
Internet → Cloud Armor Edge Policy → Cloud CDN → Load Balancer → Cloud Storage
```

## What You'll Learn

- Set up a Cloud Storage Bucket with cacheable content
- Create and configure edge security policies
- Validate edge security policy effectiveness
- Monitor and troubleshoot security policy enforcement

## Prerequisites

- Google Cloud Platform account with billing enabled
- Basic understanding of Cloud Storage, Load Balancing, and CDN concepts
- Access to Google Cloud Console and Cloud Shell

## Setup Instructions

### Step 1: Environment Setup

```bash
# Set your Project ID
export PROJECT_ID=$(gcloud config get-value project)
echo $PROJECT_ID
gcloud config set project $PROJECT_ID
```

### Step 2: Create Cloud Storage Bucket and Upload Content

1. **Create the bucket:**
   - Navigate to Cloud Storage > Buckets in the Console
   - Click CREATE
   - Set bucket name (replace `[BUCKET_NAME]` with your chosen name)
   - Choose Region for location type
   - Select Standard storage class
   - Uncheck "Enforce public access prevention"
   - Choose Fine-grained access control

2. **Upload test content:**
```bash
# Download Google logo for testing
wget --output-document google.png https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png

# Upload to your bucket
gsutil cp google.png gs://[BUCKET_NAME]

# Clean up local file
rm google.png
```

3. **Make object publicly accessible:**
   - Go to your bucket in the Console
   - Click the three dots next to your uploaded object
   - Select "Edit access"
   - Add entry with Entity: Public
   - Save changes

### Step 3: Create HTTP Load Balancer

1. **Navigate to Load Balancing:**
   - Go to Network services > Load Balancing
   - Click CREATE LOAD BALANCER

2. **Configure load balancer:**
   - Type: Application Load Balancer (HTTP/HTTPS)
   - Public facing (external)
   - Global workloads
   - Global external Application Load Balancer
   - Name: `edge-cache-lb`

3. **Frontend Configuration:**
   - Protocol: HTTP
   - IP: Ephemeral
   - Network tier: Premium (default)

4. **Backend Configuration:**
   - Create backend bucket: `lb-backend-bucket`
   - Select your Cloud Storage bucket
   - Keep default settings

5. **Routing Rules:**
   - Use simple host and path rule (default)

### Step 4: Test Load Balancer

```bash
# Replace [LOAD_BALANCER_IP] with your actual load balancer IP
curl -svo /dev/null http://[LOAD_BALANCER_IP]/google.png

# Generate some traffic to populate CDN cache
for i in `seq 1 50`; do curl http://[LOAD_BALANCER_IP]/google.png; done
```

Verify CDN is working by checking Network Services > Cloud CDN for hit ratio statistics.

### Step 5: Delete Object from Storage (Testing CDN Cache)

- Go to Cloud Storage > Buckets > [BUCKET_NAME]
- Select and delete the uploaded object
- This proves content is served from CDN cache, not origin

### Step 6: Create Edge Security Policy

1. **Create the policy:**
   - Navigate to Network Security > Cloud Armor policies
   - Click Create Policy
   - Name: `edge-security-policy`
   - Policy type: Edge security policy
   - Default rule action: Deny

2. **Apply to targets:**
   - Add Target
   - Type: Backend bucket (external application load balancer)
   - Target: `lb-backend-bucket`

### Step 7: Validate Security Policy

```bash
# This should return 403 Forbidden
curl -svo /dev/null http://[LOAD_BALANCER_IP]/google.png
```

### Step 8: Check Logs

1. Navigate to Observability > Logging > Logs Explorer
2. Run this query:
```
resource.type:(http_load_balancer) AND jsonPayload.@type="type.googleapis.com/google.cloud.loadbalancing.type.LoadBalancerLogEntry" AND severity>=WARNING
```
3. Verify 403 responses and policy enforcement

### Step 9: Remove Security Policy (Validation)

1. Go to Cloud Armor policies > edge-security-policy > Targets
2. Remove the `lb-backend-bucket` target
3. Test again:
```bash
# Should return 200 OK, proving content served from CDN cache
curl -svo /dev/null http://[LOAD_BALANCER_IP]/google.png
```

## Key Concepts

### Edge Security Policies
- Enforced at Google's network edge, upstream of CDN
- Provide geographic restrictions and access controls
- Applied before content reaches CDN cache

### Cloud CDN Integration
- Works seamlessly with Cloud Armor policies
- Maintains cache efficiency while enforcing security
- Provides detailed monitoring and analytics

### Load Balancer Integration
- Backend buckets connect Cloud Storage to load balancers
- Enables CDN and security policy attachment
- Supports both HTTP and HTTPS protocols

## Monitoring and Troubleshooting

### Checking Policy Status
```bash
# Check if policy is working (should get 403)
curl -svo /dev/null http://[LOAD_BALANCER_IP]/google.png
```

### Log Analysis
- Use Cloud Logging to monitor policy enforcement
- Look for 403 responses in load balancer logs
- Monitor CDN hit ratios and cache performance

### Common Issues
- **Policy not enforcing:** Wait 2-5 minutes after policy creation
- **CDN not caching:** Check cache-control headers and CDN configuration
- **403 errors persist:** Verify policy target removal was successful

## Best Practices

1. **Testing:** Always test policies in non-production environments first
2. **Monitoring:** Set up alerting for policy violations and CDN performance
3. **Documentation:** Keep track of policy rules and their business justifications
4. **Gradual Deployment:** Roll out policies incrementally to avoid service disruption

## Cleanup

To avoid ongoing charges, clean up resources:

```bash
# Delete the load balancer
gcloud compute forwarding-rules delete edge-cache-lb-forwarding-rule --global

# Delete the backend bucket
gcloud compute backend-buckets delete lb-backend-bucket

# Delete the Cloud Armor policy
gcloud compute security-policies delete edge-security-policy

# Delete the Cloud Storage bucket
gsutil rb gs://[BUCKET_NAME]
```

## Additional Resources

- [Cloud Armor Documentation](https://cloud.google.com/armor/docs)
- [Cloud CDN Documentation](https://cloud.google.com/cdn/docs)
- [Load Balancing Documentation](https://cloud.google.com/load-balancing/docs)
- [Cloud Storage Documentation](https://cloud.google.com/storage/docs)

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details.
