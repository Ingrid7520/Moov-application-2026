#!/usr/bin/env python3
"""
Script de test pour la blockchain
"""
import sys
import asyncio
from pathlib import Path

sys.path.append(str(Path(__file__).parent.parent))

from app.services.blockchain_service import blockchain_service
from app.services.ipfs_service import ipfs_service
from app.database import connect_to_mongo, get_database, close_mongo_connection

async def test_blockchain():
    print("🧪 Test de l'intégration blockchain...")
    
    # 1. Test connexion blockchain
    print("\n1. Test connexion blockchain:")
    if blockchain_service.w3.is_connected():
        print("   ✅ Connecté à Polygon Mumbai")
        print(f"   📍 Dernier bloc: {blockchain_service.w3.eth.block_number}")
    else:
        print("   ❌ Non connecté")
        return
    
    # 2. Test IPFS
    print("\n2. Test IPFS:")
    try:
        test_data = {"test": "data", "timestamp": "now"}
        cid = await ipfs_service.upload_json(test_data)
        print(f"   ✅ IPFS fonctionnel - CID: {cid}")
        print(f"   🔗 URL: {ipfs_service.get_ipfs_url(cid)}")
    except Exception as e:
        print(f"   ❌ IPFS error: {e}")
        print("   ℹ️  WEB3_STORAGE_TOKEN peut être manquant")
    
    # 3. Test MongoDB
    print("\n3. Test MongoDB:")
    try:
        await connect_to_mongo()
        db = get_database()
        print(f"   ✅ Connecté à MongoDB: {db.name}")
        
        # Compter les traces
        count = db.product_traces.count_documents({})
        print(f"   📊 Traces existantes: {count}")
        
        await close_mongo_connection()
    except Exception as e:
        print(f"   ❌ MongoDB error: {e}")
    
    print("\n✅ Tests terminés!")

if __name__ == "__main__":
    asyncio.run(test_blockchain())