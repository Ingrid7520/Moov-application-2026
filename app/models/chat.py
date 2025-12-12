from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from bson import ObjectId
from enum import Enum

class PyObjectId(str):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v):
        if not isinstance(v, (str, ObjectId)):
            raise TypeError(f"string or ObjectId required (got type: {type(v)})")
        return str(v)

class MessageType(str, Enum):
    TEXT = "text"
    IMAGE = "image"
    FILE = "file"
    PRODUCT_LINK = "product_link"
    LOCATION = "location"

class ChatBase(BaseModel):
    participant_ids: List[str]  # IDs des participants
    product_id: Optional[str] = None  # Si lié à un produit

class ChatCreate(ChatBase):
    initial_message: Optional[str] = None

class ChatInDB(ChatBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    last_message: Optional[str] = None
    last_message_at: Optional[datetime] = None
    unread_count: dict = Field(default_factory=dict)  # {user_id: count}
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}

class MessageBase(BaseModel):
    chat_id: str
    sender_id: str
    content: str
    message_type: MessageType = MessageType.TEXT

class MessageCreate(MessageBase):
    pass

class MessageInDB(MessageBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    read_by: List[str] = []  # IDs des utilisateurs qui ont lu
    delivered: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}