FROM python:3.12-slim

WORKDIR /app

# System deps (minimal): none required for pure-python FastAPI stack.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

# Render injects PORT; PRODUCTION disables --reload (see main.py).
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}