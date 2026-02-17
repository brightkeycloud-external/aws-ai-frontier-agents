#!/bin/bash
# Send test orders to SNS to trigger Lambda processing
set -euo pipefail

TOPIC_ARN=$(terraform output -raw sns_topic_arn)

echo "📤 Sending 10 test orders to SNS..."
for i in $(seq 1 10); do
  ORDER_ID="order-$(date +%s)-$i"
  aws sns publish \
    --topic-arn "$TOPIC_ARN" \
    --message "{\"orderId\": \"$ORDER_ID\", \"item\": \"widget-$i\", \"quantity\": $i}" \
    --region us-east-1 \
    --output text > /dev/null
  echo "  Sent $ORDER_ID"
done

echo ""
echo "✅ Orders sent. If fault is injected, Lambda errors should appear within ~1 min."
echo "   Monitor: aws cloudwatch describe-alarms --alarm-names $(terraform output -raw lambda_function_name | sed 's/demo-devops-agent-order-processor/demo-devops-agent-lambda-errors/') --region us-east-1"
