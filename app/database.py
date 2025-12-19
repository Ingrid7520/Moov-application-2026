# app/database.py
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo import MongoClient
from app.config import settings
import logging

logger = logging.getLogger(__name__)

class MongoDB:
    """Classe pour gérer la connexion MongoDB"""
    
    client: AsyncIOMotorClient = None
    sync_client: MongoClient = None
    
    async def connect(self):
        """Connecter à MongoDB"""
        try:
            self.client = AsyncIOMotorClient(settings.MONGODB_URL)
            self.sync_client = MongoClient(settings.MONGODB_URL)
            
            # Tester la connexion
            await self.client.admin.command('ping')
            logger.info(f"✅ Connecté à MongoDB: {settings.MONGODB_URL}")
            logger.info(f"📂 Base de données: {settings.MONGODB_DATABASE}")
            
            # Initialiser la base de données
            await self.initialize_database()
            
        except Exception as e:
            logger.error(f"❌ Erreur de connexion MongoDB: {e}")
            raise
    
    async def disconnect(self):
        """Déconnecter de MongoDB"""
        if self.client:
            self.client.close()
            self.sync_client.close()
            logger.info("✅ Déconnecté de MongoDB")
    
    async def initialize_database(self):
        """Initialiser la base de données avec les collections et index"""
        db = self.get_database()
        
        # Collections nécessaires
        collections = ["users", "products", "transactions", "market_prices", "weather_data", "otp_codes", "diagnostics"]
        
        existing_collections = await db.list_collection_names()
        
        for collection_name in collections:
            if collection_name not in existing_collections:
                await db.create_collection(collection_name)
                logger.info(f"📁 Collection créée: {collection_name}")
        
        # Créer les index
        await self.create_indexes(db)
    
    async def create_indexes(self, db):
        """Créer les index nécessaires"""
        # Index pour users
        await db.users.create_index("phone_number", unique=True)
        await db.users.create_index("created_at")
        
        # Index pour products
        await db.products.create_index("owner_id")
        await db.products.create_index("product_type")
        await db.products.create_index("status")
        
        # Index pour transactions
        await db.transactions.create_index("buyer_id")
        await db.transactions.create_index("seller_id")
        await db.transactions.create_index("status")
        
        # Index pour otp_codes avec TTL (expiration automatique après 1h)
        await db.otp_codes.create_index("expires_at", expireAfterSeconds=3600)
        await db.otp_codes.create_index("phone_number")
        await db.otp_codes.create_index("created_at")

        logger.info("✅ Index créés")
    
    def get_database(self):
        """Obtenir la base de données"""
        if not self.client:
            raise RuntimeError("MongoDB non connecté")
        return self.client[settings.MONGODB_DATABASE]
    
    def get_sync_database(self):
        """Obtenir la base de données synchrone"""
        if not self.sync_client:
            raise RuntimeError("MongoDB sync client non connecté")
        return self.sync_client[settings.MONGODB_DATABASE]

# Instance globale
mongodb = MongoDB()

async def get_database():
    """Dépendance FastAPI pour obtenir la base de données"""
    db = mongodb.get_database()
    try:
        yield db
    finally:
        pass