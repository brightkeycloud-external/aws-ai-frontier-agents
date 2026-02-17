#!/bin/bash
# Fault injection: Remove S3 write permission from Lambda role
# Usage: ./inject-fault.sh [inject|restore]

set -euo pipefail

ROLE_NAME=$(terraform output -raw lambda_role_name)
POLICY_NAME=$(terraform output -raw lambda_role_policy_name)
BUCKET_ARN=$(aws s3api get-bucket-location --bucket "$(terraform output -raw s3_bucket)" --query 'LocationConstraint' --output text 2>/dev/null || true)
BUCKET_NAME=$(terraform output -raw s3_bucket)

ACTION="${1:-inject}"

if [ "$ACTION" = "inject" ]; then
  echo "🔴 INJECTING FAULT: Removing S3 PutObject permission from Lambda role..."

  # Get current policy, remove S3 PutObject
  CURRENT_POLICY=$(aws iam get-role-policy --role-name "$ROLE_NAME" --policy-name "$POLICY_NAME" --query 'PolicyDocument' --output json)

  echo "$CURRENT_POLICY" | jq '
    .Statement = [.Statement[] | select(.Action != ["s3:PutObject"])]
  ' > /tmp/broken-policy.json

  aws iam put-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-name "$POLICY_NAME" \
    --policy-document file:///tmp/broken-policy.json

  echo "✅ Fault injected. S3 writes will now fail."
  echo ""
  echo "Now send test messages to trigger the alarm:"
  echo "  ./send-test-orders.sh"

elif [ "$ACTION" = "restore" ]; then
  echo "🟢 RESTORING: Re-applying Terraform to restore permissions..."
  terraform apply -auto-approve -target=aws_iam_role_policy.demo-order-processor
  echo "✅ Permissions restored."
else
  echo "Usage: $0 [inject|restore]"
  exit 1
fi
