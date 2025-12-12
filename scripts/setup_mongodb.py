import pymongo
import sys
from pathlib import Path
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient

# Configuration MongoDB
MONGODB_URL = "mongodb://localhost:27017"
DATABASE_NAME = "agrismart_db"

COLLECTIONS = [
    "users",
    "otp_codes", 
    "products",
    "transactions",
    "market_prices",
    "weather_data",
    "chat_messages",
    "blockchain_logs"
]

def setup_database_sync():
    """Configuration synchrone de la base de données"""
    print("🔄 Configuration de MongoDB...")
    
    # Connexion
    client = pymongo.MongoClient(MONGODB_URL)
    
    # Tester la connexion
    try:
        client.admin.command('ping')
        print("✅ Connecté à MongoDB!")
    except Exception as e:
        print(f"❌ Erreur de connexion: {e}")
        return False
    
    # Obtenir ou créer la base de données
    db = client[DATABASE_NAME]
    print(f"📂 Base de données: '{DATABASE_NAME}'")
    
    # Créer les collections si elles n'existent pas
    existing_collections = db.list_collection_names()
    
    for collection_name in COLLECTIONS:
        if collection_name not in existing_collections:
            db.create_collection(collection_name)
            print(f"   ✅ Collection '{collection_name}' créée")
        else:
            print(f"   ⚡ Collection '{collection_name}' existe déjà")
    
    # Créer les index
    print("\n📊 Création des index...")
    
    # Index pour users
    db.users.create_index("phone_number", unique=True)
    db.users.create_index("created_at")
    print("   ✅ Index pour 'users' créés")
    
    # Index pour otp_codes avec TTL (expiration après 1h)
    db.otp_codes.create_index("expires_at", expireAfterSeconds=3600)
    db.otp_codes.create_index([("user_phone", 1), ("created_at", -1)])
    print("   ✅ Index pour 'otp_codes' créés (TTL 1h)")
    
    # Index pour products
    db.products.create_index([("owner_id", 1), ("created_at", -1)])
    db.products.create_index("product_type")
    print("   ✅ Index pour 'products' créés")
    
    # Index pour transactions
    db.transactions.create_index("transaction_id", unique=True)
    db.transactions.create_index([("buyer_id", 1), ("seller_id", 1)])
    print("   ✅ Index pour 'transactions' créés")
    
    # Afficher les statistiques
    print("\n📈 Statistiques:")
    for collection_name in COLLECTIONS:
        count = db[collection_name].count_documents({})
        print(f"   {collection_name}: {count} documents")
    
    client.close()
    print("\n🎉 Configuration terminée avec succès!")
    return True

async def setup_database_async():
    """Configuration asynchrone de la base de données"""
    print("🔄 Configuration asynchrone de MongoDB...")
    
    client = AsyncIOMotorClient(MONGODB_URL)
    
    try:
        await client.admin.command('ping')
        print("✅ Connecté à MongoDB!")
    except Exception as e:
        print(f"❌ Erreur de connexion: {e}")
        return False
    
    db = client[DATABASE_NAME]
    
    # Créer les collections
    existing_collections = await db.list_collection_names()
    
    for collection_name in COLLECTIONS:
        if collection_name not in existing_collections:
            await db.create_collection(collection_name)
    
    # Créer les index
    await db.users.create_index("phone_number", unique=True)
    await db.users.create_index("created_at")
    
    await db.otp_codes.create_index("expires_at", expireAfterSeconds=3600)
    await db.otp_codes.create_index([("user_phone", 1), ("created_at", -1)])
    
    await client.close()
    print("✅ Configuration asynchrone terminée!")
    return True

if __name__ == "__main__":
    print("=" * 50)
    print("SETUP DATABASE AGRISMART CI")
    print("=" * 50)
    
    # Essayer la méthode synchrone
    if setup_database_sync():
        print("\n✅ Base de données prête pour AgriSmart CI!")
        print(f"\n🔗 URL: {MONGODB_URL}/{DATABASE_NAME}")
        print("📋 Collections créées:")
        for coll in COLLECTIONS:
            print(f"   - {coll}")
    else:
        print("\n❌ Échec de la configuration. Vérifie que:")
        print("   1. MongoDB est en cours d'exécution")
        print("   2. L'URL est correcte: mongodb://localhost:27017")
        print("   3. MongoDB Compass est connecté")