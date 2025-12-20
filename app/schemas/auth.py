# app/schemas/auth.py
from pydantic import BaseModel, Field, field_validator
from typing import Optional
import re

class PhoneNumber(BaseModel):
    phone_number: str = Field(..., description="Numéro de téléphone ivoirien")
    
    @field_validator('phone_number')
    @classmethod
    def validate_phone(cls, v):
        # Format ivoirien: +225XXXXXXXXXX ou 225XXXXXXXXXX ou 0XXXXXXXXX
        cleaned = re.sub(r'\s+', '', v)
        if not re.match(r'^(\+?225|0)[0-9]{10}$|^[0-9]{10}$', cleaned):
            raise ValueError('Format de numéro invalide. Utilisez +225XXXXXXXXXX')
        return cleaned

class RegisterRequest(PhoneNumber):
    name: str = Field(..., min_length=2, max_length=100)
    user_type: str = Field(..., description="Rôle de l'utilisateur (producer, buyer, ou both)")
    location: Optional[str] = Field(None, max_length=200)

class VerifyOTPRequest(PhoneNumber):
    code: str = Field(..., min_length=6, max_length=6)

class LoginRequest(PhoneNumber):
    pass

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

# 🆕 NOUVEAU SCHÉMA
class GetOTPRequest(PhoneNumber):
    """Requête pour récupérer le code OTP (dev/test uniquement)"""
    pass