#!/usr/bin/env python3
"""
Script pour initialiser les collections blockchain dans MongoDB
"""
import sys
from pathlib import Path

# Ajouter le chemin du projet
sys.path.append(str(Path(__file__).parent.parent))

from app.database import connect_to_mongo, get_database, close_mongo_connection
import asyncio

async def init_collections():
    """Initialise les collections et indexes"""
    print("🔧 Initialisation des collections blockchain...")
    
    await connect_to_mongo()
    db = get_database()
    
    # Collection: product_traces
    if "product_traces" not in db.list_collection_names():
        print("📁 Création de la collection 'product_traces'...")
    
    # Indexes pour product_traces
    db.product_traces.create_index("blockchain_product_id", unique=True, sparse=True)
    db.product_traces.create_index("tx_hash", unique=True, sparse=True)
    db.product_traces.create_index("farmer_id")
    db.product_traces.create_index("product_ref")
    db.product_traces.create_index("created_at")
    
    print("✅ Indexes créés pour 'product_traces'")
    
    # Collection: blockchain_events
    if "blockchain_events" not in db.list_collection_names():
        print("📁 Création de la collection 'blockchain_events'...")
    
    db.blockchain_events.create_index("tx_hash", unique=True)
    db.blockchain_events.create_index([("processed", 1), ("block_number", 1)])
    db.blockchain_events.create_index("created_at")
    
    print("✅ Indexes créés pour 'blockchain_events'")
    
    # Vérifier le compte
    print(f"\n📊 Collections disponibles: {db.list_collection_names()}")
    
    await close_mongo_connection()
    print("\n✅ Initialisation terminée!")

if __name__ == "__main__":
    asyncio.run(init_collections())