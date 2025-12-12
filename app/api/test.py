"""
Endpoints de test pour vérifier et déboguer la plateforme AgriSmart.
Utiliser ces endpoints pour tester l'inscription OTP, la vérification et les diagnostics.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.database import get_database
from app.models import RegisterRequest, VerifyRequest, UserResponse
from app.core.otp_service import create_otp, verify_otp, send_otp_sms
from app.core.security import create_access_token
from app.utils.sms import get_sms_demo_data
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/test", tags=["test"])


@router.post("/register-with-otp", response_model=dict, summary="Tester l'inscription avec OTP")
async def test_register_with_otp(
    request: RegisterRequest,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Endpoint de test pour enregistrement avec envoi OTP.
    
    Le code OTP est inclus dans la réponse en mode sandbox/démo.
    
    **Exemple de request:**
    ```json
    {
        "phone_number": "+2250719378709",
        "name": "Test User",
        "user_type": "producer",
        "location": "Abidjan"
    }
    ```
    
    **Réponse:**
    ```json
    {
        "message": "Compte créé avec succès. Code OTP envoyé.",
        "phone_number": "+2250719378709",
        "user_id": "...",
        "sms_sent": true,
        "test_otp": "123456",
        "otp_expires_in_minutes": 5
    }
    ```
    """
    
    # Vérifier si l'utilisateur existe déjà
    existing_user = await db.users.find_one({"phone_number": request.phone_number})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Un compte existe déjà pour {request.phone_number}. Utilise /api/test/cleanup-and-register pour réenregistrer."
        )
    
    # Créer l'utilisateur (sans password, uniquement avec OTP)
    user_data = {
        "phone_number": request.phone_number,
        "name": request.name,
        "user_type": request.user_type.value,
        "location": request.location,
        "email": request.email,
        "is_verified": False,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    result = await db.users.insert_one(user_data)
    user_id = str(result.inserted_id)
    
    # Créer et envoyer OTP
    otp_code = await create_otp(db, request.phone_number)
    sms_sent = await send_otp_sms(request.phone_number, otp_code)
    
    logger.info(f"✅ Utilisateur enregistré: {request.phone_number} (ID: {user_id}), Type: {request.user_type}")
    
    return {
        "message": "Compte créé avec succès. Code OTP envoyé.",
        "phone_number": request.phone_number,
        "user_id": user_id,
        "sms_sent": sms_sent,
        "test_otp": otp_code,  # En sandbox/démo : OTP visible pour les tests
        "otp_expires_in_minutes": 5
    }


@router.post("/cleanup-and-register", response_model=dict, summary="Supprimer l'utilisateur et réenregistrer")
async def cleanup_and_register(
    request: RegisterRequest,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Endpoint de test pour supprimer un utilisateur existant et le réenregistrer.
    
    Utile pour tester les flux multiples fois avec le même numéro.
    
    **Exemple de request:**
    ```json
    {
        "phone_number": "+2250719378709",
        "name": "Test User",
        "user_type": "producer"
    }
    ```
    """
    
    # Supprimer l'utilisateur existant et ses OTP
    await db.users.delete_one({"phone_number": request.phone_number})
    await db.otp_codes.delete_many({"phone_number": request.phone_number})
    
    logger.info(f"🗑️ Utilisateur nettoyé: {request.phone_number}")
    
    # Réenregistrer
    user_data = {
        "phone_number": request.phone_number,
        "name": request.name,
        "user_type": request.user_type.value,
        "location": request.location,
        "email": request.email,
        "is_verified": False,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    result = await db.users.insert_one(user_data)
    user_id = str(result.inserted_id)
    
    # Créer et envoyer OTP
    otp_code = await create_otp(db, request.phone_number)
    sms_sent = await send_otp_sms(request.phone_number, otp_code)
    
    logger.info(f"✅ Utilisateur réenregistré: {request.phone_number} (ID: {user_id}), Type: {request.user_type}")
    
    return {
        "message": "Utilisateur nettoyé et réenregistré. Code OTP envoyé.",
        "phone_number": request.phone_number,
        "user_id": user_id,
        "sms_sent": sms_sent,
        "test_otp": otp_code,
        "otp_expires_in_minutes": 5,
        "note": "L'utilisateur précédent a été supprimé"
    }


@router.post("/verify-otp", response_model=dict, summary="Vérifier le code OTP et obtenir un token")
async def test_verify_otp(
    request: VerifyRequest,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Endpoint de test pour vérifier l'OTP et obtenir un JWT token.
    
    **Exemple de request:**
    ```json
    {
        "phone_number": "+2250719378709",
        "code": "123456"
    }
    ```
    
    **Réponse:**
    ```json
    {
        "message": "Vérification réussie",
        "access_token": "eyJhbGc...",
        "token_type": "bearer",
        "user": {
            "phone_number": "+2250719378709",
            "name": "Test User",
            "user_type": "producer",
            "is_verified": true
        }
    }
    ```
    """
    
    # Vérifier l'OTP
    is_valid = await verify_otp(db, request.phone_number, request.code)
    
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code OTP invalide ou expiré"
        )
    
    # Marquer l'utilisateur comme vérifié
    await db.users.update_one(
        {"phone_number": request.phone_number},
        {
            "$set": {
                "is_verified": True,
                "updated_at": datetime.utcnow()
            }
        }
    )
    
    # Récupérer l'utilisateur
    user = await db.users.find_one({"phone_number": request.phone_number})
    
    # Créer le token
    access_token = create_access_token(
        data={"sub": request.phone_number},
        expires_delta=timedelta(minutes=10080)
    )
    
    logger.info(f"✅ OTP vérifié et token créé: {request.phone_number}")
    
    return {
        "message": "Vérification réussie",
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "phone_number": user["phone_number"],
            "name": user["name"],
            "user_type": user["user_type"],
            "is_verified": user["is_verified"]
        }
    }


@router.get("/sms-history", response_model=dict, summary="Voir l'historique des SMS en sandbox")
async def test_sms_history():
    """
    Endpoint de test pour visualiser l'historique des SMS envoyés en mode sandbox/simulation.
    
    **Utile pour déboguer les envois SMS sans avoir à regarder les fichiers.**
    
    **Réponse:**
    ```json
    {
        "mode": "sandbox",
        "total_sms": 5,
        "recent_sms": [
            {
                "timestamp": "2025-12-11T10:30:45.123456",
                "phone": "+2250719378709",
                "message": "Votre code de vérification AgriSmart CI est: 123456. Valide pour 5 minutes.",
                "status": "sent"
            }
        ]
    }
    ```
    """
    
    sms_logs = get_sms_demo_data()
    
    return {
        "mode": "sandbox/demo",
        "total_sms": len(sms_logs),
        "recent_sms": sms_logs[-10:] if sms_logs else []
    }


@router.delete("/cleanup-all-test-data", response_model=dict, summary="Nettoyer toutes les données de test")
async def cleanup_all_test_data(
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Endpoint de test pour supprimer tous les utilisateurs et OTP (nettoyage complet).
    
    ⚠️ **Attention**: Cette action supprime TOUS les utilisateurs et codes OTP.
    """
    
    users_deleted = await db.users.delete_many({})
    otps_deleted = await db.otp_codes.delete_many({})
    
    logger.warning(f"🗑️ Nettoyage complet: {users_deleted.deleted_count} utilisateurs, {otps_deleted.deleted_count} OTP supprimés")
    
    return {
        "message": "Toutes les données de test ont été supprimées",
        "users_deleted": users_deleted.deleted_count,
        "otps_deleted": otps_deleted.deleted_count
    }


@router.get("/db-status", response_model=dict, summary="Vérifier le statut de la base de données")
async def check_db_status(
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Endpoint de test pour vérifier la connexion à MongoDB et les collections.
    
    **Réponse:**
    ```json
    {
        "database": "agrismart_db",
        "connected": true,
        "collections": ["users", "otp_codes", ...],
        "stats": {
            "users_count": 5,
            "otp_codes_count": 3
        }
    }
    ```
    """
    
    try:
        # Vérifier la connexion
        await db.command("ping")
        connected = True
    except Exception as e:
        logger.error(f"❌ Erreur de connexion DB: {e}")
        connected = False
    
    # Compter les collections
    collections = await db.list_collection_names()
    
    users_count = await db.users.count_documents({})
    otps_count = await db.otp_codes.count_documents({})
    
    return {
        "database": "agrismart_db",
        "connected": connected,
        "collections": collections,
        "stats": {
            "users_count": users_count,
            "otp_codes_count": otps_count
        }
    }
