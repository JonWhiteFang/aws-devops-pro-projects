import json, boto3

def evaluate_compliance(resource_tags, required=('Owner','Environment')):
    keys = set([t['key'] if isinstance(t, dict) else t['Key'] for t in resource_tags])
    return all(k in keys for k in required)

def lambda_handler(event, context):
    invoking_event = json.loads(event['invokingEvent'])
    configuration_item = invoking_event.get('configurationItem', {})
    resource_type = configuration_item.get('resourceType')
    resource_id = configuration_item.get('resourceId')
    tags = configuration_item.get('configuration', {}).get('tags', [])
    tag_list = tags if isinstance(tags, list) else [{'Key':k,'Value':v} for k,v in tags.items()]

    compliant = evaluate_compliance(tag_list)

    result_token = event['resultToken']
    config = boto3.client('config')
    compliance_type = 'COMPLIANT' if compliant else 'NON_COMPLIANT'
    config.put_evaluations(
        Evaluations=[{
            'ComplianceResourceType': resource_type,
            'ComplianceResourceId': resource_id,
            'ComplianceType': compliance_type,
            'OrderingTimestamp': configuration_item.get('configurationItemCaptureTime')
        }],
        ResultToken=result_token
    )
    return {'status':'ok','compliant':compliant}
