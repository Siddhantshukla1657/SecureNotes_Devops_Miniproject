# REMEDIATION #3: Hardened, minimal base image (python:3.12-slim) with security updates
FROM python:3.12-slim

WORKDIR /app

# Apply latest security patches to base OS packages
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source
COPY . .

# Expose port
EXPOSE 5000

# Run with Gunicorn WSGI server
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
