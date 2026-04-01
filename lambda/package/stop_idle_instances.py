import json
import boto3
import os
from datetime import datetime, timedelta
import urllib3

ec2 = boto3.client('ec2')
cloudwatch = boto3.client('cloudwatch')

SLACK_WEBHOOK_URL = os.environ['SLACK_WEBHOOK_URL']
CPU_THRESHOLD = float(os.environ.get('CPU_THRESHOLD', '5.0'))  # 5% default

http = urllib3.PoolManager()

def send_slack_notification(message):
    """Send notification to Slack"""
    msg = {
        "text": message,
        "username": "Cloud Guardian Bot",
        "icon_emoji": ":robot_face:"
    }
    
    encoded_msg = json.dumps(msg).encode('utf-8')
    resp = http.request('POST', SLACK_WEBHOOK_URL, body=encoded_msg)
    print(f"Slack response: {resp.status}")

def get_cpu_utilization(instance_id):
    """Get average CPU utilization for the last hour"""
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(hours=1)
    
    response = cloudwatch.get_metric_statistics(
        Namespace='AWS/EC2',
        MetricName='CPUUtilization',
        Dimensions=[{'Name': 'InstanceId', 'Value': instance_id}],
        StartTime=start_time,
        EndTime=end_time,
        Period=3600,  # 1 hour
        Statistics=['Average']
    )
    
    if response['Datapoints']:
        return response['Datapoints'][0]['Average']
    return None

def lambda_handler(event, context):
    """Main Lambda handler"""
    
    # Get all running instances with our tag
    response = ec2.describe_instances(
        Filters=[
            {'Name': 'instance-state-name', 'Values': ['running']},
            {'Name': 'tag:Name', 'Values': ['cloud-guardian-app']}
        ]
    )
    
    stopped_instances = []
    
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            instance_name = next(
                (tag['Value'] for tag in instance.get('Tags', []) if tag['Key'] == 'Name'),
                instance_id
            )
            
            # Get CPU metrics
            cpu_avg = get_cpu_utilization(instance_id)
            
            if cpu_avg is not None:
                print(f"Instance {instance_name} ({instance_id}): CPU = {cpu_avg:.2f}%")
                
                if cpu_avg < CPU_THRESHOLD:
                    # Stop the instance
                    print(f"Stopping idle instance: {instance_name}")
                    ec2.stop_instances(InstanceIds=[instance_id])
                    
                    # Calculate cost savings (rough estimate)
                    # t2.micro = $0.0116/hour, assume 24hr savings
                    estimated_savings = 0.0116 * 24
                    
                    message = f"""
🛑 *Cloud Guardian Alert*
*Action:* Stopped idle EC2 instance
*Instance:* {instance_name} ({instance_id})
*Reason:* CPU < {CPU_THRESHOLD}% (Avg: {cpu_avg:.2f}%)
*Estimated Daily Savings:* ${estimated_savings:.2f}
*Timestamp:* {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}
                    """.strip()
                    
                    send_slack_notification(message)
                    stopped_instances.append(instance_id)
            else:
                print(f"No CPU metrics available for {instance_name}")
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': f'Processed instances, stopped {len(stopped_instances)}',
            'stopped_instances': stopped_instances
        })
    }
