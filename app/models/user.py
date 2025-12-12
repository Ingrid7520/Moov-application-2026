from pydantic import BaseModel, Field, EmailStr, validator
from typing import Optional, List
from datetime import datetime
from bson import ObjectId
from enum import Enum

class PyObjectId(ObjectId):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate
    
    @classmethod
    def validate(cls, v):
        if not ObjectId.is_valid(v):
            raise ValueError("Invalid ObjectId")
        return ObjectId(v)
    
    @classmethod
    def __get_pydantic_json_schema__(cls, core_schema, handler):
        # Pydantic v2 replacement for the removed `__modify_schema__` hook.
        # Represent ObjectId as a string in JSON schema.
        return {"type": "string"}

class UserType(str, Enum):
    PRODUCER = "producer"      # Producteur
    BUYER = "buyer"           # Acheteur
    BOTH = "both"             # Les deux
    ADMIN = "admin"           # Administrateur

class UserStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"

class UserBase(BaseModel):
    phone_number: str = Field(..., description="Numéro de téléphone ivoirien")
    name: str = Field(..., min_length=2, max_length=100)
    email: Optional[EmailStr] = None
    user_type: UserType = UserType.PRODUCER
    location: Optional[str] = Field(None, max_length=200)
    region: Optional[str] = None  # Région en Côte d'Ivoire
    profile_picture: Optional[str] = None
    language: str = "fr"

class UserCreate(UserBase):
    password: Optional[str] = None  # Pour futur authentification par mot de passe

class UserUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    location: Optional[str] = None
    region: Optional[str] = None
    profile_picture: Optional[str] = None
    language: Optional[str] = None

class UserInDB(UserBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    is_verified: bool = False
    status: UserStatus = UserStatus.ACTIVE
    rating: float = Field(default=0.0, ge=0.0, le=5.0)  # Note de réputation
    total_transactions: int = 0
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    last_login: Optional[datetime] = None
    
    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}

class UserResponse(UserBase):
    id: str = Field(..., alias="_id")
    is_verified: bool
    status: UserStatus
    rating: float
    total_transactions: int
    created_at: datetime
    updated_at: datetime
    
    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}