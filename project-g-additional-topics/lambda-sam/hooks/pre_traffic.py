import boto3
import json

codedeploy = boto3.client('codedeploy')
lambda_client = boto3.client('lambda')

def handler(event, context):
    deployment_id = event['DeploymentId']
    lifecycle_event_hook_execution_id = event['LifecycleEventHookExecutionId']
    
    try:
        # Get the new function version
        function_name = event.get('FunctionName', 'api-handler-prod')
        
        # Invoke the new version with a test payload
        response = lambda_client.invoke(
            FunctionName=function_name,
            InvocationType='RequestResponse',
            Payload=json.dumps({
                'path': '/health',
                'httpMethod': 'GET'
            })
        )
        
        payload = json.loads(response['Payload'].read())
        
        if payload.get('statusCode') == 200:
            status = 'Succeeded'
        else:
            status = 'Failed'
            
    except Exception as e:
        print(f"Pre-traffic validation failed: {e}")
        status = 'Failed'
    
    codedeploy.put_lifecycle_event_hook_execution_status(
        deploymentId=deployment_id,
        lifecycleEventHookExecutionId=lifecycle_event_hook_execution_id,
        status=status
    )
    
    return {'status': status}
