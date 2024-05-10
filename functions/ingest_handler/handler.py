from lib.http import response
from lib.sensors import put_sensor_record, validate_sensor_payload
from lib.config import get_config, validate_sensor_config, get_gps_config
from lib.errors import SensorNotConfiguredError, BadRequestError
from lib.config import get_config
from datetime import datetime, timezone
from botocore.exceptions import ClientError
import logging

# cache in lambda runtime
logger = logging.getLogger('ingest_handler_logger')
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
        payload = validate_sensor_payload(event)

        timestamp = datetime.now(timezone.utc).isoformat()
        gps_config = get_gps_config(config, sensor_id)

        sensor_record_key = f"{sensor_id}/{timestamp}.json"
        sensor_record = {
            "timestamp": timestamp,
            "payload": payload,
            "location": {
                "long": gps_config.get('long', 'Unknown'),
                "lat": gps_config.get('lat', 'Unknown')
            }
        }
        put_sensor_record(sensor_record_key, sensor_record)

        return response(200, data={'timestamp': timestamp})
    # 4xx's
    except BadRequestError as bad_request:
        return response(400, error=bad_request)
    except SensorNotConfiguredError as not_authorized:
        # NOTE: returning a 401 as requested by exercise prompt (other option would be 400)
        return response(401, error=not_authorized)
    # 5xx's
    except (EnvironmentError, ClientError, Exception) as intertnal_error:
        logger.error(f"An unexpected error occurred: {str(intertnal_error)}")
        return response(500, error='An unexpected error occurred')
