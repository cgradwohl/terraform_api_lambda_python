import unittest

from lib.errors import SensorNotConfiguredError, SensorNotFoundError, BadRequestError


class TestExceptionMessages(unittest.TestCase):
    def test_sensor_not_configured_error(self):
        """Test SensorNotConfiguredError raises with default message."""
        with self.assertRaises(SensorNotConfiguredError) as context:
            raise SensorNotConfiguredError()
        self.assertEqual(str(context.exception), "Sensor configuration error")

    def test_sensor_not_found_error(self):
        """Test SensorNotFoundError raises with default message."""
        with self.assertRaises(SensorNotFoundError) as context:
            raise SensorNotFoundError()
        self.assertEqual(str(context.exception), "Sensor not found error")

    def test_bad_request_error(self):
        """Test BadRequestError raises with default message."""
        with self.assertRaises(BadRequestError) as context:
            raise BadRequestError()
        self.assertEqual(str(context.exception), "Bad request error")

    def test_custom_message_sensor_not_configured_error(self):
        """Test SensorNotConfiguredError raises with custom message."""
        custom_message = "foo"
        with self.assertRaises(SensorNotConfiguredError) as context:
            raise SensorNotConfiguredError(message=custom_message)
        self.assertEqual(str(context.exception), custom_message)

    def test_custom_message_sensor_not_found_error(self):
        """Test SensorNotFoundError raises with custom message."""
        custom_message = "foo"
        with self.assertRaises(SensorNotFoundError) as context:
            raise SensorNotFoundError(message=custom_message)
        self.assertEqual(str(context.exception), custom_message)

    def test_custom_message_bad_request_error(self):
        """Test BadRequestError raises with custom message."""
        custom_message = "foo"
        with self.assertRaises(BadRequestError) as context:
            raise BadRequestError(message=custom_message)
        self.assertEqual(str(context.exception), custom_message)


if __name__ == '__main__':
    unittest.main()
