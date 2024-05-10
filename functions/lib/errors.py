class SensorNotConfiguredError(Exception):
    def __init__(self, message="Sensor configuration error"):
        self.message = message
        super().__init__(self.message)


class SensorNotFoundError(Exception):
    def __init__(self, message="Sensor not found error"):
        self.message = message
        super().__init__(self.message)


class BadRequestError(Exception):
    def __init__(self, message="Bad request error"):
        self.message = message
        super().__init__(self.message)
