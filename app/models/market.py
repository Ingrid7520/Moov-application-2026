from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from bson import ObjectId
from enum import Enum

class MarketCity(str, Enum):
    ABIDJAN = "abidjan"
    BOUAKE = "bouake"
    YAMOUSSOUKRO = "yamoussoukro"
    SAN_PEDRO = "san_pedro"
    DALOA = "daloa"
    KORHOGO = "korhogo"
    MAN = "man"

class MarketPriceBase(BaseModel):
    product_type: str  # Référence à ProductType
    city: MarketCity
    market_name: str
    price_per_kg: float
    min_price: Optional[float] = None
    max_price: Optional[float] = None
    quality: str = "standard"  # standard, premium, etc.

class MarketPriceCreate(MarketPriceBase):
    source: str = "manual"  # manual, api, scraper

class MarketPriceInDB(MarketPriceBase):
    id: ObjectId = Field(default_factory=ObjectId, alias="_id")
    source: str
    date: datetime = Field(default_factory=datetime.utcnow)
    verified: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}

# Modèle pour les tendances de prix
class PriceTrend(BaseModel):
    product_type: str
    city: MarketCity
    current_price: float
    weekly_change: float  # Pourcentage de changement
    monthly_change: float
    trend: str  # "up", "down", "stable"
    last_updated: datetime