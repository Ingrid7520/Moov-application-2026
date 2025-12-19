# app/models/notification.py
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum

class NotificationType(str, Enum):
    PAYMENT_SUCCESS = "payment_success"
    PAYMENT_FAILED = "payment_failed"
    DIAGNOSTIC_COMPLETE = "diagnostic_complete"
    PRODUCT_SOLD = "product_sold"
    NEW_MESSAGE = "new_message"
    SYSTEM = "system"

class NotificationPriority(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"

class NotificationCreate(BaseModel):
    user_id: str = Field(..., description="ID de l'utilisateur destinataire")
    type: NotificationType = Field(..., description="Type de notification")
    title: str = Field(..., min_length=1, max_length=100)
    message: str = Field(..., min_length=1, max_length=500)
    priority: NotificationPriority = Field(NotificationPriority.MEDIUM)
    data: Optional[dict] = Field(None, description="Données supplémentaires (JSON)")

class NotificationResponse(BaseModel):
    id: str
    user_id: str
    type: str
    title: str
    message: str
    priority: str
    data: Optional[dict] = None
    is_read: bool = False
    created_at: datetime
    read_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True
        json_encoders = {datetime: lambda v: v.isoformat()}