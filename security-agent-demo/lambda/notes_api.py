import json
import os
import uuid
import traceback
import urllib.request
import boto3

dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ["TABLE_NAME"]


def handler(event, context):
    table = dynamodb.Table(TABLE_NAME)
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
    path = event.get("rawPath", "/")
    body = json.loads(event.get("body", "{}") or "{}")
    params = event.get("queryStringParameters") or {}

    try:
        # VULN: No authentication on any endpoint
        if path == "/notes" and method == "POST":
            return create_note(table, body)
        elif path == "/notes" and method == "GET":
            return get_notes(table, params)
        elif path.startswith("/notes/") and method == "GET":
            note_id = path.split("/")[-1]
            return get_note(table, params, note_id)
        elif path.startswith("/notes/") and method == "DELETE":
            note_id = path.split("/")[-1]
            return delete_note(table, params, note_id)
        elif path == "/fetch" and method == "POST":
            return fetch_url(body)
        elif path == "/health":
            return response(200, {"status": "ok", "version": "1.0.0", "debug": True})
        else:
            return response(404, {"error": "Not found", "path": path, "method": method})

    except Exception as e:
        # VULN: Verbose error — leaks stack trace and internals
        return response(500, {
            "error": str(e),
            "type": type(e).__name__,
            "trace": traceback.format_exc(),
            "table": TABLE_NAME,
            "region": os.environ.get("AWS_REGION"),
            "function": os.environ.get("AWS_LAMBDA_FUNCTION_NAME"),
        })


def create_note(table, body):
    # VULN: No input validation — accepts arbitrary fields and sizes
    user_id = body.get("userId", "anonymous")
    note_id = str(uuid.uuid4())
    content = body.get("content", "")
    title = body.get("title", "Untitled")

    item = {"userId": user_id, "noteId": note_id, "title": title, "content": content}
    # VULN: Stores any extra fields from body without sanitization
    item.update({k: v for k, v in body.items() if k not in ("userId", "content", "title")})
    table.put_item(Item=item)

    return response(201, {"noteId": note_id, "userId": user_id})


def get_notes(table, params):
    # VULN: IDOR — any user can list any other user's notes
    user_id = params.get("userId", "anonymous")
    result = table.query(
        KeyConditionExpression=boto3.dynamodb.conditions.Key("userId").eq(user_id)
    )
    return response(200, {"notes": result["Items"]})


def get_note(table, params, note_id):
    # VULN: IDOR — no ownership check, any userId param retrieves any note
    user_id = params.get("userId", "anonymous")
    result = table.get_item(Key={"userId": user_id, "noteId": note_id})
    item = result.get("Item")
    if not item:
        return response(404, {"error": "Note not found"})
    return response(200, item)


def delete_note(table, params, note_id):
    # VULN: No auth, no ownership verification
    user_id = params.get("userId", "anonymous")
    table.delete_item(Key={"userId": user_id, "noteId": note_id})
    return response(200, {"deleted": note_id})


def fetch_url(body):
    # VULN: SSRF — fetches arbitrary URLs including internal metadata endpoints
    url = body.get("url", "")
    if not url:
        return response(400, {"error": "url is required"})
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=5) as resp:
        data = resp.read().decode("utf-8", errors="replace")
    return response(200, {"url": url, "status": resp.status, "body": data})


def response(status_code, body):
    # VULN: No security headers (CSP, X-Frame-Options, etc.)
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=str),
    }
