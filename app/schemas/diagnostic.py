# app/schemas/diagnostic.py
from pydantic import BaseModel
from typing import List, Optional


class DiagnosticAnalyzeRequest(BaseModel):
    """Requête pour analyser une image de plante"""
    user_id: str
    image_base64: str
    prompt: Optional[str] = None


class DiagnosticData(BaseModel):
    """Données du diagnostic"""
    plant_name: str
    disease_name: str
    severity: Optional[str] = None
    description: str
    treatments: List[str]
    confidence: float


class DiagnosticResponse(BaseModel):
    """Réponse du diagnostic"""
    diagnostic_id: str
    data: DiagnosticData


class DiagnosticHistoryItem(BaseModel):
    """Un diagnostic dans l'historique"""
    _id: str
    user_id: str
    plant_name: str
    disease_name: str
    severity: Optional[str] = None
    description: str
    treatments: List[str]
    confidence_score: float
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


class DiagnosticHistoryResponse(BaseModel):
    """Réponse avec historique des diagnostics"""
    diagnostics: List[DiagnosticHistoryItem]
    total: int
    page: int
    limit: int
    total_pages: int


class DiagnosticStatsResponse(BaseModel):
    """Statistiques des diagnostics d'un utilisateur"""
    total_diagnostics: int
    healthy_plants: int
    diseased_plants: int
    most_common_disease: Optional[str] = None
    recent_diagnostics: List[DiagnosticHistoryItem]