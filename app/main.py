# app/main.py
from fastapi import FastAPI, HTTPException, status, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from typing import List, Optional
import uuid
import logging
from app.core.security import create_access_token, get_password_hash
from app.core.otp_service import create_otp, verify_otp, send_otp_sms
from app.core.dependencies import get_current_user, get_current_active_user, require_roles
from bson import ObjectId

# Import nos modules
from app.config import settings
from app.database import mongodb, get_database
from app.models import (
    RegisterRequest, VerifyRequest, LoginRequest,
    ProductCreate, ProductUpdate, TransactionCreate,
    UserResponse, ProductResponse, TransactionResponse,
    TokenResponse, MarketPriceResponse, WeatherResponse,
    UserType, ProductType, ProductStatus, TransactionStatus
)
from app.api import test as test_router
from app.api import blockchain as blockchain_router

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
# ENDPOINTS D'AUTHENTIFICATION
# ============================================

@app.post("/api/auth/register", status_code=status.HTTP_201_CREATED)
async def register(
    request: RegisterRequest,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Inscription d'un nouvel utilisateur avec OTP"""
    
    # Vérifier si l'utilisateur existe déjà
    existing_user = await db.users.find_one({"phone_number": request.phone_number})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ce numéro est déjà enregistré"
        )
    
    # Préparer les données utilisateur
    user_data = {
        "phone_number": request.phone_number,
        "name": request.name,
        "user_type": request.user_type.value,
        "location": request.location,
        "email": request.email,
        "is_verified": False,
        "is_active": True,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    # Ajouter le hash du mot de passe si fourni
    if request.password:
        from app.core.security import get_password_hash
        user_data["password_hash"] = get_password_hash(request.password)
    
    # Créer l'utilisateur
    result = await db.users.insert_one(user_data)
    user_id = str(result.inserted_id)
    
    # Générer et envoyer l'OTP
    otp_code = await create_otp(db, request.phone_number)
    
    # Envoyer le SMS (mode développement si Africa's Talking n'est pas configuré)
    sms_sent = await send_otp_sms(request.phone_number, otp_code)
    
    response = {
        "message": "Compte créé avec succès. Code OTP envoyé.",
        "phone_number": request.phone_number,
        "user_id": user_id,
        "sms_sent": sms_sent
    }
    
    # En mode développement, inclure le code OTP
    if not sms_sent or settings.AT_USERNAME == "your_sandbox_username":
        response["test_otp"] = otp_code
    
    return response

@app.post("/api/auth/verify-otp", response_model=TokenResponse)
async def verify_otp_endpoint(
    request: VerifyRequest,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Vérification du code OTP et génération du token JWT"""
    
    # Vérifier le code OTP
    is_valid = await verify_otp(db, request.phone_number, request.code)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code OTP invalide ou expiré"
        )
    
    # Récupérer l'utilisateur
    user = await db.users.find_one({"phone_number": request.phone_number})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utilisateur non trouvé"
        )
    
    # Marquer comme vérifié
    await db.users.update_one(
        {"_id": user["_id"]},
        {"$set": {"is_verified": True, "updated_at": datetime.utcnow()}}
    )
    user["is_verified"] = True
    
    # Créer le token JWT
    access_token = create_access_token(
        data={
            "sub": str(user["_id"]),
            "phone": user["phone_number"],
            "name": user["name"],
            "user_type": user["user_type"]
        }
    )
    
    user_response = UserResponse(**serialize_mongo_document(user))
    
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user=user_response
    )

@app.post("/api/auth/login")
async def login(
    request: LoginRequest,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Connexion avec envoi d'OTP"""
    
    user = await db.users.find_one({"phone_number": request.phone_number})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utilisateur non trouvé. Veuillez vous inscrire."
        )
    
    # Vérifier si le compte est actif
    if not user.get("is_active", True):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Compte désactivé"
        )
    
    # Générer et envoyer l'OTP
    otp_code = await create_otp(db, request.phone_number)
    sms_sent = await send_otp_sms(request.phone_number, otp_code)
    
    response = {
        "message": "Code OTP envoyé",
        "phone_number": request.phone_number,
        "sms_sent": sms_sent
    }
    
    # En mode développement, inclure le code OTP
    if not sms_sent or settings.AT_USERNAME == "your_sandbox_username":
        response["test_otp"] = otp_code
    
    return response

@app.post("/api/auth/refresh")
async def refresh_token(
    current_user: dict = Depends(get_current_user)
):
    """Rafraîchir le token JWT"""
    
    access_token = create_access_token(
        data={
            "sub": str(current_user["_id"]),
            "phone": current_user["phone_number"],
            "name": current_user["name"],
            "user_type": current_user["user_type"]
        }
    )
    
    user_response = UserResponse(**serialize_mongo_document(current_user))
    
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        user=user_response
    )

@app.get("/api/auth/me", response_model=UserResponse)
async def get_me(
    current_user: dict = Depends(get_current_active_user)
):
    """Obtenir les informations de l'utilisateur connecté"""
    return UserResponse(**serialize_mongo_document(current_user))

# ============================================
# ENDPOINTS UTILISATEURS
# ============================================

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
# ENDPOINTS PRODUITS
# ============================================

@app.post("/api/products", status_code=status.HTTP_201_CREATED, response_model=ProductResponse)
async def create_product(
    product: ProductCreate,
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Créer un nouveau produit (authentification requise)"""
    
    product_data = {
        "name": product.name,
        "product_type": product.product_type.value,
        "quantity": product.quantity,
        "price_per_kg": product.price_per_kg,
        "location": product.location,
        "description": product.description,
        "images": product.images,
        "owner_id": str(current_user["_id"]),  # Utiliser l'ID réel de l'utilisateur
        "owner_phone": current_user["phone_number"],
        "owner_name": current_user["name"],
        "status": ProductStatus.AVAILABLE.value,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    result = await db.products.insert_one(product_data)
    
    # Récupérer le produit créé
    created_product = await db.products.find_one({"_id": result.inserted_id})
    
    return ProductResponse(**serialize_mongo_document(created_product))

@app.get("/api/products", response_model=List[ProductResponse])
async def get_products(
    product_type: Optional[ProductType] = None,
    status: Optional[ProductStatus] = None,
    location: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    limit: int = 50,
    skip: int = 0,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Lister les produits avec filtres"""
    
    query = {}
    
    if product_type:
        query["product_type"] = product_type.value
    
    if status:
        query["status"] = status.value
    
    if location:
        query["location"] = {"$regex": location, "$options": "i"}
    
    if min_price is not None or max_price is not None:
        query["price_per_kg"] = {}
        if min_price is not None:
            query["price_per_kg"]["$gte"] = min_price
        if max_price is not None:
            query["price_per_kg"]["$lte"] = max_price
    
    cursor = db.products.find(query).sort("created_at", -1).skip(skip).limit(limit)
    products = await cursor.to_list(length=limit)
    
    return [ProductResponse(**serialize_mongo_document(product)) for product in products]

@app.get("/api/products/{product_id}", response_model=ProductResponse)
async def get_product(
    product_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Obtenir un produit spécifique"""
    
    product = await db.products.find_one({"_id": to_objectid(product_id)})
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit non trouvé"
        )
    
    return ProductResponse(**serialize_mongo_document(product))

@app.get("/api/users/{user_id}/products", response_model=List[ProductResponse])
async def get_user_products(
    user_id: str,
    status: Optional[ProductStatus] = None,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Obtenir les produits d'un utilisateur"""
    
    query = {"owner_id": user_id}
    if status:
        query["status"] = status.value
    
    cursor = db.products.find(query).sort("created_at", -1)
    products = await cursor.to_list(length=100)
    
    return [ProductResponse(**serialize_mongo_document(product)) for product in products]

# ============================================
# ENDPOINTS TRANSACTIONS
# ============================================

@app.post("/api/transactions", status_code=status.HTTP_201_CREATED, response_model=TransactionResponse)
async def create_transaction(
    transaction: TransactionCreate,
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Créer une nouvelle transaction (authentification requise)"""
    
    # Récupérer le produit
    product = await db.products.find_one({"_id": to_objectid(transaction.product_id)})
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit non trouvé"
        )
    
    # Vérifier que l'acheteur n'est pas le vendeur
    if str(current_user["_id"]) == product["owner_id"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Vous ne pouvez pas acheter votre propre produit"
        )
    
    # Vérifier la disponibilité
    if product["status"] != ProductStatus.AVAILABLE.value:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Produit non disponible"
        )
    
    if transaction.quantity > product["quantity"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Quantité demandée supérieure à la quantité disponible"
        )
    
    transaction_data = {
        "product_id": transaction.product_id,
        "seller_id": product["owner_id"],
        "buyer_id": str(current_user["_id"]),
        "buyer_phone": current_user["phone_number"],
        "buyer_name": current_user["name"],
        "quantity": transaction.quantity,
        "unit_price": product["price_per_kg"],
        "total_amount": transaction.quantity * product["price_per_kg"],
        "status": TransactionStatus.PENDING.value,
        "delivery_address": transaction.delivery_address,
        "notes": transaction.notes,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    result = await db.transactions.insert_one(transaction_data)
    
    # Mettre à jour le statut du produit
    await db.products.update_one(
        {"_id": to_objectid(transaction.product_id)},
        {"$set": {"status": ProductStatus.RESERVED.value, "updated_at": datetime.utcnow()}}
    )
    
    # Récupérer la transaction créée
    created_transaction = await db.transactions.find_one({"_id": result.inserted_id})
    
    return TransactionResponse(**serialize_mongo_document(created_transaction))

@app.get("/api/transactions/{transaction_id}", response_model=TransactionResponse)
async def get_transaction(
    transaction_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Obtenir une transaction spécifique"""
    
    transaction = await db.transactions.find_one({"_id": to_objectid(transaction_id)})
    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction non trouvée"
        )
    
    return TransactionResponse(**serialize_mongo_document(transaction))

# ============================================
# ENDPOINTS MARCHÉ (PRIX)
# ============================================

@app.get("/api/market-prices", response_model=List[MarketPriceResponse])
async def get_market_prices(
    product: Optional[str] = None,
    city: Optional[str] = None,
    limit: int = 50,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Obtenir les prix du marché"""
    
    query = {}
    if product:
        query["product"] = {"$regex": product, "$options": "i"}
    if city:
        query["city"] = {"$regex": city, "$options": "i"}
    
    # Si la base est vide, ajouter des données de démo
    count = await db.market_prices.count_documents(query)
    if count == 0:
        await seed_market_prices(db)
    
    cursor = db.market_prices.find(query).sort("last_updated", -1).limit(limit)
    prices = await cursor.to_list(length=limit)
    
    return [MarketPriceResponse(**serialize_mongo_document(price)) for price in prices]

async def seed_market_prices(db):
    """Ajouter des données de démo pour les prix du marché"""
    demo_prices = [
        {
            "product": "cocoa",
            "city": "Abidjan",
            "market": "Marché de Marcory",
            "price_per_kg": 1500,
            "unit": "FCFA",
            "quality": "premium",
            "trend": "stable",
            "last_updated": datetime.utcnow()
        },
        {
            "product": "cocoa",
            "city": "Bouaké",
            "market": "Grand Marché",
            "price_per_kg": 1450,
            "unit": "FCFA",
            "quality": "standard",
            "trend": "up",
            "last_updated": datetime.utcnow()
        },
        {
            "product": "cashew",
            "city": "Korhogo",
            "market": "Marché Central",
            "price_per_kg": 1200,
            "unit": "FCFA",
            "quality": "premium",
            "trend": "stable",
            "last_updated": datetime.utcnow()
        },
        {
            "product": "cassava",
            "city": "Yamoussoukro",
            "market": "Marché du Plateau",
            "price_per_kg": 350,
            "unit": "FCFA",
            "quality": "standard",
            "trend": "down",
            "last_updated": datetime.utcnow()
        }
    ]
    
    await db.market_prices.insert_many(demo_prices)

# ============================================
# ENDPOINTS MÉTÉO
# ============================================

@app.get("/api/weather/{location}", response_model=WeatherResponse)
async def get_weather(
    location: str,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Obtenir les données météo pour une localité"""
    
    # Chercher dans la base de données
    weather_data = await db.weather_data.find_one(
        {"location": {"$regex": location, "$options": "i"}},
        sort=[("date", -1)]
    )
    
    # Si pas de données, créer des données de démo
    if not weather_data:
        weather_data = await create_demo_weather_data(db, location)
    
    return WeatherResponse(**serialize_mongo_document(weather_data))

async def create_demo_weather_data(db, location: str):
    """Créer des données météo de démo"""
    demo_data = {
        "location": location,
        "date": datetime.utcnow(),
        "data": {
            "current": {
                "temperature": 28.5,
                "humidity": 75,
                "condition": "partiellement nuageux",
                "condition_icon": "⛅",
                "precipitation_mm": 2.5,
                "wind_speed_kmh": 12,
                "wind_direction": "SE",
                "feels_like": 30.2
            },
            "forecast": [
                {
                    "day": "aujourd'hui",
                    "date": datetime.utcnow().strftime("%Y-%m-%d"),
                    "condition": "pluies éparses",
                    "max_temp": 29,
                    "min_temp": 24,
                    "rain_probability": 60
                }
            ],
            "alerts": [],
            "agricultural_advice": [
                "Bon moment pour l'irrigation",
                "Éviter les traitements chimiques aujourd'hui"
            ]
        },
        "created_at": datetime.utcnow()
    }
    
    result = await db.weather_data.insert_one(demo_data)
    demo_data["_id"] = result.inserted_id
    
    return demo_data

# ============================================
# ENDPOINTS DIAGNOSTIC MALADIES
# ============================================

@app.post("/api/diagnose")
async def diagnose_disease(request: dict):
    """Diagnostic de maladie des cultures par IA (simulé)"""
    
    # Pour l'instant, gardons la version simulée
    # Dans une vraie implémentation, on utiliserait un modèle IA
    
    crop_type = request.get("crop_type", "cocoa")
    
    diseases_knowledge = {
        "cocoa": [
            {
                "disease_id": "cocoa_1",
                "name": "Pourriture brune des cabosses",
                "confidence": 0.85,
                "severity": "high",
                "treatments": ["Fongicide à base de cuivre", "Bon drainage"]
            }
        ]
    }
    
    crop_diseases = diseases_knowledge.get(crop_type, [])
    
    return {
        "diagnosis_id": str(uuid.uuid4()),
        "crop_type": crop_type,
        "diagnosis_date": datetime.utcnow().isoformat(),
        "primary_diagnosis": crop_diseases[0] if crop_diseases else None,
        "alternative_diagnoses": crop_diseases[1:] if len(crop_diseases) > 1 else []
    }

# ============================================
# ENDPOINTS DE SANTÉ ET STATISTIQUES
# ============================================

@app.get("/")
async def root():
    return {
        "message": "🌱 Bienvenue sur AgriSmart CI API avec MongoDB",
        "version": "1.0.0",
        "status": "operational",
        "database": "MongoDB",
        "documentation": "/docs",
        "health": "/health"
    }

@app.get("/health")
async def health_check(db: AsyncIOMotorDatabase = Depends(get_database)):
    """Vérifier l'état de l'application et de la base de données"""
    
    try:
        # Tester la connexion MongoDB
        await db.command("ping")
        
        # Compter les documents
        users_count = await db.users.count_documents({})
        products_count = await db.products.count_documents({})
        transactions_count = await db.transactions.count_documents({})
        
        return {
            "status": "healthy",
            "timestamp": datetime.utcnow().isoformat(),
            "database": {
                "connected": True,
                "name": settings.MONGODB_DATABASE,
                "collections": {
                    "users": users_count,
                    "products": products_count,
                    "transactions": transactions_count
                }
            }
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "timestamp": datetime.utcnow().isoformat(),
            "database": {
                "connected": False,
                "error": str(e)
            }
        }

@app.get("/api/stats")
async def get_stats(db: AsyncIOMotorDatabase = Depends(get_database)):
    """Obtenir les statistiques de l'application"""
    
    # Aggrégations MongoDB
    users_by_type = await db.users.aggregate([
        {"$group": {"_id": "$user_type", "count": {"$sum": 1}}}
    ]).to_list(length=10)
    
    products_by_type = await db.products.aggregate([
        {"$group": {"_id": "$product_type", "count": {"$sum": 1}}}
    ]).to_list(length=10)
    
    transactions_by_status = await db.transactions.aggregate([
        {"$group": {"_id": "$status", "count": {"$sum": 1}}}
    ]).to_list(length=10)
    
    return {
        "timestamp": datetime.utcnow().isoformat(),
        "users": {
            "total": await db.users.count_documents({}),
            "by_type": {item["_id"]: item["count"] for item in users_by_type},
            "verified": await db.users.count_documents({"is_verified": True})
        },
        "products": {
            "total": await db.products.count_documents({}),
            "by_type": {item["_id"]: item["count"] for item in products_by_type},
            "available": await db.products.count_documents({"status": ProductStatus.AVAILABLE.value})
        },
        "transactions": {
            "total": await db.transactions.count_documents({}),
            "by_status": {item["_id"]: item["count"] for item in transactions_by_status},
            "total_volume": 0  # À calculer avec une agrégation plus complexe
        }
    }

# ============================================
# ENDPOINTS DELETE - UTILISATEURS
# ============================================

@app.delete("/api/users/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Supprimer un utilisateur"""
    
    result = await db.users.delete_one({"_id": to_objectid(user_id)})
    
    if result.deleted_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utilisateur non trouvé"
        )
    
    # Supprimer aussi les produits de l'utilisateur
    await db.products.delete_many({"owner_id": user_id})
    
    return None

# ============================================
# ENDPOINTS DELETE - PRODUITS
# ============================================

@app.delete("/api/products/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product(
    product_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Supprimer un produit"""
    
    # Vérifier si le produit existe
    product = await db.products.find_one({"_id": to_objectid(product_id)})
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit non trouvé"
        )
    
    # Vérifier s'il y a des transactions en cours
    active_transactions = await db.transactions.count_documents({
        "product_id": product_id,
        "status": {"$in": ["pending", "paid", "confirmed"]}
    })
    
    if active_transactions > 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Impossible de supprimer: transactions en cours"
        )
    
    # Supprimer le produit
    result = await db.products.delete_one({"_id": to_objectid(product_id)})
    
    if result.deleted_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit non trouvé"
        )
    
    # Annuler les transactions associées
    await db.transactions.update_many(
        {"product_id": product_id},
        {"$set": {"status": "cancelled", "updated_at": datetime.utcnow()}}
    )
    
    return None

# ============================================
# ENDPOINTS DELETE - TRANSACTIONS
# ============================================

@app.delete("/api/transactions/{transaction_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_transaction(
    transaction_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Annuler une transaction"""
    
    transaction = await db.transactions.find_one({"_id": to_objectid(transaction_id)})
    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction non trouvée"
        )
    
    # Vérifier si la transaction peut être annulée
    if transaction["status"] in ["delivered", "completed"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Transaction déjà livrée, impossible d'annuler"
        )
    
    # Marquer comme annulée
    result = await db.transactions.update_one(
        {"_id": to_objectid(transaction_id)},
        {"$set": {"status": "cancelled", "updated_at": datetime.utcnow()}}
    )
    
    if result.modified_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction non trouvée"
        )
    
    # Remettre le produit en vente si c'était réservé
    if transaction["status"] == "reserved":
        await db.products.update_one(
            {"_id": to_objectid(transaction["product_id"])},
            {"$set": {"status": "available", "updated_at": datetime.utcnow()}}
        )
    
    return None

# ============================================
# ENDPOINTS UPDATE - PRODUITS
# ============================================

@app.patch("/api/products/{product_id}", response_model=ProductResponse)
async def update_product(
    product_id: str,
    update: ProductUpdate,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Mettre à jour un produit"""
    
    # Vérifier si le produit existe
    product = await db.products.find_one({"_id": to_objectid(product_id)})
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit non trouvé"
        )
    
    # Préparer les mises à jour
    update_data = {}
    for field, value in update.dict(exclude_unset=True).items():
        if value is not None:
            if field == "status" and isinstance(value, ProductStatus):
                update_data[field] = value.value
            else:
                update_data[field] = value
    
    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Aucune donnée à mettre à jour"
        )
    
    update_data["updated_at"] = datetime.utcnow()
    
    # Mettre à jour
    result = await db.products.update_one(
        {"_id": to_objectid(product_id)},
        {"$set": update_data}
    )
    
    if result.modified_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit non trouvé"
        )
    
    # Récupérer le produit mis à jour
    updated_product = await db.products.find_one({"_id": to_objectid(product_id)})
    
    return ProductResponse(**serialize_mongo_document(updated_product))

# ============================================
# ENDPOINTS DÉMO SMS
# ============================================

@app.get("/api/demo/sms-history")
async def get_sms_history():
    """Obtenir l'historique des SMS pour la démo"""
    from app.utils.sms import get_sms_demo_data
    
    history = get_sms_demo_data()
    
    return {
        "count": len(history),
        "mode": "sandbox" if settings.AT_USERNAME != "your_sandbox_username" else "simulation",
        "sms_history": history[-10:],  # 10 derniers
        "total_sent": len([h for h in history if h.get("status") == "sent"]),
        "total_simulated": len([h for h in history if h.get("status") == "simulated"])
    }

@app.get("/api/demo/send-test-sms")
async def send_test_sms():
    """Envoyer un SMS de test pour la démo"""
    from app.utils.sms import send_sms_async
    
    test_number = "+2250719378709"  # Ton numéro
    test_message = "🔔 Test AgriSmart CI - Service SMS Opérationnel!"
    
    success = await send_sms_async(test_number, test_message)
    
    return {
        "success": success,
        "phone_number": test_number,
        "message": test_message,
        "mode": "sandbox" if settings.AT_USERNAME != "your_sandbox_username" else "simulation",
        "timestamp": datetime.utcnow().isoformat()
    }

# ============================================
# IMPORT MANQUANT
# ============================================

from datetime import datetime
from typing import Optional, List