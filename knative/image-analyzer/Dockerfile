# ═══════════════════════════════════════════════════════════════
# CloudField Image Analyzer – Knative Serverless Function
# Docker Hub: tsilian9/cloudfield-image-analyzer:latest
# ═══════════════════════════════════════════════════════════════
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY app.py .

# Knative uses PORT env variable
ENV PORT=8080

EXPOSE 8080

CMD ["python", "app.py"]
