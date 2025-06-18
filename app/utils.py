import os
import aiofiles
from fastapi import HTTPException, UploadFile

async def validate_image(file: UploadFile, supported_formats: set):
    if not file.filename:
        raise HTTPException(status_code=400, detail="No filename provided")

    file_ext = file.filename.split('.')[-1].lower()
    if file_ext not in supported_formats:
        raise HTTPException(status_code=400, detail=f"Unsupported format: {file_ext}")

    content = await file.read()
    if len(content) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File too large (max 10MB)")
    await file.seek(0)

async def save_upload_file(upload_file: UploadFile, destination):
    content = await upload_file.read()
    async with aiofiles.open(destination, 'wb') as f:
        await f.write(content)

def cleanup_file(file_path: str):
    if os.path.exists(file_path):
        os.remove(file_path)
