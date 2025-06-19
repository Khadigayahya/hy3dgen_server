import os
import logging
from pathlib import Path
from fastapi import UploadFile, HTTPException
import aiofiles

logger = logging.getLogger(__name__)

def cleanup_file(file_path: str):
    """Background task to clean up temporary files"""
    try:
        if os.path.exists(file_path):
            os.remove(file_path)
            print(f"Cleaned up: {file_path}")
    except Exception as e:
        logger.error(f"Error cleaning up {file_path}: {e}")

async def validate_image(file: UploadFile, supported_formats: set) -> None:
    """Validate uploaded image file"""
    if not file.filename:
        raise HTTPException(status_code=400, detail="No filename provided")

    file_ext = file.filename.split('.')[-1].lower()
    if file_ext not in supported_formats:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported format. Supported: {', '.join(supported_formats)}"
        )

    # Check file size (max 10MB)
    content = await file.read()
    if len(content) > 10 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="File too large (max 10MB)")

    # Reset file position
    await file.seek(0)

async def save_upload_file(upload_file: UploadFile, destination: Path) -> None:
    """Save uploaded file"""
    content = await upload_file.read()
    async with aiofiles.open(destination, 'wb') as f:
        await f.write(content)