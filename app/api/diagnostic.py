# app/api/diagnostic.py
from fastapi import APIRouter, HTTPException, Depends
from typing import List
from datetime import datetime
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.database import get_database
from app.schemas.diagnostic import (
    DiagnosticAnalyzeRequest,
    DiagnosticHistoryResponse,
    DiagnosticStatsResponse,
    DiagnosticResponse
)

router = APIRouter(prefix="/api/diagnostic", tags=["diagnostic"])



def _create_default_analysis(prompt: str = None) -> dict:
    """Crée une analyse par défaut sans Gemini."""
    return {
        "plant_name": "Plante analysée",
        "disease_name": "Aucune maladie détectée",
        "severity": None,
        "description": "Analyse locale sans IA externe. Consulter un expert pour un diagnostic précis.",
        "treatments": ["Arroser régulièrement", "Exposer à la lumière", "Vérifier le pH du sol"],
        "confidence": 0.4
    }


@router.post("/analyze", response_model=DiagnosticResponse)
async def analyze_plant(
    request: DiagnosticAnalyzeRequest,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Crée un diagnostic pour une image de plante (sans IA externe)."""
    try:
        print(f"📥 Nouvelle demande diagnostic pour user: {request.user_id}")
        
        # Créer une analyse par défaut
        analysis = _create_default_analysis(request.prompt)
        
        print(f"✅ Diagnostic créé: {analysis['plant_name']} - {analysis['disease_name']}")
        
        # Créer le document diagnostic
        diagnostic_doc = {
            "user_id": request.user_id,
            "plant_name": analysis["plant_name"],
            "disease_name": analysis["disease_name"],
            "severity": analysis.get("severity"),
            "description": analysis["description"],
            "treatments": analysis.get("treatments", []),
            "confidence_score": analysis.get("confidence", 0.4),
            "image_base64": request.image_base64,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        # Insérer dans MongoDB
        result = await db.diagnostics.insert_one(diagnostic_doc)
        diagnostic_id = str(result.inserted_id)
        
        print(f"✅ Diagnostic créé - ID: {diagnostic_id}")
        
        return DiagnosticResponse(
            diagnostic_id=diagnostic_id,
            data={
                "plant_name": analysis["plant_name"],
                "disease_name": analysis["disease_name"],
                "severity": analysis.get("severity"),
                "description": analysis["description"],
                "treatments": analysis.get("treatments", []),
                "confidence": analysis.get("confidence", 0.5)
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Erreur analyze_plant: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Erreur serveur: {str(e)}"
        )


@router.get("/history/{user_id}", response_model=DiagnosticHistoryResponse)
async def get_diagnostic_history(
    user_id: str, 
    page: int = 1, 
    limit: int = 10,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Récupère l'historique des diagnostics."""
    try:
        skip = (page - 1) * limit
        
        total = await db.diagnostics.count_documents({"user_id": user_id})
        
        cursor = db.diagnostics.find(
            {"user_id": user_id},
            {"image_base64": 0}
        ).sort("created_at", -1).skip(skip).limit(limit)
        
        diagnostics = []
        async for doc in cursor:
            doc["_id"] = str(doc["_id"])
            if "created_at" in doc and isinstance(doc["created_at"], datetime):
                doc["created_at"] = doc["created_at"].isoformat()
            if "updated_at" in doc and isinstance(doc["updated_at"], datetime):
                doc["updated_at"] = doc["updated_at"].isoformat()
            diagnostics.append(doc)
        
        total_pages = (total + limit - 1) // limit
        
        return DiagnosticHistoryResponse(
            diagnostics=diagnostics,
            total=total,
            page=page,
            limit=limit,
            total_pages=total_pages
        )
        
    except Exception as e:
        print(f"❌ Erreur get_diagnostic_history: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/stats/{user_id}", response_model=DiagnosticStatsResponse)
async def get_diagnostic_stats(
    user_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Récupère les statistiques."""
    try:
        total = await db.diagnostics.count_documents({"user_id": user_id})
        healthy = await db.diagnostics.count_documents({
            "user_id": user_id,
            "disease_name": {"$regex": "aucune maladie", "$options": "i"}
        })
        diseased = total - healthy
        
        pipeline = [
            {"$match": {
                "user_id": user_id,
                "disease_name": {"$not": {"$regex": "aucune maladie", "$options": "i"}}
            }},
            {"$group": {"_id": "$disease_name", "count": {"$sum": 1}}},
            {"$sort": {"count": -1}},
            {"$limit": 1}
        ]
        
        most_common_result = await db.diagnostics.aggregate(pipeline).to_list(1)
        most_common = most_common_result[0]["_id"] if most_common_result else None
        
        recent_cursor = db.diagnostics.find(
            {"user_id": user_id},
            {"image_base64": 0}
        ).sort("created_at", -1).limit(5)
        
        recent_diagnostics = []
        async for doc in recent_cursor:
            doc["_id"] = str(doc["_id"])
            if "created_at" in doc and isinstance(doc["created_at"], datetime):
                doc["created_at"] = doc["created_at"].isoformat()
            if "updated_at" in doc and isinstance(doc["updated_at"], datetime):
                doc["updated_at"] = doc["updated_at"].isoformat()
            recent_diagnostics.append(doc)
        
        return DiagnosticStatsResponse(
            total_diagnostics=total,
            healthy_plants=healthy,
            diseased_plants=diseased,
            most_common_disease=most_common,
            recent_diagnostics=recent_diagnostics
        )
        
    except Exception as e:
        print(f"❌ Erreur get_diagnostic_stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{diagnostic_id}")
async def get_diagnostic_details(
    diagnostic_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Récupère les détails complets d'un diagnostic."""
    try:
        try:
            obj_id = ObjectId(diagnostic_id)
        except Exception:
            raise HTTPException(status_code=400, detail="ID invalide")
        
        diagnostic = await db.diagnostics.find_one({"_id": obj_id})
        
        if not diagnostic:
            raise HTTPException(status_code=404, detail="Diagnostic non trouvé")
        
        diagnostic["_id"] = str(diagnostic["_id"])
        
        if "created_at" in diagnostic and isinstance(diagnostic["created_at"], datetime):
            diagnostic["created_at"] = diagnostic["created_at"].isoformat()
        if "updated_at" in diagnostic and isinstance(diagnostic["updated_at"], datetime):
            diagnostic["updated_at"] = diagnostic["updated_at"].isoformat()
        
        return diagnostic
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Erreur get_diagnostic_details: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{diagnostic_id}")
async def delete_diagnostic(
    diagnostic_id: str, 
    user_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Supprime un diagnostic."""
    try:
        try:
            obj_id = ObjectId(diagnostic_id)
        except Exception:
            raise HTTPException(status_code=400, detail="ID invalide")
        
        diagnostic = await db.diagnostics.find_one({"_id": obj_id})
        
        if not diagnostic:
            raise HTTPException(status_code=404, detail="Diagnostic non trouvé")
        
        if diagnostic.get("user_id") != user_id:
            raise HTTPException(status_code=403, detail="Non autorisé")
        
        result = await db.diagnostics.delete_one({"_id": obj_id})
        
        if result.deleted_count == 0:
            raise HTTPException(status_code=500, detail="Échec suppression")
        
        return {"message": "Diagnostic supprimé", "diagnostic_id": diagnostic_id}
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ Erreur delete_diagnostic: {e}")
        raise HTTPException(status_code=500, detail=str(e))