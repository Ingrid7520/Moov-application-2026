# scripts/init_mongodb.py
import asyncio
import sys
from pathlib import Path

# Ajouter le chemin du projet
sys.path.append(str(Path(__file__).parent.parent))

from motor.motor_asyncio import AsyncIOMotorClient
from app.config import settings
from datetime import datetime

async def init_database():
    """Initialiser la base de données MongoDB"""
    print("🚀 Initialisation de la base de données AgriSmart CI...")
    
    client = AsyncIOMotorClient(settings.MONGODB_URL)
    
    try:
        await client.admin.command('ping')
        print("✅ Connecté à MongoDB")
    except Exception as e:
        print(f"❌ Erreur de connexion: {e}")
        return
    
    db = client[settings.MONGODB_DATABASE]
    
    # Créer les collections
    collections = [
        "users", "products", "transactions", 
        "market_prices", "weather_data", "diseases"
    ]
    
    existing = await db.list_collection_names()
    
    for coll in collections:
        if coll not in existing:
            await db.create_collection(coll)
            print(f"📁 Collection '{coll}' créée")
    
    # Créer les index
    print("\n📊 Création des index...")
    
    # Users
    await db.users.create_index("phone_number", unique=True)
    await db.users.create_index("user_type")
    await db.users.create_index("created_at")
    
    # Products
    await db.products.create_index("owner_id")
    await db.products.create_index("product_type")
    await db.products.create_index("status")
    await db.products.create_index([("location", "text")])
    
    # Transactions
    await db.transactions.create_index("buyer_id")
    await db.transactions.create_index("seller_id")
    await db.transactions.create_index("status")
    await db.transactions.create_index("created_at")
    
    # Market prices
    await db.market_prices.create_index([("product", 1), ("city", 1)])
    await db.market_prices.create_index("last_updated")
    
    print("✅ Index créés")
    
    # Ajouter des données de démo
    await add_demo_data(db)
    
    print("\n🎉 Base de données initialisée avec succès!")
    print(f"📋 Collections: {len(collections)}")
    print(f"🔗 URL: {settings.MONGODB_URL}/{settings.MONGODB_DATABASE}")
    
    await client.close()

async def add_demo_data(db):
    """Ajouter des données de démo"""
    
    # Vérifier si des données existent déjà
    users_count = await db.users.count_documents({})
    if users_count == 0:
        # Ajouter des utilisateurs de démo
        demo_users = [
            {
                "phone_number": "+2250700000001",
                "name": "Jean Koffi",
                "user_type": "producer",
                "location": "Abidjan, Yopougon",
                "email": "jean.koffi@example.com",
                "is_verified": True,
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            },
            {
                "phone_number": "+2250700000002",
                "name": "Marie Traoré",
                "user_type": "buyer",
                "location": "Bouaké",
                "email": "marie.traore@example.com",
                "is_verified": True,
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            },
            {
                "phone_number": "+2250700000003",
                "name": "Pierre Koné",
                "user_type": "both",
                "location": "Korhogo",
                "email": "pierre.kone@example.com",
                "is_verified": True,
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            }
        ]
        
        await db.users.insert_many(demo_users)
        print(f"👥 {len(demo_users)} utilisateurs de démo ajoutés")
    
    # Ajouter des prix de marché de démo
    market_prices_count = await db.market_prices.count_documents({})
    if market_prices_count == 0:
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
                "product": "cashew",
                "city": "Korhogo",
                "market": "Marché Central",
                "price_per_kg": 1200,
                "unit": "FCFA",
                "quality": "premium",
                "trend": "up",
                "last_updated": datetime.utcnow()
            }
        ]
        
        await db.market_prices.insert_many(demo_prices)
        print(f"💰 {len(demo_prices)} prix de marché ajoutés")

# Ajoute cette fonction pour tester Africa's Talking
async def test_sms_service():
    """Tester le service SMS"""
    from app.utils.sms import send_sms_sync
    from app.config import settings
    
    print("\n📱 Test du service SMS...")
    
    if settings.AT_USERNAME == "your_sandbox_username":
        print("   ⚠️  Mode développement: SMS simulés")
        print("   Pour utiliser Africa's Talking, configure ton .env:")
        print("   AT_USERNAME=ton_username_sandbox")
        print("   AT_API_KEY=ta_clé_api_sandbox")
    else:
        test_number = "+2250700000000"  # Numéro de test
        test_message = "Test AgriSmart CI - Service SMS opérationnel!"
        
        success = send_sms_sync(test_number, test_message)
        if success:
            print("   ✅ SMS de test envoyé (vérifie ton téléphone)")
        else:
            print("   ❌ Échec d'envoi SMS")

if __name__ == "__main__":
    asyncio.run(init_database())