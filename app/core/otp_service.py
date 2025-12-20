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
    
    logger.info(f"🔐 OTP généré pour {phone_number}: {code}")
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
        logger.info(f"✅ OTP vérifié avec succès pour {phone_number}")
        return True
    
    logger.warning(f"❌ OTP invalide ou expiré pour {phone_number}")
    return False


async def send_otp_sms(phone_number: str, code: str) -> bool:
    """Envoyer un code OTP par SMS via Africa's Talking"""
    message = (
        f"Votre code de vérification AgriSmart CI est: {code}. "
        f"Valide pour {settings.OTP_EXPIRE_MINUTES} minutes."
    )
    
    try:
        success = await send_sms_async(phone_number, message)
        if success:
            logger.info(f"📱 SMS OTP envoyé à {phone_number}")
        else:
            logger.error(f"❌ Échec d'envoi SMS à {phone_number}")
        return success
    except Exception as e:
        logger.error(f"❌ Erreur lors de l'envoi du SMS: {e}")
        return False


# ============================================================================
# 🆕 NOUVELLE FONCTION : Récupérer le dernier OTP valide
# ============================================================================
async def get_latest_otp(db: AsyncIOMotorDatabase, phone_number: str) -> str | None:
    """
    Récupère le dernier code OTP valide et non utilisé pour un numéro.
    
    Cette fonction est destinée au développement et aux tests.
    
    ⚠️ EN PRODUCTION :
    - Désactivez cette route dans les endpoints publics
    - OU sécurisez-la avec un token admin
    - OU utilisez-la uniquement pour les tests automatisés
    
    Args:
        db: Instance de la base de données MongoDB
        phone_number: Numéro de téléphone de l'utilisateur
        
    Returns:
        Le code OTP s'il existe, None sinon
    """
    try:
        # Chercher le dernier OTP valide non utilisé
        otp = await db.otp_codes.find_one(
            {
                "phone_number": phone_number,
                "is_used": False,
                "expires_at": {"$gt": datetime.utcnow()}
            },
            sort=[("created_at", -1)]  # Tri décroissant pour avoir le plus récent
        )
        
        if otp:
            logger.info(f"🔍 OTP trouvé pour {phone_number}: {otp['code']}")
            return otp["code"]
        
        logger.warning(f"⚠️ Aucun OTP valide trouvé pour {phone_number}")
        return None
        
    except Exception as e:
        logger.error(f"❌ Erreur lors de la récupération de l'OTP: {e}")
        return None


async def cleanup_expired_otps(db: AsyncIOMotorDatabase) -> int:
    """
    Nettoie les codes OTP expirés de la base de données.
    
    Cette fonction peut être appelée périodiquement (par exemple via un cron job)
    pour maintenir la base de données propre.
    
    Returns:
        Nombre de codes OTP supprimés
    """
    try:
        result = await db.otp_codes.delete_many({
            "expires_at": {"$lt": datetime.utcnow()}
        })
        
        deleted_count = result.deleted_count
        if deleted_count > 0:
            logger.info(f"🧹 {deleted_count} codes OTP expirés supprimés")
        
        return deleted_count
        
    except Exception as e:
        logger.error(f"❌ Erreur lors du nettoyage des OTP: {e}")
        return 0


async def get_otp_stats(db: AsyncIOMotorDatabase, phone_number: str) -> dict:
    """
    Récupère des statistiques sur les OTP d'un utilisateur.
    
    Utile pour le monitoring et le debugging.
    
    Returns:
        Dictionnaire contenant:
        - total: Nombre total d'OTP générés
        - used: Nombre d'OTP utilisés
        - expired: Nombre d'OTP expirés
        - active: Nombre d'OTP valides non utilisés
    """
    try:
        now = datetime.utcnow()
        
        # Total OTP générés
        total = await db.otp_codes.count_documents({
            "phone_number": phone_number
        })
        
        # OTP utilisés
        used = await db.otp_codes.count_documents({
            "phone_number": phone_number,
            "is_used": True
        })
        
        # OTP expirés (non utilisés et périmés)
        expired = await db.otp_codes.count_documents({
            "phone_number": phone_number,
            "is_used": False,
            "expires_at": {"$lt": now}
        })
        
        # OTP actifs (non utilisés et valides)
        active = await db.otp_codes.count_documents({
            "phone_number": phone_number,
            "is_used": False,
            "expires_at": {"$gt": now}
        })
        
        return {
            "phone_number": phone_number,
            "total": total,
            "used": used,
            "expired": expired,
            "active": active
        }
        
    except Exception as e:
        logger.error(f"❌ Erreur lors de la récupération des stats OTP: {e}")
        return {
            "phone_number": phone_number,
            "total": 0,
            "used": 0,
            "expired": 0,
            "active": 0,
            "error": str(e)
        }


async def resend_otp(
    db: AsyncIOMotorDatabase,
    phone_number: str,
    force_new: bool = False
) -> tuple[str, bool]:
    """
    Renvoie un code OTP (soit le dernier valide, soit en génère un nouveau).
    
    Args:
        db: Instance de la base de données
        phone_number: Numéro de téléphone
        force_new: Si True, génère toujours un nouveau code même si un valide existe
        
    Returns:
        Tuple (code, is_new) où:
        - code: Le code OTP
        - is_new: True si nouveau code généré, False si code existant renvoyé
    """
    try:
        # Si force_new est False, vérifier s'il existe déjà un OTP valide
        if not force_new:
            existing_otp = await db.otp_codes.find_one(
                {
                    "phone_number": phone_number,
                    "is_used": False,
                    "expires_at": {"$gt": datetime.utcnow()}
                },
                sort=[("created_at", -1)]
            )
            
            if existing_otp:
                code = existing_otp["code"]
                logger.info(f"♻️ Renvoi du code OTP existant pour {phone_number}")
                await send_otp_sms(phone_number, code)
                return code, False
        
        # Générer un nouveau code
        code = await create_otp(db, phone_number)
        await send_otp_sms(phone_number, code)
        logger.info(f"🆕 Nouveau code OTP généré et envoyé pour {phone_number}")
        return code, True
        
    except Exception as e:
        logger.error(f"❌ Erreur lors du renvoi de l'OTP: {e}")
        raise