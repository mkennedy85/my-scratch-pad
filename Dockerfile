# Use the latest Python 3.12 slim image for better security
FROM python:3.12-slim

# Set working directory in container
WORKDIR /app

# Update system packages and install security updates
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Upgrade pip and setuptools to latest secure versions
RUN pip install --no-cache-dir --upgrade pip setuptools>=78.1.1

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Initialize the database
RUN python init_db.py

# Create non-root user for security
RUN adduser --disabled-password --gecos '' --no-create-home appuser && \
    chown -R appuser:appuser /app
USER appuser

# Expose port 5001
EXPOSE 5001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5001/ || exit 1

# Run the application
CMD ["python", "app.py"]