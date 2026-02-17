import json
import os
import uuid
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
s3 = boto3.client("s3")

TABLE_NAME = os.environ["TABLE_NAME"]
BUCKET_NAME = os.environ["BUCKET_NAME"]


def handler(event, context):
    table = dynamodb.Table(TABLE_NAME)

    for record in event["Records"]:
        body = json.loads(record["body"])
        # SNS wraps the message
        message = json.loads(body.get("Message", body)) if isinstance(body, dict) and "Message" in body else body

        order_id = message.get("orderId", str(uuid.uuid4()))
        logger.info(f"Processing order: {order_id}")

        # Write to DynamoDB
        table.put_item(Item={"orderId": order_id, "status": "processed", "data": json.dumps(message)})
        logger.info(f"Order {order_id} saved to DynamoDB")

        # Write receipt to S3 — THIS WILL FAIL when S3 permission is removed
        receipt = {"orderId": order_id, "status": "completed", "message": "Order processed successfully"}
        s3.put_object(Bucket=BUCKET_NAME, Key=f"receipts/{order_id}.json", Body=json.dumps(receipt))
        logger.info(f"Receipt for {order_id} written to S3")

    return {"statusCode": 200, "body": f"Processed {len(event['Records'])} orders"}
