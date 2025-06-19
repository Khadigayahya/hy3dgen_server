# Hunyuan3D API Makefile

.PHONY: help install run-local run-ngrok docker-build docker-run clean test

# Variables
PYTHON := python3
PIP := pip3
PROJECT_NAME := hunyuan3d-api
DOCKER_IMAGE := $(PROJECT_NAME):latest

# Default target
help:
	@echo "🚀 Hunyuan3D API Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  install      - Install all dependencies"
	@echo "  run-local    - Run API locally"
	@echo "  run-ngrok    - Run API with ngrok tunnel"
	@echo "  docker-build - Build Docker image"
	@echo "  docker-run   - Run with Docker Compose"
	@echo "  clean        - Clean temporary files"
	@echo "  test         - Run tests"
	@echo "  setup-env    - Setup environment file"
	@echo "  check        - Check dependencies and configuration"

# Install dependencies
install:
	@echo "📦 Installing dependencies..."
	chmod +x install.sh
	./install.sh

# Run locally
run-local:
	@echo "🏠 Running API locally..."
	chmod +x run.sh
	./run.sh local

# Run with ngrok
run-ngrok:
	@echo "🌐 Running API with ngrok..."
	chmod +x run.sh
	./run.sh ngrok

# Docker targets
docker-build:
	@echo "🐳 Building Docker image..."
	docker build -t $(DOCKER_IMAGE) .

docker-run: docker-build
	@echo "🐳 Running with Docker Compose..."
	docker-compose up

docker-stop:
	@echo "🛑 Stopping Docker containers..."
	docker-compose down

# Setup environment
setup-env:
	@echo "⚙️ Setting up environment..."
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "✅ Created .env file from template"; \
		echo "📝 Please edit .env and add your NGROK_AUTH_TOKEN"; \
	else \
		echo "⚠️ .env file already exists"; \
	fi

# Check configuration
check:
	@echo "🔍 Checking configuration..."
	chmod +x run.sh
	./run.sh check

# Clean temporary files
clean:
	@echo "🧹 Cleaning temporary files..."
	rm -rf temp_data/*
	rm -rf logs/*.log
	rm -rf __pycache__/
	rm -rf *.pyc
	rm -rf .pytest_cache/
	docker system prune -f

# Run tests (if you have tests)
test:
	@echo "🧪 Running tests..."
	@if [ -f requirements-test.txt ]; then \
		$(PIP) install -r requirements-test.txt; \
	fi
	@if [ -d tests ]; then \
		$(PYTHON) -m pytest tests/ -v; \
	else \
		echo "No tests directory found"; \
	fi

# Development setup
dev-setup: setup-env
	@echo "👨‍💻 Setting up development environment..."
	$(PIP) install -r requirements.txt
	mkdir -p temp_data logs
	@echo "✅ Development environment ready!"

# Quick start (full setup and run)
quickstart: install setup-env
	@echo "🚀 Quick start complete!"
	@echo "📝 Edit .env file and add your NGROK_AUTH_TOKEN"
	@echo "▶️ Run 'make run-ngrok' to start with public access"
	@echo "▶️ Run 'make run-local' to start locally"

# Show logs
logs:
	@echo "📋 Showing recent logs..."
	@if [ -f logs/app.log ]; then \
		tail -f logs/app.log; \
	else \
		echo "No log file found"; \
	fi

# Health check
health:
	@echo "🏥 Checking API health..."
	@curl -s http://localhost:8000/health | $(PYTHON) -m json.tool || echo "API not running"