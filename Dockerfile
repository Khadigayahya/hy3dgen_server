# Use official Python runtime as base image
FROM python:3.9-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    python3-dev \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Install ngrok
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
    | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
    && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
    | tee /etc/apt/sources.list.d/ngrok.list \
    && apt-get update \
    && apt-get install -y ngrok \
    && rm -rf /var/lib/apt/lists/*

# Clone required repositories
RUN git clone https://github.com/Tencent/Hunyuan3D-2.git /tmp/Hunyuan3D-2
RUN git clone https://github.com/kijai/ComfyUI-Hunyuan3DWrapper.git /tmp/ComfyUI-Hunyuan3DWrapper

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install additional requirements from ComfyUI-Hunyuan3DWrapper
RUN pip install --no-cache-dir -r /tmp/ComfyUI-Hunyuan3DWrapper/requirements.txt

# Build and install custom rasterizer
WORKDIR /tmp/ComfyUI-Hunyuan3DWrapper/hy3dgen/texgen/custom_rasterizer/
RUN python setup.py bdist_wheel
RUN pip install dist/custom_rasterizer*.whl

# Install Hunyuan3D-2
WORKDIR /tmp/Hunyuan3D-2
RUN python setup.py install

# Go back to app directory
WORKDIR /app

# Copy application code
COPY . .

# Create temp directory
RUN mkdir -p /tmp/temp_3d

# Set environment variables
ENV TEMP_DIR=/tmp/temp_3d
ENV HOST=0.0.0.0
ENV PORT=8000

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Command to run the application
CMD ["python", "main.py"]