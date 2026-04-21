import json
import os
import uuid
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource("dynamodb")
bedrock = boto3.client("bedrock-runtime")

TABLE_NAME = os.environ["TABLE_NAME"]
MODEL_ID = os.environ["MODEL_ID"]

SYSTEM_PROMPT = (
    "You are a translator that converts modern English text into Old English "
    "(Early Modern / Shakespearean style). Respond ONLY with the translated text, "
    "no explanations or preamble. Preserve the original meaning while using archaic "
    "vocabulary, grammar, and style (thee, thou, hath, doth, wherefore, etc.)."
)


def handler(event, context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
    path = event.get("rawPath", "/")

    try:
        if path == "/translate" and method == "POST":
            return translate(event)
        elif path == "/history" and method == "GET":
            return get_history()
        else:
            return response(404, {"error": "Not found"})
    except Exception as e:
        logger.error(f"Error: {e}")
        return response(500, {"error": "Internal server error"})


def translate(event):
    body = json.loads(event.get("body", "{}") or "{}")
    text = body.get("text", "").strip()
    if not text:
        return response(400, {"error": "text is required"})

    # Call Bedrock
    bedrock_body = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1024,
        "system": SYSTEM_PROMPT,
        "messages": [{"role": "user", "content": text}],
    })

    result = bedrock.invoke_model(modelId=MODEL_ID, body=bedrock_body)
    response_body = json.loads(result["body"].read())
    translated = response_body["content"][0]["text"]

    # Save to DynamoDB
    table = dynamodb.Table(TABLE_NAME)
    translation_id = str(uuid.uuid4())
    table.put_item(Item={
        "translationId": translation_id,
        "originalText": text,
        "translatedText": translated,
    })

    logger.info(f"Translation {translation_id} saved")
    return response(200, {
        "translationId": translation_id,
        "original": text,
        "translated": translated,
    })


def get_history():
    table = dynamodb.Table(TABLE_NAME)
    result = table.scan(Limit=20)
    return response(200, {"translations": result.get("Items", [])})


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "X-Content-Type-Options": "nosniff",
        },
        "body": json.dumps(body, default=str),
    }
