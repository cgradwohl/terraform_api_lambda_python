from lib.config import get_config, validate_sensor_config, get_gps_config
from lib.sensors import get_latest_sensor_record
from lib.errors import SensorNotConfiguredError, SensorNotFoundError
from lib.http import response
from botocore.exceptions import ClientError
import logging

# cache in lambda runtime
logger = logging.getLogger('get_handler_logger')
logger.setLevel(logging.DEBUG)


def main(event, context):
    try:
        config = get_config()

        path_parameters = event['pathParameters']
        sensor_type = path_parameters['sensor_type']
        city = path_parameters['city']
        location = path_parameters['location']

        sensor_id = f"{sensor_type}/{city}/{location}"

        validate_sensor_config(config, sensor_id)

        record = get_latest_sensor_record(sensor_id)

        return response(200, data=record)
    # 4xx's
    except SensorNotConfiguredError as not_authorized:
        # NOTE: returning a 401 as requested by exercise prompt (other option would be 400)
        return response(401, error=not_authorized)
    except SensorNotFoundError as not_found:
        return response(404, not_found)
    # 5xx's
    except (EnvironmentError, ClientError, Exception) as intertnal_error:
        logger.error(f"An unexpected error occurred: {str(intertnal_error)}")
        return response(500, error='An unexpected error occurred')
