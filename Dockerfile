FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY src/ .

EXPOSE 8000

CMD uvicorn app.main:app --host ${HOST:-0.0.0.0} --port ${PORT:-8000}
