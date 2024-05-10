FROM public.ecr.aws/lambda/python:3.12-arm64

WORKDIR ${LAMBDA_TASK_ROOT}

# copy global requirements.txt
COPY functions/requirements.txt .

RUN pip install -r requirements.txt

COPY functions/ingest_handler/handler.py .

COPY functions/lib ./lib

CMD ["handler.main"]
