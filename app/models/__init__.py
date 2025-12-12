# app/models/__init__.py
from pydantic import BaseModel, Field, field_validator, EmailStr, ConfigDict
from typing import Optional, List
from datetime import datetime
from enum import Enum
import re

# ============================================
# ENUMS
# ============================================

class UserType(str, Enum):
    PRODUCER = "producer"
    BUYER = "buyer"
    BOTH = "both"

class ProductType(str, Enum):
    COCOA = "cocoa"
    CASHEW = "cashew"
    CASSAVA = "cassava"
    COFFEE = "coffee"
    RICE = "rice"
    CORN = "corn"
    OTHER = "other"

class ProductStatus(str, Enum):
    AVAILABLE = "available"
    RESERVED = "reserved"
    SOLD = "sold"

class TransactionStatus(str, Enum):
    PENDING = "pending"
    PAID = "paid"
    CONFIRMED = "confirmed"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"

# ============================================
# MODÈLES DE REQUÊTE
# ============================================

class PhoneValidator:
    @staticmethod
    def validate_phone(phone: str) -> str:
        cleaned = re.sub(r'\s+', '', phone)
        if not re.match(r'^(\+?225|0)[0-9]{10}$|^[0-9]{10}$', cleaned):
            raise ValueError('Format de numéro invalide. Utilisez +225XXXXXXXXXX')
        return cleaned

class RegisterRequest(BaseModel):
    phone_number: str = Field(..., description="Numéro de téléphone")
    name: str = Field(..., min_length=2, max_length=100)
    user_type: UserType = Field(..., description="Rôle de l'utilisateur (producer, buyer, ou both)")
    location: Optional[str] = Field(None, max_length=200)
    email: Optional[EmailStr] = None
    
    @field_validator('phone_number')
    @classmethod
    def validate_phone(cls, v):
        return PhoneValidator.validate_phone(v)

class VerifyRequest(BaseModel):
    phone_number: str
    code: str = Field(..., min_length=6, max_length=6)
    
    @field_validator('phone_number')
    @classmethod
    def validate_phone(cls, v):
        return PhoneValidator.validate_phone(v)

class LoginRequest(BaseModel):
    phone_number: str
    
    @field_validator('phone_number')
    @classmethod
    def validate_phone(cls, v):
        return PhoneValidator.validate_phone(v)

class ProductCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    product_type: ProductType
    quantity: float = Field(..., gt=0)
    price_per_kg: float = Field(..., gt=0)
    location: str
    description: Optional[str] = None
    images: List[str] = Field(default_factory=list)

class ProductUpdate(BaseModel):
    name: Optional[str] = None
    product_type: Optional[ProductType] = None
    quantity: Optional[float] = None
    price_per_kg: Optional[float] = None
    location: Optional[str] = None
    description: Optional[str] = None
    images: Optional[List[str]] = None
    status: Optional[ProductStatus] = None

class TransactionCreate(BaseModel):
    product_id: str
    quantity: float = Field(..., gt=0)
    delivery_address: Optional[str] = None
    notes: Optional[str] = None

# ============================================
# MODÈLES DE RÉPONSE
# ============================================

class UserResponse(BaseModel):
    model_config = ConfigDict(
        json_encoders={datetime: lambda v: v.isoformat()}
    )
    
    id: str
    phone_number: str
    name: str
    user_type: UserType
    location: Optional[str]
    email: Optional[str]
    is_verified: bool
    created_at: datetime
    updated_at: datetime

class ProductResponse(BaseModel):
    id: str
    name: str
    product_type: ProductType
    quantity: float
    price_per_kg: float
    location: str
    description: Optional[str]
    images: List[str]
    owner_id: str
    status: ProductStatus
    created_at: datetime
    updated_at: datetime

class TransactionResponse(BaseModel):
    id: str
    product_id: str
    seller_id: str
    buyer_id: str
    quantity: float
    unit_price: float
    total_amount: float
    status: TransactionStatus
    delivery_address: Optional[str]
    notes: Optional[str]
    created_at: datetime
    updated_at: datetime

class MarketPriceResponse(BaseModel):
    id: str
    product: str
    city: str
    market: str
    price_per_kg: float
    unit: str = "FCFA"
    quality: str
    trend: str
    last_updated: datetime

class WeatherResponse(BaseModel):
    location: str
    date: datetime
    current: dict
    forecast: List[dict]
    alerts: List[dict]
    agricultural_advice: List[str]

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

# ============================================
# MODÈLES POUR LA BASE DE DONNÉES
# ============================================

class UserInDB(BaseModel):
    phone_number: str
    name: str
    user_type: UserType
    location: Optional[str]
    email: Optional[str]
    is_verified: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class ProductInDB(BaseModel):
    name: str
    product_type: ProductType
    quantity: float
    price_per_kg: float
    location: str
    description: Optional[str]
    images: List[str]
    owner_id: str
    status: ProductStatus = ProductStatus.AVAILABLE
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class TransactionInDB(BaseModel):
    product_id: str
    seller_id: str
    buyer_id: str
    quantity: float
    unit_price: float
    total_amount: float
    status: TransactionStatus = TransactionStatus.PENDING
    delivery_address: Optional[str]
    notes: Optional[str]
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class MarketPriceInDB(BaseModel):
    product: str
    city: str
    market: str
    price_per_kg: float
    unit: str = "FCFA"
    quality: str
    trend: str
    last_updated: datetime = Field(default_factory=datetime.utcnow)

class WeatherInDB(BaseModel):
    location: str
    date: datetime = Field(default_factory=datetime.utcnow)
    data: dict
    created_at: datetime = Field(default_factory=datetime.utcnow)

__all__ = [
    "UserType",
    "ProductType",
    "ProductStatus",
    "TransactionStatus",
    "RegisterRequest",
    "VerifyRequest",
    "LoginRequest",
    "ProductCreate",
    "ProductUpdate",
    "TransactionCreate",
    "UserResponse",
    "ProductResponse",
    "TransactionResponse",
    "MarketPriceResponse",
    "WeatherResponse",
    "TokenResponse",
    "UserInDB",
    "ProductInDB",
    "TransactionInDB",
    "MarketPriceInDB",
    "WeatherInDB",
    "ProductTrace",
    "BlockchainEvent",
]