#!/bin/bash

# Hunyuan3D API Run Script

echo "🚀 Starting Hunyuan3D API..."

# Set environment variables
export TEMP_DIR="$(pwd)/temp_data"
export HOST="0.0.0.0"
export PORT="8000"

# Create temp directory if it doesn't exist
mkdir -p "$TEMP_DIR"

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    export $(cat .env | grep -v '^#' | xargs)
fi

# Check if ngrok auth token is set
if [ -z "$NGROK_AUTH_TOKEN" ]; then
    echo "⚠️  NGROK_AUTH_TOKEN not set. Please set it with:"
    echo "export NGROK_AUTH_TOKEN='your_token_here'"
    echo "You can get a token from https://dashboard.ngrok.com/get-started/your-authtoken"
    echo ""
fi

# Function to check if required files exist
check_files() {
    required_files=("main.py" "model_manager.py" "utils.py" "ngrok_server.py")
    missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -ne 0 ]; then
        echo "❌ Missing required files:"
        printf '%s\n' "${missing_files[@]}"
        echo ""
        echo "Please make sure all Python files are in the current directory."
        exit 1
    fi
}

# Function to check Python dependencies
check_dependencies() {
    echo "Checking Python dependencies..."
    
    required_packages=("fastapi" "uvicorn" "torch" "trimesh" "hy3dgen")
    missing_packages=()
    
    for package in "${required_packages[@]}"; do
        if ! python3 -c "import $package" 2>/dev/null; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -ne 0 ]; then
        echo "❌ Missing Python packages:"
        printf '%s\n' "${missing_packages[@]}"
        echo ""
        echo "Please install missing packages:"
        echo "pip install ${missing_packages[*]}"
        exit 1
    fi
    
    echo "✅ All dependencies are installed"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  ngrok          Run with ngrok tunnel (public access)"
    echo "  local          Run locally only (default)"
    echo "  check          Check dependencies and configuration"
    echo "  --help, -h     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 ngrok       # Run with public ngrok tunnel"
    echo "  $0 local       # Run locally on http://localhost:8000"
    echo "  $0 check       # Check if everything is properly configured"
}

# Parse command line arguments
case "${1:-local}" in
    "ngrok")
        MODE="ngrok"
        ;;
    "local")
        MODE="local"
        ;;
    "check")
        echo "🔍 Checking configuration..."
        check_files
        check_dependencies
        echo "✅ Configuration check completed successfully!"
        exit 0
        ;;
    "--help"|"-h")
        show_usage
        exit 0
        ;;
    *)
        echo "❌ Unknown option: $1"
        show_usage
        exit 1
        ;;
esac

# Check files and dependencies
check_files
check_dependencies

# Run the API based on mode
if [ "$MODE" = "ngrok" ]; then
    if [ -z "$NGROK_AUTH_TOKEN" ]; then
        echo "❌ NGROK_AUTH_TOKEN is required for ngrok mode"
        echo "Set it with: export NGROK_AUTH_TOKEN='your_token'"
        exit 1
    fi
    
    echo "🌐 Running with ngrok tunnel..."
    echo "This will make your API publicly accessible"
    python3 ngrok_server.py
else
    echo "🏠 Running locally..."
    echo "API will be available at: http://localhost:$PORT"
    echo "API docs at: http://localhost:$PORT/docs"
    python3 main.py
fi
