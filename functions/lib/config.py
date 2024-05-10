import os
import boto3
import yaml
import logging
from botocore.exceptions import ClientError
from lib.errors import SensorNotConfiguredError

# cache in lambda runtime
logger = logging.getLogger('config_lib_logger')
logger.setLevel(logging.DEBUG)
CONFIG_CACHE = None
CONFIG_KEY = 'config.yml'


def get_config():
    global CONFIG_CACHE

    if CONFIG_CACHE is not None:
        return CONFIG_CACHE

    S3_BUCKET = os.getenv('BUCKET_NAME')

    if S3_BUCKET is None:
        raise EnvironmentError("S3_BUCKET environment variable is not set.")

    try:
        s3_client = boto3.client('s3')
        response = s3_client.get_object(Bucket=S3_BUCKET, Key=CONFIG_KEY)
        config_data = response['Body'].read()
        CONFIG_CACHE = yaml.safe_load(config_data)
        logger.debug("Configuration loaded and cached.")
    except ClientError as error:
        logger.error(f"Failed to retrieve configuration from S3: {error}")
        raise error

    return CONFIG_CACHE


def get_gps_config(config, sensor_id):
    sensor_type, city, location = sensor_id.split("/")

    if city not in config:
        raise SensorNotConfiguredError(
            f"City '{city}' not found in the configuration")

    city_config = config[city]

    for sensor in city_config:
        if sensor['name'] == location:
            if 'long' not in sensor['location'] or 'lat' not in sensor['location']:
                raise SensorNotConfiguredError(
                    f"Invalid location configuration for {sensor['name']}")
            return sensor['location']

    raise SensorNotConfiguredError(
        f"Location '{location}' not found in city '{city}'.")


def validate_sensor_config(config, sensor_id):
    sensor_type, city, location = sensor_id.split("/")
    city_config = config.get(city)

    if not city_config:
        raise SensorNotConfiguredError(f'Invalid city: {city}')

    location_config = next(
        (item for item in city_config if item['name'] == location), None) if city_config else None
    if not location_config:
        raise SensorNotConfiguredError(f'Invalid location: {location}')

    if location_config and sensor_type not in location_config['sensors']:
        raise SensorNotConfiguredError(f'Invalid sensor_type: {sensor_type}')
