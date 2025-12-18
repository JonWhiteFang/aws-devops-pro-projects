import json
import os
import logging

logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

def handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")
    
    path = event.get('path', '/')
    method = event.get('httpMethod', 'GET')
    
    if path == '/health':
        return {
            'statusCode': 200,
            'body': json.dumps({'status': 'healthy', 'version': '1.0.0'})
        }
    
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({
            'message': 'Hello from Lambda!',
            'path': path,
            'method': method
        })
    }
