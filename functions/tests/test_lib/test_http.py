import unittest
import json
from lib.http import response


class TestResponseFunction(unittest.TestCase):

    def test_response_success_with_data(self):
        """Test response with success status code and data."""
        data = {"foo": "bar"}
        result = response(200, data=data)
        expected_body = json.dumps(data)
        self.assertEqual(result, {'statusCode': 200, 'body': expected_body})

    def test_response_success_without_data(self):
        """Test response with success status code and no data."""
        result = response(200)
        expected_body = json.dumps({})
        self.assertEqual(result, {'statusCode': 200, 'body': expected_body})

    def test_response_failure_with_error(self):
        """Test response with failure status code and error message."""
        error = "foo"
        result = response(400, error=error)
        expected_body = json.dumps({"message": "FAILURE", "error": error})
        self.assertEqual(result, {'statusCode': 400, 'body': expected_body})

    def test_response_failure_without_error(self):
        """Test response with failure status code and no error message"""
        result = response(400)
        expected_body = json.dumps({"message": "FAILURE"})
        self.assertEqual(result, {'statusCode': 400, 'body': expected_body})


if __name__ == '__main__':
    unittest.main()
