FROM python:3.10-slim

# Install system dependencies including OpenMP
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    proj-bin \
    libproj-dev \
    libgeos-dev \
    cdo \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt