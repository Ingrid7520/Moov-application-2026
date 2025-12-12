from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from bson import ObjectId
from enum import Enum

from app.models.user import PyObjectId

class TransactionStatus(str, Enum):
    PENDING = "pending"        # En attente de paiement
    PAID = "paid"             # Payé
    CONFIRMED = "confirmed"   # Confirmé par le vendeur
    SHIPPED = "shipped"       # Expédié
    DELIVERED = "delivered"   # Livré
    CANCELLED = "cancelled"   # Annulé
    DISPUTED = "disputed"     # Litige

class PaymentMethod(str, Enum):
    MOOV_MONEY = "moov_money"
    ORANGE_MONEY = "orange_money"
    WAVE = "wave"
    CASH = "cash"
    BANK_TRANSFER = "bank_transfer"

class TransactionBase(BaseModel):
    product_id: str
    seller_id: str
    buyer_id: str
    quantity: float
    unit_price: float
    total_amount: float
    delivery_address: Optional[str] = None
    delivery_date: Optional[datetime] = None
    notes: Optional[str] = None

class TransactionCreate(TransactionBase):
    payment_method: PaymentMethod

class TransactionUpdate(BaseModel):
    status: Optional[TransactionStatus] = None
    tracking_number: Optional[str] = None
    delivery_date: Optional[datetime] = None
    notes: Optional[str] = None

class TransactionInDB(TransactionBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    transaction_id: str = Field(..., unique=True)  # ID unique pour référence
    payment_method: PaymentMethod
    status: TransactionStatus = TransactionStatus.PENDING
    payment_reference: Optional[str] = None  # Référence de paiement Moov Money
    blockchain_hash: Optional[str] = None  # Hash blockchain
    tracking_number: Optional[str] = None
    rating_by_buyer: Optional[int] = Field(None, ge=1, le=5)
    rating_by_seller: Optional[int] = Field(None, ge=1, le=5)
    feedback_by_buyer: Optional[str] = None
    feedback_by_seller: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    completed_at: Optional[datetime] = None
    
    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}