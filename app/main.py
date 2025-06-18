import nest_asyncio
nest_asyncio.apply()

from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
import uuid
from pathlib import Path
import torch
from pyngrok import ngrok
import logging

from app.model_manager import model_manager
from app.utils import validate_image, save_upload_file, cleanup_file

import trimesh

app = FastAPI(
    title="3D Model Generator API",
    description="Generate 3D models from images using Hunyuan3D",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

TEMP_DIR = Path("/tmp/temp_3d")
TEMP_DIR.mkdir(exist_ok=True)

SUPPORTED_FORMATS = {"jpg", "jpeg", "png", "webp", "bmp"}

@app.get("/")
async def root():
    return {"status": "healthy"}

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "pipeline_loaded": model_manager._pipeline is not None,
        "cuda_available": torch.cuda.is_available(),
        "device_count": torch.cuda.device_count() if torch.cuda.is_available() else 0
    }

@app.post("/generate-3d")
async def generate_3d_model(background_tasks: BackgroundTasks, image: UploadFile = File(...)):
    await validate_image(image, SUPPORTED_FORMATS)
    request_id = str(uuid.uuid4())
    input_path = TEMP_DIR / f"input_{request_id}.jpg"
    output_path = TEMP_DIR / f"output_{request_id}.glb"

    try:
        await save_upload_file(image, input_path)
        pipeline = await model_manager.get_pipeline()
        mesh_result = pipeline(image=str(input_path))

        if not mesh_result:
            raise HTTPException(status_code=500, detail="Failed to generate 3D model")

        mesh = mesh_result[0]
        trimesh_obj = trimesh.Trimesh(vertices=mesh.vertices, faces=mesh.faces, process=False)
        trimesh_obj.export(str(output_path))

        background_tasks.add_task(cleanup_file, str(input_path))
        background_tasks.add_task(cleanup_file, str(output_path))

        return FileResponse(path=str(output_path), media_type="model/gltf-binary")

    except Exception as e:
        background_tasks.add_task(cleanup_file, str(input_path))
        background_tasks.add_task(cleanup_file, str(output_path))
        raise HTTPException(status_code=500, detail=str(e))
