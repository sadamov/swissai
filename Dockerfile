FROM python:3.10-slim

# Install system dependencies (for CMIP6 splitting)
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    proj-bin \
    libproj-dev \
    libgeos-dev \
    cdo \
    libgomp1 \
    bc \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies (for verification and plotting)
COPY requirements.txt .
RUN pip install -r requirements.txt