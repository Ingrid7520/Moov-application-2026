from pydantic import BaseModel, Field
from datetime import datetime
from bson import ObjectId
from app.models.user import PyObjectId

class OTPBase(BaseModel):
    user_phone: str
    code: str
    expires_at: datetime
    is_used: bool = False

class OTPInDB(OTPBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}