import os
import unittest
from unittest.mock import patch, MagicMock
from lib.config import get_config, get_gps_config, validate_sensor_config, SensorNotConfiguredError
import boto3
from botocore.exceptions import ClientError
from lib.config import get_config
import logging


class TestConfigFunctionsFailures(unittest.TestCase):
    def setUp(self):
        self.config = {
            "houston": [
                {"name": "clay_st", "sensors": ["weather", "traffic", "air_quality"],
                 "location": {"lat": 29.742079234296156, "long": -95.34625445767158}},
                {"name": "lyons_ave", "sensors": ["weather", "traffic", "air_quality"],
                 "location": {"lat": 29.77666625781551, "long": -95.31539968940213}}
            ],
            "chicago": [
                {"name": "w_goethe_st", "sensors": ["traffic", "air_quality"],
                 "location": {"lat": 41.90587258379623, "long": -87.63444084296869}},
                {"name": "lyons_ave", "sensors": ["traffic", "air_quality"],
                 "location": {"lat": 41.91300931880483, "long": -87.63843998714738}}
            ]
        }
        self.original_bucket_name = os.getenv('BUCKET_NAME')
        os.environ.pop('BUCKET_NAME', None)

    def tearDown(self):
        if self.original_bucket_name is not None:
            os.environ['BUCKET_NAME'] = self.original_bucket_name
        else:
            os.environ.pop('BUCKET_NAME', None)

    @patch('boto3.client')
    def test_get_config_no_env_var(self, mock_boto3):
        from lib.config import get_config
        with self.assertRaises(EnvironmentError) as context:
            get_config()
        self.assertIn(
            "S3_BUCKET environment variable is not set.", str(context.exception))

    @patch('os.getenv', return_value='test-bucket')
    @patch('boto3.client')
    @patch('logging.Logger.error')
    def test_get_config_s3_client_error(self, mock_logger_error, mock_boto3_client, mock_getenv):
        mock_s3_client = MagicMock()
        mock_boto3_client.return_value = mock_s3_client
        error_msg = "S3 Access Denied"
        mock_s3_client.get_object.side_effect = ClientError(
            {"Error": {"Code": "AccessDenied", "Message": error_msg}}, "GetObject")

        with self.assertRaises(ClientError) as mock_client_error:
            get_config()
        error = mock_client_error.exception
        self.assertEqual(str(
            error), f"An error occurred (AccessDenied) when calling the GetObject operation: {error_msg}")

        # Check that the error was logged
        mock_logger_error.assert_called_once()
        call_args = mock_logger_error.call_args
        self.assertIn(
            "Failed to retrieve configuration from S3:", str(call_args))

    def test_get_gps_config_missing_city(self):
        sensor_id = "weather/chicago/clay_st"
        with self.assertRaises(SensorNotConfiguredError) as context:
            get_gps_config(self.config, sensor_id)
        self.assertIn(
            "Location 'clay_st' not found in city 'chicago", str(context.exception))

    def test_get_gps_config_no_loc(self):
        sensor_id = "weather/houston/no_loc"
        with self.assertRaises(SensorNotConfiguredError) as context:
            get_gps_config(self.config, sensor_id)
        self.assertIn("Location 'no_loc' not found in city 'houston'", str(
            context.exception))

    def test_get_gps_config_invalid_loc(self):
        self.config['houston'].append({"name": "invalid_loc", "sensors": [
                                      "weather"], "location": {"lat": 30}})
        sensor_id = "weather/houston/invalid_loc"
        with self.assertRaises(SensorNotConfiguredError) as context:
            get_gps_config(self.config, sensor_id)
        self.assertIn(
            "Invalid location configuration for invalid_loc", str(context.exception))

    def test_validate_sensor_config_invalid_city(self):
        sensor_id = "weather/invalid_city/clay_st"
        with self.assertRaises(SensorNotConfiguredError) as context:
            validate_sensor_config(self.config, sensor_id)
        self.assertIn('Invalid city: invalid_city', str(context.exception))

    def test_validate_sensor_config_invalid_loc(self):
        sensor_id = "weather/houston/invalid_loc"
        with self.assertRaises(SensorNotConfiguredError) as context:
            validate_sensor_config(self.config, sensor_id)
        self.assertIn('Invalid location: invalid_loc',
                      str(context.exception))

    def test_validate_sensor_config_invalid_sensor_type(self):
        sensor_id = "invalid_sensor_type/houston/clay_st"
        with self.assertRaises(SensorNotConfiguredError) as context:
            validate_sensor_config(self.config, sensor_id)
        self.assertIn('Invalid sensor_type: invalid_sensor_type',
                      str(context.exception))


class TestConfigFunctionsSuccess(unittest.TestCase):
    def setUp(self):
        self.config = {
            "houston": [
                {"name": "clay_st", "sensors": ["weather", "traffic", "air_quality"],
                 "location": {"lat": 29.742079234296156, "long": -95.34625445767158}},
                {"name": "lyons_ave", "sensors": ["weather", "traffic", "air_quality"],
                 "location": {"lat": 29.77666625781551, "long": -95.31539968940213}}
            ],
            "chicago": [
                {"name": "w_goethe_st", "sensors": ["traffic", "air_quality"],
                 "location": {"lat": 41.90587258379623, "long": -87.63444084296869}},
                {"name": "lyons_ave", "sensors": ["traffic", "air_quality"],
                 "location": {"lat": 41.91300931880483, "long": -87.63843998714738}}
            ]
        }

    @patch('lib.config.boto3.client')
    @patch('lib.config.os.getenv', return_value='test-bucket')
    def test_get_config(self, mock_getenv, mock_boto_client):
        mock_s3 = mock_boto_client.return_value
        mock_body = MagicMock()
        mock_body.read.return_value = b'mocked'
        mock_s3.get_object.return_value = {'Body': mock_body}

        with patch('lib.config.yaml.safe_load', return_value=self.config) as mock_yaml_load:
            config = get_config()
            self.assertEqual(config, self.config)
            mock_yaml_load.assert_called_once_with(b'mocked')
            mock_s3.get_object.assert_called_once_with(
                Bucket='test-bucket', Key='config.yml')

    def test_get_gps_config(self):
        sensor_id = "weather/houston/clay_st"
        location = get_gps_config(self.config, sensor_id)
        expected_location = {"lat": 29.742079234296156,
                             "long": -95.34625445767158}
        self.assertEqual(location, expected_location)

    def test_validate_sensor_config(self):
        sensor_id = "weather/houston/clay_st"
        # should not raise an exception
        validate_sensor_config(self.config, sensor_id)


if __name__ == '__main__':
    unittest.main()
