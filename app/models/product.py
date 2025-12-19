# app/models/product.py
# ✅ VERSION AVEC SUPPORT IMAGES
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum

class ProductType(str, Enum):
    COCOA = "cocoa"
    CASHEW = "cashew"
    CASSAVA = "cassava"
    COFFEE = "coffee"
    RICE = "rice"
    CORN = "corn"
    VEGETABLE = "vegetable"
    FRUIT = "fruit"
    PLANTAIN = "plantain"
    YAMS = "yams"
    PEANUT = "peanut"
    COTTON = "cotton"
    OTHER = "other"

class ProductStatus(str, Enum):
    AVAILABLE = "available"
    RESERVED = "reserved"
    SOLD = "sold"
    HARVESTED = "harvested"

class QualityGrade(str, Enum):
    GRADE_A = "A"
    GRADE_B = "B"
    GRADE_C = "C"
    ORGANIC = "organic"

class ProductBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100, description="Nom du produit")
    product_type: ProductType = Field(..., description="Type de produit")
    description: Optional[str] = Field(None, max_length=500, description="Description du produit")
    quantity: float = Field(..., gt=0, description="Quantité en kg")
    unit_price: float = Field(..., gt=0, description="Prix par kg en FCFA")
    location: str = Field(..., min_length=2, max_length=100, description="Lieu de production")
    harvest_date: Optional[datetime] = Field(None, description="Date de récolte")
    quality_grade: Optional[QualityGrade] = Field(QualityGrade.GRADE_B, description="Grade de qualité")

class ProductCreate(ProductBase):
    """Schéma pour créer un nouveau produit"""
    images: Optional[List[str]] = Field(None, description="Liste d'images en base64 (max 5 images, 5MB chacune)")

class ProductUpdate(BaseModel):
    """Schéma pour mettre à jour un produit"""
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    quantity: Optional[float] = Field(None, gt=0)
    unit_price: Optional[float] = Field(None, gt=0)
    status: Optional[ProductStatus] = None
    quality_grade: Optional[QualityGrade] = None
    images: Optional[List[str]] = Field(None, description="Nouvelles images (remplace les anciennes)")

class ProductResponse(BaseModel):
    """Schéma de réponse pour un produit"""
    id: str
    name: str
    product_type: str
    description: Optional[str] = None
    quantity: float
    unit_price: float
    location: str
    harvest_date: Optional[datetime] = None
    quality_grade: str
    owner_id: str
    owner_name: Optional[str] = None
    owner_phone: Optional[str] = None
    status: str
    images: List[str] = []  # ✅ NOUVEAU: Liste d'images base64
    views: int = 0
    favorite_count: int = 0
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
        json_encoders = {datetime: lambda v: v.isoformat()}