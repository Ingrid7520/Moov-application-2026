# app/core/otp_service.py
import random
import string
from datetime import datetime, timedelta
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from app.config import settings
from app.utils.sms import send_sms_async
import logging

logger = logging.getLogger(__name__)

def generate_otp_code() -> str:
    """Générer un code OTP de 6 chiffres"""
    return ''.join(random.choices(string.digits, k=settings.OTP_LENGTH))

async def create_otp(db: AsyncIOMotorDatabase, phone_number: str) -> str:
    """Créer et stocker un code OTP"""
    # Invalider les anciens OTP non utilisés
    await db.otp_codes.update_many(
        {
            "phone_number": phone_number,
            "is_used": False,
            "expires_at": {"$gt": datetime.utcnow()}
        },
        {"$set": {"is_used": True}}
    )
    
    # Générer un nouveau code
    code = generate_otp_code()
    expires_at = datetime.utcnow() + timedelta(minutes=settings.OTP_EXPIRE_MINUTES)
    
    # Stocker le code
    otp_data = {
        "phone_number": phone_number,
        "code": code,
        "is_used": False,
        "expires_at": expires_at,
        "created_at": datetime.utcnow()
    }
    
    await db.otp_codes.insert_one(otp_data)
    
    logger.info(f"OTP généré pour {phone_number}: {code}")
    return code

async def verify_otp(db: AsyncIOMotorDatabase, phone_number: str, code: str) -> bool:
    """Vérifier un code OTP"""
    otp = await db.otp_codes.find_one({
        "phone_number": phone_number,
        "code": code,
        "is_used": False,
        "expires_at": {"$gt": datetime.utcnow()}
    })
    
    if otp:
        # Marquer comme utilisé
        await db.otp_codes.update_one(
            {"_id": otp["_id"]},
            {"$set": {"is_used": True, "used_at": datetime.utcnow()}}
        )
        return True
    
    return False

async def send_otp_sms(phone_number: str, code: str) -> bool:
    """Envoyer un code OTP par SMS via Africa's Talking"""
    message = f"Votre code de vérification AgriSmart CI est: {code}. Valide pour {settings.OTP_EXPIRE_MINUTES} minutes."
    
    try:
        success = await send_sms_async(phone_number, message)
        if success:
            logger.info(f"SMS OTP envoyé à {phone_number}")
        else:
            logger.error(f"Échec d'envoi SMS à {phone_number}")
        return success
    except Exception as e:
        logger.error(f"Erreur lors de l'envoi du SMS: {e}")
        return False