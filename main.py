import os
import tempfile
import uuid
import asyncio
import logging
import threading
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import torch
import trimesh
from pyngrok import ngrok
import aiofiles
import nest_asyncio

from model_manager import ModelManager
from utils import cleanup_file, validate_image, save_upload_file

# Enable nested asyncio (required for Colab)
nest_asyncio.apply()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="3D Model Generator API",
    description="Generate 3D models from images using Hunyuan3D",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Setup paths
TEMP_DIR = Path(os.getenv("TEMP_DIR", "/tmp/temp_3d"))
TEMP_DIR.mkdir(exist_ok=True)

# Supported image formats
SUPPORTED_FORMATS = {"jpg", "jpeg", "png", "webp", "bmp"}

# Initialize model manager
model_manager = ModelManager()

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "message": "3D Model Generator API",
        "status": "healthy",
        "supported_formats": list(SUPPORTED_FORMATS),
        "temp_dir": str(TEMP_DIR)
    }

@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "pipeline_loaded": model_manager._pipeline is not None,
        "cuda_available": torch.cuda.is_available(),
        "device_count": torch.cuda.device_count() if torch.cuda.is_available() else 0,
        "temp_dir": str(TEMP_DIR)
    }

@app.post("/generate-3d")
async def generate_3d_model(
    background_tasks: BackgroundTasks,
    image: UploadFile = File(..., description="Image file to convert to 3D model")
):
    """Generate a 3D model from an uploaded image"""
    print("Received request for generation")
    await validate_image(image, SUPPORTED_FORMATS)

    request_id = str(uuid.uuid4())
    input_path = TEMP_DIR / f"input_{request_id}.jpg"
    output_path = TEMP_DIR / f"output_{request_id}.glb"

    try:
        print(f"Processing request {request_id}")

        # Save uploaded file
        await save_upload_file(image, input_path)
        print(f"Saved input: {input_path}")

        # Get pipeline
        pipeline = await model_manager.get_pipeline()

        # Generate 3D model
        print("Generating 3D model...")
        mesh_result = pipeline(image=str(input_path))

        if not mesh_result or len(mesh_result) == 0:
            raise HTTPException(status_code=500, detail="Failed to generate 3D model")

        mesh = mesh_result[0]

        # Convert to trimesh and export
        print("Converting to GLB...")
        trimesh_obj = trimesh.Trimesh(
            vertices=mesh.vertices,
            faces=mesh.faces,
            process=False
        )

        trimesh_obj.export(str(output_path))
        print(f"Model saved: {output_path}")

        # Schedule cleanup
        background_tasks.add_task(cleanup_file, str(input_path))
        background_tasks.add_task(cleanup_file, str(output_path))

        return FileResponse(
            path=str(output_path),
            media_type="model/gltf-binary",
            filename=f"model_{request_id}.glb"
        )

    except Exception as e:
        background_tasks.add_task(cleanup_file, str(input_path))
        background_tasks.add_task(cleanup_file, str(output_path))
        logger.error(f"Error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    uvicorn.run(app, host=host, port=port)