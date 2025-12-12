from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from bson import ObjectId
from enum import Enum

from app.models.user import PyObjectId

class WeatherAlertType(str, Enum):
    RAIN = "rain"
    FLOOD = "flood"
    DROUGHT = "drought"
    HEATWAVE = "heatwave"
    STORM = "storm"

class WeatherDataBase(BaseModel):
    location: str  # Coordonnées ou nom de localité
    temperature: float  # en °C
    humidity: int  # Pourcentage
    precipitation: float  # en mm
    wind_speed: float  # en km/h
    condition: str  # soleil, pluie, nuageux, etc.

class WeatherDataCreate(WeatherDataBase):
    pass

class WeatherDataInDB(WeatherDataBase):
    id: PyObjectId = Field(default_factory=PyObjectId, alias="_id")
    recorded_at: datetime = Field(default_factory=datetime.utcnow)
    forecast_date: Optional[datetime] = None  # Pour les prévisions
    is_forecast: bool = False
    source: str = "api"
    
    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}

class WeatherAlert(BaseModel):
    alert_type: WeatherAlertType
    location: str
    severity: str  # low, medium, high
    message: str
    start_time: datetime
    end_time: Optional[datetime] = None
    recommended_action: Optional[str] = None