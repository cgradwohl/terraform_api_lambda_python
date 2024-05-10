import os
import json
import boto3
import logging
from botocore.exceptions import ClientError
from lib.errors import BadRequestError, SensorNotFoundError

# cache in lambda runtime
logger = logging.getLogger('sensors_lib_logger')
logger.setLevel(logging.DEBUG)


def put_sensor_record(key, record):
    S3_BUCKET = os.getenv('BUCKET_NAME')

    if S3_BUCKET is None:
        raise EnvironmentError("S3_BUCKET environment variable is not set.")

    try:
        s3_client = boto3.client('s3')
        s3_client.put_object(Body=json.dumps(
            record, indent=4), Bucket=S3_BUCKET, Key=key)
    except ClientError as error:
        logger.error(f"Failed to write sensor record to S3: {error}")
        raise error


def get_latest_sensor_record(sensor_id):
    S3_BUCKET = os.getenv('BUCKET_NAME')

    if S3_BUCKET is None:
        raise EnvironmentError("S3_BUCKET environment variable is not set.")

    try:
        s3_client = boto3.client('s3')
        response = s3_client.list_objects_v2(
            Bucket=S3_BUCKET, Prefix=sensor_id)

        if 'Contents' not in response:
            raise SensorNotFoundError(
                "No records found for this sensor.")

        latest_record = max(response['Contents'],
                            key=lambda x: x['LastModified'])
        latest_key = latest_record['Key']

        data = s3_client.get_object(Bucket=S3_BUCKET, Key=latest_key)

        record = data['Body'].read().decode('utf-8')
        record_json = json.loads(record)

        return record_json

    except (SensorNotFoundError, ClientError) as error:
        logger.error(f"Failed to write sensor record to S3: {error}")
        raise error


def validate_sensor_payload(event):
    body_str = event.get('body')
    if not body_str:
        raise BadRequestError("Request body is invalid or missing")

    try:
        body = json.loads(body_str)
    except json.JSONDecodeError:
        raise BadRequestError("Request body is not valid JSON")

    payload = body.get('payload')
    if not payload:
        raise BadRequestError('Request body `payload` cannot be empty')

    return payload
