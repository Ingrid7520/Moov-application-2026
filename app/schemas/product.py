# app/schemas/product.py
from pydantic import BaseModel, Field
from typing import Optional
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
    OTHER = "other"

class QualityGrade(str, Enum):
    GRADE_A = "A"
    GRADE_B = "B"
    GRADE_C = "C"
    ORGANIC = "organic"

class ProductCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    product_type: ProductType
    quantity: float = Field(..., gt=0)
    unit_price: float = Field(..., gt=0)
    location: str
    description: Optional[str] = None
    harvest_date: Optional[datetime] = None
    quality_grade: QualityGrade = QualityGrade.GRADE_B
