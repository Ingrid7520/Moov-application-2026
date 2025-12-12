from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from bson import ObjectId
from enum import Enum

from app.models.user import PyObjectId

class ProductType(str, Enum):
    COCOA = "cocoa"           # Cacao
    CASHEW = "cashew"         # Anacarde
    CASSAVA = "cassava"       # Manioc
    COFFEE = "coffee"         # Café
    RICE = "rice"             # Riz
    CORN = "corn"             # Maïs
    VEGETABLE = "vegetable"   # Légumes
    FRUIT = "fruit"           # Fruits
    OTHER = "other"

class ProductStatus(str, Enum):
    AVAILABLE = "available"      # Disponible à la vente
    RESERVED = "reserved"       # Réservé
    SOLD = "sold"              # Vendu
    HARVESTED = "harvested"    # Récolté (pas encore en vente)

class QualityGrade(str, Enum):
    GRADE_A = "A"      # Meilleure qualité
    GRADE_B = "B"      # Bonne qualité
    GRADE_C = "C"      # Qualité standard
    ORGANIC = "organic" # Biologique

class ProductBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    product_type: ProductType
    description: Optional[str] = None
    quantity: float = Field(..., gt=0)  # en kg
    unit_price: float = Field(..., gt=0)  # prix par kg
    location: str  # Lieu de production
    harvest_date: datetime
    expiration_date: Optional[datetime] = None
    quality_grade: QualityGrade = QualityGrade.GRADE_B
    certification: Optional[str] = None  # Bio, équitable, etc.
    images: List[str] = []  # URLs des images

class ProductCreate(ProductBase):
    owner_id: str  # ID du producteur

class ProductUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    quantity: Optional[float] = None
    unit_price: Optional[float] = None
    status: Optional[ProductStatus] = None
    quality_grade: Optional[QualityGrade] = None

class ProductInDB(ProductBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    owner_id: str
    status: ProductStatus = ProductStatus.AVAILABLE
    views: int = 0
    favorite_count: int = 0
    blockchain_hash: Optional[str] = None  # Hash de la transaction blockchain
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}