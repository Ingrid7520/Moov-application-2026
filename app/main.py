# app/main.py
# ✅ VERSION COMPLÈTE avec Notifications + Images
from fastapi import FastAPI, HTTPException, status, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from typing import List, Optional
import logging
from datetime import datetime
from app.api import diagnostic

# Import nos modules
from app.config import settings
from app.database import mongodb, get_database
from app.utils.error_logger import MongoChatLogHandler
from app.services.chat_history_service import ChatHistoryService
import sys
import pydantic

# Import des routeurs
from app.api import test as test_router
from app.api import blockchain as blockchain_router
from app.api import auth as auth_router
from app.api import payment as payment_router
from app.api import products as products_router
from app.api import chat_history as chat_history_router
from app.api import notifications as notifications_router  # ✅ NOUVEAU

# Import des modèles
from app.models import (
    ProductCreate, ProductUpdate, TransactionCreate,
    UserResponse, ProductResponse, TransactionResponse,
    MarketPriceResponse, WeatherResponse,
    UserType, ProductType, ProductStatus, TransactionStatus
)
from app.core.dependencies import get_current_active_user, get_current_user
from app.core.security import create_access_token

logger = logging.getLogger(__name__)

# ============================================
# GESTION DU CYCLE DE VIE
# ============================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestion du cycle de vie de l'application"""
    # Startup
    logger.info("🚀 Démarrage d'AgriSmart CI avec MongoDB...")
    
    try:
        await mongodb.connect()
        logger.info("✅ MongoDB connecté avec succès")
        
        db = mongodb.get_database()
        
        # ✅ Index chat_conversations
        await db.chat_conversations.create_index([("user_id", 1), ("updated_at", -1)])
        await db.chat_conversations.create_index([("user_id", 1), ("session_id", 1)])
        await db.chat_conversations.create_index([("is_archived", 1)])
        logger.info("✅ Index MongoDB créés pour chat_conversations")
        
        # ✅ Index notifications (NOUVEAU)
        await db.notifications.create_index([("user_id", 1), ("created_at", -1)])
        await db.notifications.create_index([("is_read", 1)])
        await db.notifications.create_index([("user_id", 1), ("is_read", 1)])
        logger.info("✅ Index MongoDB créés pour notifications")
        
        # ✅ Index products (pour performances)
        await db.products.create_index([("owner_id", 1)])
        await db.products.create_index([("status", 1)])
        await db.products.create_index([("product_type", 1)])
        await db.products.create_index([("created_at", -1)])
        logger.info("✅ Index MongoDB créés pour products")
        
        # Installer handler de logs
        try:
            root_logger = logging.getLogger()
            handler = MongoChatLogHandler(user_id="system", session_id="system_logs", level=logging.WARNING)
            formatter = logging.Formatter('%(levelname)s: %(message)s (%(name)s:%(lineno)d)')
            handler.setFormatter(formatter)
            root_logger.addHandler(handler)
            import warnings
            warnings.filterwarnings('default')
            logging.captureWarnings(True)
            logger.info("✅ MongoChatLogHandler installé")
        except Exception as e:
            logger.exception("Impossible d'installer MongoChatLogHandler")

        # Message démarrage Python 3.14+
        try:
            if sys.version_info >= (3, 14):
                info_msg = (
                    f"Startup: Python {sys.version} detected. "
                    f"Pydantic version: {getattr(pydantic, '__version__', 'unknown')}."
                )
                logger.warning(info_msg)

                try:
                    chat_service = ChatHistoryService(db)
                    await chat_service.log_error(
                        user_id="system",
                        session_id="system_startup",
                        error_message=info_msg,
                        severity="info"
                    )
                except Exception:
                    logger.exception("Impossible de sauvegarder le message de démarrage")
        except Exception:
            logger.exception("Erreur lors de l'envoi du message de démarrage")
        
    except Exception as e:
        logger.error(f"❌ Erreur lors de la connexion à MongoDB: {e}")
        raise
    
    yield
    
    # Shutdown
    logger.info("🛑 Arrêt de l'application...")
    await mongodb.disconnect()
    logger.info("✅ Application arrêtée proprement")

# ============================================
# APPLICATION FASTAPI
# ============================================

app = FastAPI(
    title="AgriSmart CI API",
    description="API Backend pour l'assistant agricole intelligent avec MongoDB",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================
# INCLUSION DES ROUTEURS
# ============================================

app.include_router(test_router.router)
app.include_router(blockchain_router.router)
app.include_router(auth_router.router)
app.include_router(payment_router.router)
app.include_router(products_router.router)
app.include_router(chat_history_router.router)
app.include_router(notifications_router.router) 
app.include_router(diagnostic.router)

# ============================================
# UTILITAIRES
# ============================================

def to_objectid(id_str: str) -> ObjectId:
    """Convertir un string en ObjectId MongoDB"""
    try:
        return ObjectId(id_str)
    except:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="ID invalide"
        )

def serialize_mongo_document(doc) -> dict:
    """Sérialiser un document MongoDB"""
    if not doc:
        return None
    
    doc["id"] = str(doc["_id"])
    doc.pop("_id", None)
    return doc

# ============================================
# ENDPOINTS UTILISATEURS
# ============================================

@app.get("/api/auth/me", response_model=UserResponse)
async def get_me(
    current_user: dict = Depends(get_current_active_user)
):
    """Obtenir les informations de l'utilisateur connecté"""
    return UserResponse(**serialize_mongo_document(current_user))

@app.get("/api/users/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Obtenir les informations d'un utilisateur"""
    user = await db.users.find_one({"_id": to_objectid(user_id)})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utilisateur non trouvé"
        )
    return UserResponse(**serialize_mongo_document(user))

@app.get("/api/users", response_model=List[UserResponse])
async def get_users(
    user_type: Optional[UserType] = None,
    limit: int = 100,
    skip: int = 0,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Lister les utilisateurs avec filtres"""
    query = {}
    if user_type:
        query["user_type"] = user_type.value
    
    cursor = db.users.find(query).skip(skip).limit(limit)
    users = await cursor.to_list(length=limit)
    return [UserResponse(**serialize_mongo_document(user)) for user in users]

# ============================================
# ENDPOINTS SANTÉ ET STATS
# ============================================

@app.get("/")
async def root():
    return {
        "message": "🌱 Bienvenue sur AgriSmart CI API avec MongoDB",
        "version": "1.0.0",
        "status": "operational",
        "database": "MongoDB",
        "features": {
            "authentication": True,
            "products": True,
            "payments": True,
            "blockchain": True,
            "chat_history": True,
            "notifications": True,  # ✅ NOUVEAU
            "images": True  # ✅ NOUVEAU
        },
        "documentation": "/docs",
        "health": "/health"
    }

@app.get("/health")
async def health_check(db: AsyncIOMotorDatabase = Depends(get_database)):
    try:
        await db.command("ping")
        
        collections = await db.list_collection_names()
        
        return {
            "status": "healthy",
            "database": "connected",
            "collections": {
                "users": "users" in collections,
                "products": "products" in collections,
                "transactions": "transactions" in collections,
                "chat_conversations": "chat_conversations" in collections,
                "notifications": "notifications" in collections  # ✅ NOUVEAU
            }
        }
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}