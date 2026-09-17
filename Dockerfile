FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY api_server.py .
COPY rider_incentive_schema.sql .
COPY populate_global_incentive_schemes.sql .

RUN mkdir -p /app/logs

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health')" || exit 1

CMD ["python", "api_server.py"]
