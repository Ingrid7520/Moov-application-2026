# app/api/diagnostics.py
"""
API complète de gestion des diagnostics
CRUD + statistiques + historique
"""

from fastapi import APIRouter, Depends, HTTPException, status, Query
from motor.motor_asyncio import AsyncIOMotorDatabase
from typing import List, Optional
from datetime import datetime, timedelta
from bson import ObjectId
import logging

from app.database import get_database
from app.models.diagnostic import (
    DiagnosticCreate, DiagnosticUpdate, DiagnosticResponse,
    DiagnosticStats, DiagnosticStatus, DiseaseSeverity
)
from app.core.dependencies import get_current_active_user
from app.services.notification_service import notify_diagnostic_completed

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/diagnostics", tags=["Diagnostics"])

def to_objectid(id_str: str) -> ObjectId:
    """Convertir un string en ObjectId"""
    try:
        return ObjectId(id_str)
    except:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="ID de diagnostic invalide"
        )

def serialize_diagnostic(diagnostic: dict) -> dict:
    """Sérialiser un diagnostic MongoDB"""
    if not diagnostic:
        return None
    diagnostic["id"] = str(diagnostic["_id"])
    diagnostic.pop("_id", None)
    return diagnostic

# ============================================================================
# CREATE - Créer un diagnostic
# ============================================================================
@router.post("", status_code=status.HTTP_201_CREATED, response_model=DiagnosticResponse)
async def create_diagnostic(
    diagnostic: DiagnosticCreate,
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Créer un nouveau diagnostic après analyse d'image
    
    - **image_path**: Chemin de l'image analysée (requis)
    - **plant_name**: Nom de la plante (optionnel)
    - **disease_name**: Maladie détectée (optionnel)
    - **severity**: Sévérité (none, low, moderate, high, critical)
    - **confidence**: Confiance du diagnostic en % (0-100)
    - **description**: Description de la maladie
    - **symptoms**: Liste des symptômes
    - **treatments**: Liste des traitements recommandés
    - **prevention_tips**: Conseils de prévention
    """
    try:
        # Préparer les données
        diagnostic_data = {
            "user_id": str(current_user["_id"]),
            "user_name": current_user.get("name", "Utilisateur"),
            "image_path": diagnostic.image_path,
            "image_url": f"http://172.16.1.218:8001{diagnostic.image_path}" if not diagnostic.image_path.startswith("http") else diagnostic.image_path,
            "plant_name": diagnostic.plant_name,
            "disease_name": diagnostic.disease_name,
            "severity": diagnostic.severity.value if diagnostic.severity else None,
            "confidence": diagnostic.confidence,
            "description": diagnostic.description,
            "symptoms": diagnostic.symptoms or [],
            "treatments": diagnostic.treatments or [],
            "prevention_tips": diagnostic.prevention_tips or [],
            "notes": diagnostic.notes,
            "status": DiagnosticStatus.COMPLETED.value,
            "location": diagnostic.location,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        # Insérer en base
        result = await db.diagnostics.insert_one(diagnostic_data)
        
        # Récupérer le diagnostic créé
        created_diagnostic = await db.diagnostics.find_one({"_id": result.inserted_id})
        
        logger.info(f"✅ Diagnostic créé: {result.inserted_id} pour {current_user['name']}")
        
        # Envoyer notification si maladie détectée
        if diagnostic.disease_name and diagnostic.disease_name.lower() != "aucune":
            try:
                await notify_diagnostic_completed(
                    db=db,
                    user_id=str(current_user["_id"]),
                    diagnostic_id=str(result.inserted_id),
                    disease_name=diagnostic.disease_name,
                    plant_name=diagnostic.plant_name or "Plante inconnue"
                )
                logger.info(f"📬 Notification diagnostic envoyée")
            except Exception as e:
                logger.error(f"⚠️ Erreur envoi notification: {e}")
        
        return DiagnosticResponse(**serialize_diagnostic(created_diagnostic))
        
    except Exception as e:
        logger.error(f"❌ Erreur création diagnostic: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================================================
# READ - Lire les diagnostics
# ============================================================================
@router.get("", response_model=List[DiagnosticResponse])
async def get_diagnostics(
    status: Optional[DiagnosticStatus] = Query(None, description="Filtrer par statut"),
    severity: Optional[DiseaseSeverity] = Query(None, description="Filtrer par sévérité"),
    limit: int = Query(50, ge=1, le=100, description="Nombre max de résultats"),
    skip: int = Query(0, ge=0, description="Nombre de résultats à ignorer"),
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Récupérer les diagnostics de l'utilisateur connecté
    
    - **status**: Filtrer par statut (pending, processing, completed, failed)
    - **severity**: Filtrer par sévérité (none, low, moderate, high, critical)
    - **limit**: Nombre max de résultats
    - **skip**: Pagination
    """
    try:
        # Construire la requête
        query = {"user_id": str(current_user["_id"])}
        
        if status:
            query["status"] = status.value
        
        if severity:
            query["severity"] = severity.value
        
        # Récupérer les diagnostics
        cursor = db.diagnostics.find(query)\
            .sort("created_at", -1)\
            .skip(skip)\
            .limit(limit)
        
        diagnostics = await cursor.to_list(length=limit)
        
        logger.info(f"📊 {len(diagnostics)} diagnostics récupérés pour {current_user['name']}")
        
        return [DiagnosticResponse(**serialize_diagnostic(d)) for d in diagnostics]
        
    except Exception as e:
        logger.error(f"❌ Erreur récupération diagnostics: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/recent", response_model=List[DiagnosticResponse])
async def get_recent_diagnostics(
    days: int = Query(7, ge=1, le=30, description="Nombre de jours"),
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Récupérer les diagnostics récents (7 derniers jours par défaut)
    
    - **days**: Nombre de jours (défaut: 7, max: 30)
    """
    try:
        cutoff_date = datetime.utcnow() - timedelta(days=days)
        
        cursor = db.diagnostics.find({
            "user_id": str(current_user["_id"]),
            "created_at": {"$gte": cutoff_date}
        }).sort("created_at", -1)
        
        diagnostics = await cursor.to_list(length=None)
        
        logger.info(f"📅 {len(diagnostics)} diagnostics des {days} derniers jours pour {current_user['name']}")
        
        return [DiagnosticResponse(**serialize_diagnostic(d)) for d in diagnostics]
        
    except Exception as e:
        logger.error(f"❌ Erreur diagnostics récents: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/stats", response_model=DiagnosticStats)
async def get_diagnostics_stats(
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Obtenir les statistiques des diagnostics de l'utilisateur
    
    Retourne:
    - total: nombre total de diagnostics
    - by_status: répartition par statut
    - by_severity: répartition par sévérité
    - most_common_diseases: maladies les plus fréquentes
    - recent_diagnostics: nombre des 7 derniers jours
    """
    try:
        user_id = str(current_user["_id"])
        
        # Compter total
        total = await db.diagnostics.count_documents({"user_id": user_id})
        
        # Compter par statut
        status_pipeline = [
            {"$match": {"user_id": user_id}},
            {"$group": {"_id": "$status", "count": {"$sum": 1}}}
        ]
        status_results = await db.diagnostics.aggregate(status_pipeline).to_list(None)
        by_status = {item["_id"]: item["count"] for item in status_results}
        
        # Compter par sévérité
        severity_pipeline = [
            {"$match": {"user_id": user_id, "severity": {"$ne": None}}},
            {"$group": {"_id": "$severity", "count": {"$sum": 1}}}
        ]
        severity_results = await db.diagnostics.aggregate(severity_pipeline).to_list(None)
        by_severity = {item["_id"]: item["count"] for item in severity_results}
        
        # Maladies les plus communes
        disease_pipeline = [
            {
                "$match": {
                    "user_id": user_id,
                    "disease_name": {"$ne": None, "$nin": ["", "Aucune", "aucune"]}
                }
            },
            {
                "$group": {
                    "_id": "$disease_name",
                    "count": {"$sum": 1},
                    "avg_severity": {"$avg": {
                        "$switch": {
                            "branches": [
                                {"case": {"$eq": ["$severity", "none"]}, "then": 0},
                                {"case": {"$eq": ["$severity", "low"]}, "then": 1},
                                {"case": {"$eq": ["$severity", "moderate"]}, "then": 2},
                                {"case": {"$eq": ["$severity", "high"]}, "then": 3},
                                {"case": {"$eq": ["$severity", "critical"]}, "then": 4},
                            ],
                            "default": 0
                        }
                    }}
                }
            },
            {"$sort": {"count": -1}},
            {"$limit": 5}
        ]
        disease_results = await db.diagnostics.aggregate(disease_pipeline).to_list(5)
        most_common_diseases = [
            {
                "disease_name": item["_id"],
                "count": item["count"],
                "avg_severity": round(item.get("avg_severity", 0), 2)
            }
            for item in disease_results
        ]
        
        # Diagnostics récents (7 jours)
        cutoff_date = datetime.utcnow() - timedelta(days=7)
        recent_count = await db.diagnostics.count_documents({
            "user_id": user_id,
            "created_at": {"$gte": cutoff_date}
        })
        
        stats = DiagnosticStats(
            total=total,
            by_status=by_status,
            by_severity=by_severity,
            most_common_diseases=most_common_diseases,
            recent_diagnostics=recent_count
        )
        
        logger.info(f"📈 Stats diagnostics pour {current_user['name']}: {total} total")
        
        return stats
        
    except Exception as e:
        logger.error(f"❌ Erreur stats diagnostics: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{diagnostic_id}", response_model=DiagnosticResponse)
async def get_diagnostic(
    diagnostic_id: str,
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Obtenir un diagnostic spécifique par son ID
    """
    try:
        diagnostic = await db.diagnostics.find_one({
            "_id": to_objectid(diagnostic_id),
            "user_id": str(current_user["_id"])
        })
        
        if not diagnostic:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Diagnostic non trouvé"
            )
        
        return DiagnosticResponse(**serialize_diagnostic(diagnostic))
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur récupération diagnostic: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================================================
# UPDATE - Mettre à jour un diagnostic
# ============================================================================
@router.put("/{diagnostic_id}", response_model=DiagnosticResponse)
async def update_diagnostic(
    diagnostic_id: str,
    diagnostic_update: DiagnosticUpdate,
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Mettre à jour un diagnostic existant
    
    Seul le propriétaire peut modifier son diagnostic
    """
    try:
        # Vérifier existence et propriété
        existing = await db.diagnostics.find_one({
            "_id": to_objectid(diagnostic_id),
            "user_id": str(current_user["_id"])
        })
        
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Diagnostic non trouvé"
            )
        
        # Préparer les données de mise à jour
        update_data = {}
        
        if diagnostic_update.status is not None:
            update_data["status"] = diagnostic_update.status.value
        if diagnostic_update.plant_name is not None:
            update_data["plant_name"] = diagnostic_update.plant_name
        if diagnostic_update.disease_name is not None:
            update_data["disease_name"] = diagnostic_update.disease_name
        if diagnostic_update.severity is not None:
            update_data["severity"] = diagnostic_update.severity.value
        if diagnostic_update.confidence is not None:
            update_data["confidence"] = diagnostic_update.confidence
        if diagnostic_update.description is not None:
            update_data["description"] = diagnostic_update.description
        if diagnostic_update.symptoms is not None:
            update_data["symptoms"] = diagnostic_update.symptoms
        if diagnostic_update.treatments is not None:
            update_data["treatments"] = diagnostic_update.treatments
        if diagnostic_update.prevention_tips is not None:
            update_data["prevention_tips"] = diagnostic_update.prevention_tips
        if diagnostic_update.notes is not None:
            update_data["notes"] = diagnostic_update.notes
        
        # Toujours mettre à jour updated_at
        update_data["updated_at"] = datetime.utcnow()
        
        # Appliquer les modifications
        await db.diagnostics.update_one(
            {"_id": to_objectid(diagnostic_id)},
            {"$set": update_data}
        )
        
        # Récupérer le diagnostic mis à jour
        updated_diagnostic = await db.diagnostics.find_one(
            {"_id": to_objectid(diagnostic_id)}
        )
        
        logger.info(f"✏️ Diagnostic {diagnostic_id} mis à jour par {current_user['name']}")
        
        return DiagnosticResponse(**serialize_diagnostic(updated_diagnostic))
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur mise à jour diagnostic: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================================================
# DELETE - Supprimer un diagnostic
# ============================================================================
@router.delete("/{diagnostic_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_diagnostic(
    diagnostic_id: str,
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Supprimer un diagnostic
    
    Seul le propriétaire peut supprimer son diagnostic
    """
    try:
        result = await db.diagnostics.delete_one({
            "_id": to_objectid(diagnostic_id),
            "user_id": str(current_user["_id"])
        })
        
        if result.deleted_count == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Diagnostic non trouvé"
            )
        
        logger.info(f"🗑️ Diagnostic {diagnostic_id} supprimé par {current_user['name']}")
        
        return None
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur suppression diagnostic: {e}")
        raise HTTPException(status_code=500, detail=str(e))