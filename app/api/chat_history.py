# app/api/chat_history.py
"""
✅ API COMPLÈTE - Tous les endpoints fonctionnels
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from motor.motor_asyncio import AsyncIOMotorDatabase
import logging

from ..database import get_database
from ..services.chat_history_service import ChatHistoryService
from ..models.chat import (
    ChatConversationUpdate,
    AddMessageRequest,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/chat-history", tags=["Chat History"])


@router.get("/conversations")
async def list_conversations(
    user_id: str = Query(...),
    include_archived: bool = Query(False),
    limit: int = Query(50, ge=1, le=100),
    skip: int = Query(0, ge=0),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Lister les conversations d'un utilisateur"""
    service = ChatHistoryService(db)
    result = await service.list_conversations(
        user_id=user_id,
        include_archived=include_archived,
        limit=limit,
        skip=skip
    )
    
    if result["status"] == "success":
        return result
    else:
        raise HTTPException(status_code=500, detail=result.get("message"))


@router.post("/conversations/get-or-create")
async def get_or_create_conversation(
    user_id: str = Query(...),
    session_id: str = Query(...),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    ✅ ENDPOINT CRITIQUE - Récupérer ou créer conversation
    """
    service = ChatHistoryService(db)
    
    try:
        result = await service.get_or_create_conversation(
            user_id=user_id,
            session_id=session_id
        )
        
        if result["status"] == "success":
            logger.info(f"✅ get_or_create OK: {result.get('conversation_id', '')[:8]}...")
            return result
        else:
            logger.error(f"❌ get_or_create failed: {result.get('message')}")
            raise HTTPException(status_code=500, detail=result.get("message"))
    
    except Exception as e:
        logger.error(f"❌ Exception get_or_create: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/messages")
async def add_message(
    request: AddMessageRequest,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    ✅ ENDPOINT CRITIQUE - Ajouter message RAPIDEMENT
    """
    service = ChatHistoryService(db)
    
    try:
        logger.info(f"📨 Message reçu: {request.conversation_id[:8]}... | {request.role}")
        
        result = await service.add_message(
            conversation_id=request.conversation_id,
            role=request.role.value,
            content=request.content,
            message_type=request.message_type.value,
            image_url=request.image_url,
            audio_url=request.audio_url,
            audio_duration=request.audio_duration
        )
        
        if result["status"] == "success":
            logger.info(f"✅ Message sauvegardé: {request.conversation_id[:8]}...")
            return {"status": "success", "message": "Message ajouté"}
        else:
            logger.warning(f"⚠️ Erreur sauvegarde: {result.get('message')}")
            return {"status": "error", "message": result.get("message")}
    
    except Exception as e:
        logger.error(f"❌ Exception add_message: {str(e)}")
        # ✅ Retourner 200 même si erreur pour éviter timeout Flutter
        return {"status": "error", "message": str(e)}


@router.get("/conversations/{conversation_id}")
async def get_conversation(
    conversation_id: str,
    user_id: str = Query(...),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Récupérer une conversation complète avec tous les messages"""
    service = ChatHistoryService(db)
    result = await service.get_conversation(conversation_id, user_id)
    
    if result["status"] == "success":
        return result
    else:
        raise HTTPException(status_code=404, detail=result.get("message"))


@router.patch("/conversations/{conversation_id}")
async def update_conversation(
    conversation_id: str,
    user_id: str = Query(...),
    update: ChatConversationUpdate = None,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Mettre à jour une conversation"""
    service = ChatHistoryService(db)
    result = await service.update_conversation(
        conversation_id=conversation_id,
        user_id=user_id,
        title=update.title if update else None,
        is_archived=update.is_archived if update else None
    )
    
    if result["status"] == "success":
        return result
    else:
        raise HTTPException(status_code=404, detail=result.get("message"))


@router.delete("/conversations/{conversation_id}")
async def delete_conversation(
    conversation_id: str,
    user_id: str = Query(...),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Supprimer (archiver) une conversation"""
    service = ChatHistoryService(db)
    result = await service.delete_conversation(conversation_id, user_id)
    
    if result["status"] == "success":
        return result
    else:
        raise HTTPException(status_code=404, detail=result.get("message"))


@router.get("/stats")
async def get_user_stats(
    user_id: str = Query(...),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Statistiques utilisateur"""
    service = ChatHistoryService(db)
    return await service.get_user_stats(user_id)