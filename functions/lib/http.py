import json


def response(status_code, error=None, data=None):
    body_dict = {}

    if 400 <= status_code < 600:
        body_dict = {'message': "FAILURE"}
        if error is not None:
            body_dict['error'] = str(error)
        return {'statusCode': status_code, 'body': json.dumps(body_dict)}

    if status_code == 200:
        if data is not None:
            body_dict = data
        return {'statusCode': status_code, 'body': json.dumps(body_dict)}
