# app/models/chat.py
"""
Modèles pour l'historique des conversations chat
Sauvegardé dans MongoDB pour consultation ultérieure
"""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from bson import ObjectId
from enum import Enum


class MessageRole(str, Enum):
    """Rôle du message"""
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"


class MessageType(str, Enum):
    """Type de message"""
    TEXT = "text"
    IMAGE = "image"
    AUDIO = "audio"


class ChatMessageModel(BaseModel):
    """Message individuel dans une conversation"""
    role: MessageRole
    content: str
    message_type: MessageType = MessageType.TEXT
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    # Metadata pour images/audio
    image_url: Optional[str] = None
    audio_url: Optional[str] = None
    audio_duration: Optional[int] = None  # en secondes
    
    class Config:
        use_enum_values = True
        json_encoders = {datetime: lambda v: v.isoformat()}


class ChatConversationCreate(BaseModel):
    """Création d'une nouvelle conversation"""
    user_id: str
    title: Optional[str] = "Nouvelle conversation"
    session_id: Optional[str] = None


class ChatConversationUpdate(BaseModel):
    """Mise à jour d'une conversation"""
    title: Optional[str] = None
    is_archived: Optional[bool] = None


class ChatConversationInDB(BaseModel):
    """Conversation stockée dans MongoDB"""
    id: str = Field(alias="_id")
    user_id: str
    session_id: str
    title: str = "Nouvelle conversation"
    messages: List[ChatMessageModel] = []
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    is_archived: bool = False
    message_count: int = 0
    last_message_preview: Optional[str] = None
    
    class Config:
        populate_by_name = True
        json_encoders = {
            ObjectId: str,
            datetime: lambda v: v.isoformat()
        }
        use_enum_values = True


class ChatConversationResponse(BaseModel):
    """Réponse API pour une conversation complète"""
    id: str
    user_id: str
    session_id: str
    title: str
    messages: List[ChatMessageModel]
    created_at: datetime
    updated_at: datetime
    is_archived: bool
    message_count: int
    
    class Config:
        json_encoders = {datetime: lambda v: v.isoformat()}
        use_enum_values = True


class ChatConversationListItem(BaseModel):
    """Item de liste (sans messages complets)"""
    id: str
    title: str
    session_id: str
    message_count: int
    last_message_preview: Optional[str] = None
    updated_at: datetime
    is_archived: bool
    
    class Config:
        json_encoders = {datetime: lambda v: v.isoformat()}


class AddMessageRequest(BaseModel):
    """Requête pour ajouter un message à l'historique"""
    conversation_id: str
    role: MessageRole
    content: str
    message_type: MessageType = MessageType.TEXT
    image_url: Optional[str] = None
    audio_url: Optional[str] = None
    audio_duration: Optional[int] = None


class ChatStatsResponse(BaseModel):
    """Statistiques utilisateur"""
    total_conversations: int
    total_messages: int
    archived_conversations: int
    last_conversation_date: Optional[datetime] = None
    
    class Config:
        json_encoders = {datetime: lambda v: v.isoformat()}