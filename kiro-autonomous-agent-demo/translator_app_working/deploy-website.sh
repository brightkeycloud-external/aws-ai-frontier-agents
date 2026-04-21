#!/bin/bash
# Deploy the static website to S3 and update the API URL
set -euo pipefail

API_URL=$(terraform output -raw api_url)
BUCKET=$(terraform output -raw s3_bucket)
CF_DIST=$(terraform output -raw cloudfront_distribution_id)

echo "📝 Injecting API URL into index.html..."
sed "s|{{API_URL}}|${API_URL}|g" website/index.html > /tmp/index.html

echo "📤 Uploading to S3..."
aws s3 cp /tmp/index.html "s3://${BUCKET}/index.html" \
  --content-type "text/html" \
  --region us-east-1

echo "🔄 Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
  --distribution-id "$CF_DIST" \
  --paths "/*" \
  --query 'Invalidation.Id' \
  --output text

echo ""
echo "✅ Website deployed!"
echo "   URL: https://$(terraform output -raw website_url | sed 's|https://||')"
echo "   (CloudFront may take 1-2 min to propagate)"
