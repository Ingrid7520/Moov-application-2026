"""
Modèle MongoDB pour les diagnostics de plantes
"""

from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field
from bson import ObjectId


class DiagnosticBase(BaseModel):
    """Données de base d'un diagnostic"""
    user_id: str
    plant_name: Optional[str] = None
    disease_name: str
    severity: Optional[str] = None  # "Sévère", "Modéré", "Léger"
    description: str
    treatments: List[str] = []
    confidence_score: Optional[float] = None  # Score de confiance de l'IA (0-1)
    image_base64: Optional[str] = None  # Image en base64
    

class DiagnosticCreate(DiagnosticBase):
    """Données pour créer un diagnostic"""
    pass


class DiagnosticInDB(DiagnosticBase):
    """Diagnostic stocké dans MongoDB"""
    id: str = Field(alias="_id")
    created_at: datetime
    updated_at: datetime
    
    class Config:
        populate_by_name = True
        json_encoders = {
            ObjectId: str,
            datetime: lambda v: v.isoformat()
        }


class DiagnosticResponse(BaseModel):
    """Réponse API pour un diagnostic"""
    id: str
    user_id: str
    plant_name: Optional[str]
    disease_name: str
    severity: Optional[str]
    description: str
    treatments: List[str]
    confidence_score: Optional[float]
    image_url: Optional[str] = None  # URL de l'image si stockée
    created_at: datetime
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat()
        }