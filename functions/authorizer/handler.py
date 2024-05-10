import boto3
import os
import logging
from botocore.exceptions import ClientError

# cache in lambda runtime
logger = logging.getLogger('authorizer_logger')
logger.setLevel(logging.DEBUG)
ssm_client = boto3.client('ssm')
API_KEY_PARAM_NAME = os.getenv('API_KEY_PARAM_NAME')


def main(event, context):
    if API_KEY_PARAM_NAME is None:
        raise EnvironmentError(
            "API_KEY_PARAM_NAME environment variable is not set.")

    try:
        token = event['authorizationToken'] if 'authorizationToken' in event else None
        method_arn = event['methodArn']

        parameter = ssm_client.get_parameter(
            Name=API_KEY_PARAM_NAME, WithDecryption=True)
        stored_api_key = parameter['Parameter']['Value']

        logger.debug("methodarn")
        logger.debug(modify_arn(method_arn))

        if token == stored_api_key:
            return generate_policy('user', 'Allow', modify_arn(method_arn))
        else:
            return generate_policy('user', 'Deny', method_arn)
    except ClientError as error:
        logger.error(f"Failed to write read parameter from SSM: {error}")
        raise error


def generate_policy(principal_id, effect, resource_arn):
    policy_document = {
        'Version': '2012-10-17',
        'Statement': [{
            'Action': 'execute-api:Invoke',
            'Effect': effect,
            'Resource': resource_arn
        }]
    }
    return {
        'principalId': principal_id,
        'policyDocument': policy_document
    }


def modify_arn(method_arn):
    parts = method_arn.split(':')
    api_gateway_arn = parts[5].split('/')
    # allow access to all methods and paths under the stage
    modified_api_gateway_arn = '/'.join(api_gateway_arn[:2]) + '/*'
    return ':'.join(parts[:5] + [modified_api_gateway_arn])
