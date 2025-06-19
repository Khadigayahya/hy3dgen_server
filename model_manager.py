import logging
from fastapi import HTTPException

logger = logging.getLogger(__name__)

class ModelManager:
    """Singleton class to manage the 3D model pipeline"""
    _instance = None
    _pipeline = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    async def get_pipeline(self):
        if self._pipeline is None:
            print("Loading Hunyuan3D pipeline...")
            try:
                # Import here to avoid issues if package isn't installed
                from hy3dgen.shapegen import Hunyuan3DDiTFlowMatchingPipeline
                self._pipeline = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained(
                    'tencent/Hunyuan3D-2'
                )
                print("Pipeline loaded successfully")
            except Exception as e:
                logger.error(f"Failed to load pipeline: {e}")
                raise HTTPException(status_code=500, detail=f"Failed to load model: {e}")
        return self._pipeline