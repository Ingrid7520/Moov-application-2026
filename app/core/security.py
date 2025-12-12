# app/core/security.py
from datetime import datetime, timedelta
from typing import Optional
import jwt
from jwt import PyJWTError
from passlib.context import CryptContext
from app.config import settings
import logging

logger = logging.getLogger(__name__)

# Crypt context pour le hachage des mots de passe
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Configuration JWT
SECRET_KEY = settings.SECRET_KEY
ALGORITHM = settings.ALGORITHM
ACCESS_TOKEN_EXPIRE_MINUTES = settings.ACCESS_TOKEN_EXPIRE_MINUTES

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Vérifier un mot de passe"""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """Hacher un mot de passe"""
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Créer un token JWT"""
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire, "iat": datetime.utcnow()})
    
    try:
        encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
        return encoded_jwt
    except PyJWTError as e:
        logger.error(f"Erreur lors de la création du token JWT: {e}")
        raise

def decode_access_token(token: str) -> Optional[dict]:
    """Décoder et valider un token JWT"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except PyJWTError as e:
        logger.error(f"Erreur lors du décodage du token JWT: {e}")
        return None

def verify_access_token(token: str) -> Optional[dict]:
    """Vérifier un token JWT"""
    return decode_access_token(token)