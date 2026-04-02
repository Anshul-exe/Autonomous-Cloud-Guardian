import json
import boto3
import gzip
import base64
import os
import urllib3
from datetime import datetime

http = urllib3.PoolManager()
SLACK_WEBHOOK_URL = os.environ['SLACK_WEBHOOK_URL']

def send_slack_alert(log_group, errors):
    """Send error alert to Slack"""
    error_preview = '\n'.join(errors[:5])  # Show max 5 errors
    
    message = {
        "text": f"""🚨 *Cloud Guardian - Error Alert*
*Log Group:* `{log_group}`
*Errors Detected:* {len(errors)}
*Timestamp:* {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}

```
{error_preview}
```
{'...(truncated)' if len(errors) > 5 else ''}""",
        "username": "Cloud Guardian Bot",
        "icon_emoji": ":rotating_light:"
    }
    
    resp = http.request('POST', SLACK_WEBHOOK_URL,
                        body=json.dumps(message).encode('utf-8'))
    print(f"Slack response: {resp.status}")

def lambda_handler(event, context):
    """Process CloudWatch Logs and alert on errors"""
    
    # Decode and decompress CloudWatch Logs data
    compressed_payload = base64.b64decode(event['awslogs']['data'])
    log_data = json.loads(gzip.decompress(compressed_payload))
    
    log_group = log_data.get('logGroup', 'unknown')
    log_stream = log_data.get('logStream', 'unknown')
    
    print(f"Processing logs from {log_group}/{log_stream}")
    
    # Collect error messages
    errors = []
    for log_event in log_data.get('logEvents', []):
        message = log_event.get('message', '')
        
        # Check for error patterns
        error_patterns = ['ERROR', 'FATAL', 'Exception', 'CRITICAL', 'Traceback']
        if any(pattern in message for pattern in error_patterns):
            errors.append(message.strip()[:200])  # Limit message length
    
    if errors:
        print(f"Found {len(errors)} errors, sending Slack alert")
        send_slack_alert(log_group, errors)
    else:
        print("No errors found in this batch")
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'processed': len(log_data.get('logEvents', [])),
            'errors_found': len(errors)
        })
    }
