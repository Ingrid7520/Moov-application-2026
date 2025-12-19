# app/services/chat_history_service.py
"""
✅ VERSION ULTRA-RAPIDE - Sans aucune opération lente
"""

from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from datetime import datetime
from typing import Optional
import logging

logger = logging.getLogger(__name__)


class ChatHistoryService:
    """Service optimisé pour vitesse maximale"""
    
    def __init__(self, db: AsyncIOMotorDatabase):
        self.db = db
        self.collection = db.chat_conversations
    
    async def create_conversation(
        self,
        user_id: str,
        session_id: str,
        title: str = "Nouvelle conversation"
    ) -> dict:
        """Créer une nouvelle conversation"""
        conversation = {
            "user_id": user_id,
            "session_id": session_id,
            "title": title,
            "messages": [],
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
            "is_archived": False,
            "message_count": 0,
            "last_message_preview": None
        }
        
        result = await self.collection.insert_one(conversation)
        
        return {
            "status": "success",
            "conversation_id": str(result.inserted_id),
        }
    
    async def get_or_create_conversation(
        self,
        user_id: str,
        session_id: str
    ) -> dict:
        """Récupérer ou créer une conversation"""
        conversation = await self.collection.find_one({
            "user_id": user_id,
            "session_id": session_id
        })
        
        if conversation:
            return {
                "status": "success",
                "conversation_id": str(conversation["_id"]),
                "created": False
            }
        
        result = await self.create_conversation(user_id, session_id)
        result["created"] = True
        return result
    
    async def add_message(
        self,
        conversation_id: str,
        role: str,
        content: str,
        message_type: str = "text",
        image_url: Optional[str] = None,
        audio_url: Optional[str] = None,
        audio_duration: Optional[int] = None
    ) -> dict:
        """
        ✅ ULTRA-RAPIDE - Update minimal sans validation
        """
        try:
            # Message minimal
            message = {
                "role": role,
                "content": content,
                "message_type": message_type,
                "timestamp": datetime.utcnow()
            }
            
            if image_url:
                message["image_url"] = image_url
            if audio_url:
                message["audio_url"] = audio_url
                message["audio_duration"] = audio_duration
            
            # Preview court
            preview = content[:50]
            
            # ✅ UPDATE ULTRA-RAPIDE - Une seule opération
            await self.collection.update_one(
                {"_id": ObjectId(conversation_id)},
                {
                    "$push": {"messages": message},
                    "$set": {
                        "updated_at": datetime.utcnow(),
                        "last_message_preview": preview
                    },
                    "$inc": {"message_count": 1}
                }
            )
            
            # ✅ RETOUR IMMÉDIAT sans vérification
            return {"status": "success"}
            
        except Exception as e:
            logger.error(f"❌ add_message: {str(e)}")
            return {"status": "error", "message": str(e)}
    
    async def get_conversation(
        self,
        conversation_id: str,
        user_id: str
    ) -> dict:
        """Récupérer une conversation"""
        conversation = await self.collection.find_one({
            "_id": ObjectId(conversation_id),
            "user_id": user_id
        })
        
        if not conversation:
            return {"status": "error", "message": "Non trouvée"}
        
        conversation["id"] = str(conversation.pop("_id"))
        
        return {
            "status": "success",
            "conversation": conversation
        }
    
    async def list_conversations(
        self,
        user_id: str,
        include_archived: bool = False,
        limit: int = 50,
        skip: int = 0
    ) -> dict:
        """Lister les conversations"""
        query = {"user_id": user_id}
        
        if not include_archived:
            query["is_archived"] = False
        
        cursor = self.collection.find(query).sort(
            "updated_at", -1
        ).skip(skip).limit(limit)
        
        conversations = await cursor.to_list(length=limit)
        
        result = []
        for conv in conversations:
            result.append({
                "id": str(conv["_id"]),
                "title": conv["title"],
                "session_id": conv["session_id"],
                "message_count": conv.get("message_count", 0),
                "last_message_preview": conv.get("last_message_preview"),
                "updated_at": conv["updated_at"].isoformat(),
                "is_archived": conv.get("is_archived", False)
            })
        
        return {
            "status": "success",
            "conversations": result,
            "total": len(result)
        }
    
    async def update_conversation(
        self,
        conversation_id: str,
        user_id: str,
        title: Optional[str] = None,
        is_archived: Optional[bool] = None
    ) -> dict:
        """Mettre à jour une conversation"""
        update_data = {"updated_at": datetime.utcnow()}
        
        if title is not None:
            update_data["title"] = title
        if is_archived is not None:
            update_data["is_archived"] = is_archived
        
        await self.collection.update_one(
            {"_id": ObjectId(conversation_id), "user_id": user_id},
            {"$set": update_data}
        )
        
        return {"status": "success"}
    
    async def delete_conversation(
        self,
        conversation_id: str,
        user_id: str
    ) -> dict:
        """Archiver une conversation"""
        await self.collection.update_one(
            {"_id": ObjectId(conversation_id), "user_id": user_id},
            {"$set": {"is_archived": True, "updated_at": datetime.utcnow()}}
        )
        
        return {"status": "success"}
    
    async def get_user_stats(self, user_id: str) -> dict:
        """Statistiques utilisateur"""
        pipeline = [
            {"$match": {"user_id": user_id}},
            {
                "$group": {
                    "_id": None,
                    "total_conversations": {"$sum": 1},
                    "total_messages": {"$sum": "$message_count"},
                    "archived_count": {"$sum": {"$cond": ["$is_archived", 1, 0]}},
                    "last_updated": {"$max": "$updated_at"}
                }
            }
        ]
        
        result = await self.collection.aggregate(pipeline).to_list(length=1)
        
        if not result:
            return {
                "status": "success",
                "stats": {
                    "total_conversations": 0,
                    "total_messages": 0,
                    "archived_conversations": 0,
                    "last_conversation_date": None
                }
            }
        
        stats = result[0]
        
        return {
            "status": "success",
            "stats": {
                "total_conversations": stats["total_conversations"],
                "total_messages": stats["total_messages"],
                "archived_conversations": stats["archived_count"],
                "last_conversation_date": stats["last_updated"].isoformat() if stats.get("last_updated") else None
            }
        }