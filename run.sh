#!/bin/bash

# Build Docker image
docker build -t hy3dgen-server .

# Run Docker container
docker run -p 8000:8000 hy3dgen-server
