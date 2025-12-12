# app/core/dependencies.py
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.database import get_database
from app.core.security import verify_access_token
from bson import ObjectId
import logging

logger = logging.getLogger(__name__)

# Schéma d'authentification Bearer
security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Obtenir l'utilisateur courant depuis le token JWT"""
    
    token = credentials.credentials
    
    # Vérifier le token
    payload = verify_access_token(token)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalide ou expiré",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Récupérer l'ID utilisateur
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalide",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Récupérer l'utilisateur depuis MongoDB
    try:
        user = await db.users.find_one({"_id": ObjectId(user_id)})
    except:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Utilisateur non trouvé",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utilisateur non trouvé"
        )
    
    if not user.get("is_verified", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Compte non vérifié"
        )
    
    return user

async def get_current_active_user(
    current_user: dict = Depends(get_current_user)
):
    """Vérifier que l'utilisateur est actif"""
    if not current_user.get("is_active", True):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Compte désactivé"
        )
    return current_user

def require_roles(allowed_roles: list):
    """Décorateur pour vérifier les rôles"""
    async def role_checker(current_user: dict = Depends(get_current_active_user)):
        user_role = current_user.get("user_type")
        if user_role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Permissions insuffisantes"
            )
        return current_user
    return role_checker