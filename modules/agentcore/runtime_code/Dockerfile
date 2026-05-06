FROM public.ecr.aws/docker/library/python:3.11-slim

WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

ARG AWS_DEFAULT_REGION=us-east-1
ENV AWS_REGION=$AWS_DEFAULT_REGION
ENV AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION

RUN useradd -m -u 1000 bedrock_agentcore
USER bedrock_agentcore

EXPOSE 8080
EXPOSE 8000

COPY main.py memory_hook_provider.py ./

CMD ["opentelemetry-instrument", "python", "main.py"]
