#!/bin/bash

# Hunyuan3D API Installation Script
# This script installs all dependencies and sets up the Hunyuan3D API

set -e  # Exit on any error

echo "🚀 Starting Hunyuan3D API Installation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Python 3.8+ is installed
check_python() {
    print_status "Checking Python version..."
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
        PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
        PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
        
        if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 8 ]; then
            print_success "Python $PYTHON_VERSION found"
        else
            print_error "Python 3.8+ required, found $PYTHON_VERSION"
            exit 1
        fi
    else
        print_error "Python 3 not found. Please install Python 3.8+"
        exit 1
    fi
}

# Check if pip is installed
check_pip() {
    print_status "Checking pip..."
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 not found. Installing pip..."
        python3 -m ensurepip --upgrade
    fi
    print_success "pip found"
}

# Install system dependencies
install_system_deps() {
    print_status "Installing system dependencies..."
    
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        sudo apt-get update
        sudo apt-get install -y \
            git \
            curl \
            build-essential \
            python3-dev \
            libgl1-mesa-glx \
            libglib2.0-0 \
            libsm6 \
            libxext6 \
            libxrender-dev \
            libgomp1
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        sudo yum update -y
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y \
            git \
            curl \
            python3-devel \
            mesa-libGL \
            glib2 \
            libSM \
            libXext \
            libXrender \
            libgomp
    elif command -v brew &> /dev/null; then
        # macOS
        brew install git curl
    else
        print_warning "Unknown package manager. Please install git, curl, and build tools manually."
    fi
    
    print_success "System dependencies installed"
}

# Install ngrok
install_ngrok() {
    print_status "Installing ngrok..."
    
    if command -v ngrok &> /dev/null; then
        print_success "ngrok already installed"
        return
    fi
    
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
            | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
            && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
            | sudo tee /etc/apt/sources.list.d/ngrok.list \
            && sudo apt-get update \
            && sudo apt-get install -y ngrok
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        curl -s https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -o ngrok.zip
        unzip ngrok.zip
        sudo mv ngrok /usr/local/bin/
        rm ngrok.zip
    elif command -v brew &> /dev/null; then
        # macOS
        brew install ngrok/ngrok/ngrok
    else
        # Manual installation
        print_status "Installing ngrok manually..."
        curl -s https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -o ngrok.zip
        unzip ngrok.zip
        sudo mv ngrok /usr/local/bin/
        rm ngrok.zip
    fi
    
    print_success "ngrok installed"
}

# Clone repositories
clone_repos() {
    print_status "Cloning required repositories..."
    
    # Create temp directory for cloning
    mkdir -p /tmp/hunyuan3d_install
    cd /tmp/hunyuan3d_install
    
    # Clone Hunyuan3D-2
    if [ ! -d "Hunyuan3D-2" ]; then
        git clone https://github.com/Tencent/Hunyuan3D-2.git
    fi
    
    # Clone ComfyUI-Hunyuan3DWrapper
    if [ ! -d "ComfyUI-Hunyuan3DWrapper" ]; then
        git clone https://github.com/kijai/ComfyUI-Hunyuan3DWrapper.git
    fi
    
    print_success "Repositories cloned"
}

# Install Python dependencies
install_python_deps() {
    print_status "Installing Python dependencies..."
    
    # Install basic requirements
    pip3 install --upgrade pip
    pip3 install hy3dgen
    pip3 install --upgrade huggingface_hub
    pip3 install fastapi uvicorn aiofiles pyngrok python-multipart
    pip3 install trimesh torch torchvision
    pip3 install gradio nest-asyncio
    
    # Install ComfyUI-Hunyuan3DWrapper requirements
    if [ -f "/tmp/hunyuan3d_install/ComfyUI-Hunyuan3DWrapper/requirements.txt" ]; then
        pip3 install -r /tmp/hunyuan3d_install/ComfyUI-Hunyuan3DWrapper/requirements.txt
    fi
    
    print_success "Python dependencies installed"
}

# Build custom rasterizer
build_custom_rasterizer() {
    print_status "Building custom rasterizer..."
    
    cd /tmp/hunyuan3d_install/ComfyUI-Hunyuan3DWrapper/hy3dgen/texgen/custom_rasterizer/
    python3 setup.py bdist_wheel
    pip3 install dist/custom_rasterizer*.whl
    
    print_success "Custom rasterizer built and installed"
}

# Install Hunyuan3D-2
install_hunyuan3d() {
    print_status "Installing Hunyuan3D-2..."
    
    cd /tmp/hunyuan3d_install/Hunyuan3D-2
    python3 setup.py install
    
    print_success "Hunyuan3D-2 installed"
}

# Create project structure
setup_project() {
    print_status "Setting up project structure..."
    
    # Create project directory
    PROJECT_DIR="$HOME/hunyuan3d-api"
    mkdir -p "$PROJECT_DIR"
    mkdir -p "$PROJECT_DIR/temp_data"
    mkdir -p "$PROJECT_DIR/logs"
    
    print_success "Project structure created at $PROJECT_DIR"
    echo "Project directory: $PROJECT_DIR"
}

# Cleanup
cleanup() {
    print_status "Cleaning up temporary files..."
    rm -rf /tmp/hunyuan3d_install
    print_success "Cleanup completed"
}

# Create run script
create_run_script() {
    print_status "Creating run script..."
    
    PROJECT_DIR="$HOME/hunyuan3d-api"
    
    cat > "$PROJECT_DIR/run.sh" << 'EOF'
#!/bin/bash

# Hunyuan3D API Run Script

echo "🚀 Starting Hunyuan3D API..."

# Set environment variables
export TEMP_DIR="$(pwd)/temp_data"
export HOST="0.0.0.0"
export PORT="8000"

# Check if ngrok auth token is set
if [ -z "$NGROK_AUTH_TOKEN" ]; then
    echo "⚠️  NGROK_AUTH_TOKEN not set. Please set it with:"
    echo "export NGROK_AUTH_TOKEN='your_token_here'"
    echo "You can get a token from https://dashboard.ngrok.com/get-started/your-authtoken"
fi

# Run the API
if [ "$1" = "ngrok" ]; then
    echo "Running with ngrok tunnel..."
    python3 ngrok_server.py
else
    echo "Running without ngrok (local only)..."
    python3 main.py
fi
EOF

    chmod +x "$PROJECT_DIR/run.sh"
    print_success "Run script created"
}

# Main installation function
main() {
    print_status "Starting installation process..."
    
    check_python
    check_pip
    install_system_deps
    install_ngrok
    clone_repos
    install_python_deps
    build_custom_rasterizer
    install_hunyuan3d
    setup_project
    create_run_script
    cleanup
    
    print_success "Installation completed successfully! 🎉"
    echo ""
    echo "📋 Next steps:"
    echo "1. Copy the Python files (main.py, model_manager.py, utils.py, ngrok_server.py) to $HOME/hunyuan3d-api/"
    echo "2. Set your ngrok auth token: export NGROK_AUTH_TOKEN='your_token'"
    echo "3. Run the API:"
    echo "   cd $HOME/hunyuan3d-api"
    echo "   ./run.sh ngrok    # With ngrok tunnel"
    echo "   ./run.sh          # Local only"
    echo ""
    echo "🌐 Get your ngrok token from: https://dashboard.ngrok.com/get-started/your-authtoken"
}

# Run main function
main "$@"