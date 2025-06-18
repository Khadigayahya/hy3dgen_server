from fastapi import HTTPException
import logging

logger = logging.getLogger(__name__)

class ModelManager:
    _instance = None
    _pipeline = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    async def get_pipeline(self):
        if self._pipeline is None:
            try:
                from hy3dgen.shapegen import Hunyuan3DDiTFlowMatchingPipeline
                self._pipeline = Hunyuan3DDiTFlowMatchingPipeline.from_pretrained('tencent/Hunyuan3D-2')
            except Exception as e:
                logger.error(f"Failed to load pipeline: {e}")
                raise HTTPException(status_code=500, detail=str(e))
        return self._pipeline

model_manager = ModelManager()
