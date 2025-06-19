# Hunyuan3D API

A FastAPI-based web service for generating 3D models from images using Hunyuan3D-2.

## Features

- 🖼️ Convert images to 3D models using Hunyuan3D-2
- 🌐 RESTful API with FastAPI
- 🔗 Ngrok integration for public access
- 🐳 Docker support
- 📱 CORS enabled for web applications
- 🗂️ Automatic file cleanup
- 📊 Health monitoring endpoints

## Quick Start

### Option 1: Automatic Installation (Recommended)

```bash
# Download and run the installation script
curl -sSL https://raw.githubusercontent.com/your-repo/hunyuan3d-api/main/install.sh | bash

# Copy the Python files to the project directory
cd ~/hunyuan3d-api

# Copy all .py files here: main.py, model_manager.py, utils.py, ngrok_server.py

# Set your ngrok token
export NGROK_AUTH_TOKEN="your_token_here"

# Run with ngrok tunnel
./run.sh ngrok
```

### Option 2: Docker (Easiest)

```bash
# Clone or create project directory
mkdir hunyuan3d-api && cd hunyuan3d-api

# Copy all files (Dockerfile, docker-compose.yml, requirements.txt, .py files)

# Set environment variables
cp .env.example .env
# Edit .env and add your NGROK_AUTH_TOKEN

# Build and run
docker-compose up --build
```

### Option 3: Manual Installation

```bash
# Install system dependencies (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y git curl build-essential python3-dev libgl1-mesa-glx

# Install ngrok
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
  | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
  && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
  | sudo tee /etc/apt/sources.list.d/ngrok.list \
  && sudo apt update \
  && sudo apt install ngrok

# Clone required repositories
git clone https://github.com/Tencent/Hunyuan3D-2.git
git clone https://github.com/kijai/ComfyUI-Hunyuan3DWrapper.git

# Install Python dependencies
pip install -r requirements.txt
pip install -r ComfyUI-Hunyuan3DWrapper/requirements.txt

# Build custom rasterizer
cd ComfyUI-Hunyuan3DWrapper/hy3dgen/texgen/custom_rasterizer/
python setup.py bdist_wheel
pip install dist/custom_rasterizer*.whl

# Install Hunyuan3D-2
cd ../../../Hunyuan3D-2
python setup.py install

# Run the API
python main.py
```

## Configuration

### Environment Variables

Create a `.env` file based on `.env.example`:

```bash
NGROK_AUTH_TOKEN=your_token_here
HOST=0.0.0.0
PORT=8000
TEMP_DIR=/tmp/temp_3d
LOG_LEVEL=INFO
```

### Ngrok Setup

1. Sign up at [ngrok.com](https://ngrok.com)
2. Get your auth token from [dashboard](https://dashboard.ngrok.com/get-started/your-authtoken)
3. Set the token:
   ```bash
   export NGROK_AUTH_TOKEN="your_token_here"
   # or add it to your .env file
   ```

## API Usage

### Endpoints

- `GET /` - API status and information
- `GET /health` - Detailed health check
- `POST /generate-3d` - Generate 3D model from image

### Example Usage

#### Using curl
```bash
curl -X POST "http://your-api-url/generate-3d" \
     -H "accept: model/gltf-binary" \
     -H "Content-Type: multipart/form-data" \
     -F "image=@your_image.jpg" \
     --output model.glb
```

#### Using Python
```python
import requests

url = "http://your-api-url/generate-3d"
files = {"image": ("image.jpg", open("image.jpg", "rb"), "image/jpeg")}

response = requests.post(url, files=files)
if response.status_code == 200:
    with open("model.glb", "wb") as f:
        f.write(response.content)
    print("Model saved as model.glb")
```

#### Using JavaScript/Fetch
```javascript
const formData = new FormData();
formData.append('image', fileInput.files[0]);

fetch('/generate-3d', {
    method: 'POST',
    body: formData
})
.then(response => response.blob())
.then(blob => {
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'model.glb';
    a.click();
});
```

## File Structure

```
hunyuan3d-api/
├── main.py                 # Main FastAPI application
├── model_manager.py        # Model loading and management
├── utils.py               # Utility functions
├── ngrok_server.py        # Ngrok integration
├── requirements.txt       # Python dependencies
├── Dockerfile            # Docker configuration
├── docker-compose.yml    # Docker Compose setup
├── install.sh           # Installation script
├── .env.example         # Environment configuration template
├── README.md            # This file
└── temp_data/           # Temporary files directory
```

## API Documentation

Once the server is running, visit:
- `http://your-url/docs` - Interactive API documentation (Swagger UI)
- `http://your-url/redoc` - Alternative API documentation

## Supported Image Formats

- JPEG (.jpg, .jpeg)
- PNG (.png)
- WebP (.webp)
- BMP (.bmp)

**File Limitations:**
- Maximum file size: 10MB
- Recommended resolution: 512x512 to 1024x1024

## Troubleshooting

### Common Issues

1. **Pipeline loading fails**
   ```bash
   # Check if all dependencies are installed
   pip install hy3dgen --upgrade
   
   # Verify CUDA availability
   python -c "import torch; print(torch.cuda.is_available())"
   ```

2. **Ngrok connection fails**
   ```bash
   # Check if auth token is set
   echo $NGROK_AUTH_TOKEN
   
   # Test ngrok manually
   ngrok http 8000
   ```

3. **Docker build fails**
   ```bash
   # Clean Docker cache
   docker system prune -a
   
   # Rebuild with no cache
   docker-compose build --no-cache
   ```

4. **Out of memory errors**
   - Reduce image resolution
   - Close other applications
   - Use smaller batch sizes

### Logs

Check logs for debugging:
```bash
# Docker logs
docker-compose logs -f

# Local logs
tail -f logs/app.log
```

## Development

### Running in Development Mode

```bash
# Install development dependencies
pip install -r requirements.txt

# Run with auto-reload
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Running Tests

```bash
# Install test dependencies
pip install pytest pytest-asyncio httpx

# Run tests
pytest tests/
```

## Performance Considerations

- **GPU recommended** for faster inference
- **RAM**: At least 8GB recommended
- **Storage**: ~5GB for model weights and dependencies
- **Network**: Stable internet for model downloads

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Support

- 📧 Email: your-email@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/your-repo/hunyuan3d-api/issues)
- 📖 Documentation: [Wiki](https://github.com/your-repo/hunyuan3d-api/wiki)

## Acknowledgments

- [Hunyuan3D-2](https://github.com/Tencent/Hunyuan3D-2) by Tencent
- [ComfyUI-Hunyuan3DWrapper](https://github.com/kijai/ComfyUI-Hunyuan3DWrapper) by kijai
- [FastAPI](https://fastapi.tiangolo.com/) for the web framework
- [ngrok](https://ngrok.com/) for tunneling