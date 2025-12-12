from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from bson import ObjectId
from enum import Enum

from app.models.user import PyObjectId

class CropType(str, Enum):
    COCOA = "cocoa"
    CASHEW = "cashew"
    CASSAVA = "cassava"

class DiseaseSeverity(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class DiseaseBase(BaseModel):
    crop_type: CropType
    disease_name: str
    scientific_name: Optional[str] = None
    symptoms: List[str]
    causes: List[str]
    prevention_methods: List[str]
    treatment_methods: List[str]
    organic_treatments: List[str] = []
    chemical_treatments: List[str] = []

class DiseaseCreate(DiseaseBase):
    pass

class DiseaseInDB(DiseaseBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    ai_model_version: str
    accuracy: float
    sample_images: List[str] = []
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}

class DiagnosisResult(BaseModel):
    image_id: str
    crop_type: CropType
    disease_id: str
    confidence: float
    severity: DiseaseSeverity
    recommended_treatments: List[str]
    prevention_tips: List[str]
    diagnosed_at: datetime = Field(default_factory=datetime.utcnow)