from fastapi import APIRouter, Depends, HTTPException
from app.database import get_db
from app.services.blockchain_service import blockchain_service
from typing import Optional
from datetime import datetime
from bson import ObjectId

# Ajouter cette fonction à ton router existant
router = APIRouter()

@router.post("/{product_id}/register-blockchain")
async def register_product_on_blockchain(
    product_id: str,
    farmer_id: str,
    db = Depends(get_db)
):
    """
    Enregistre un produit existant sur la blockchain
    """
    # 1. Récupérer le produit depuis MongoDB
    product = db.products.find_one({"_id": ObjectId(product_id)})
    
    if not product:
        raise HTTPException(status_code=404, detail="Produit non trouvé")
    
    # 2. Préparer les données pour la blockchain
    product_data = {
        "product_name": product.get("name", ""),
        "crop_type": product.get("crop_type", ""),
        "quantity": product.get("quantity", 0),
        "location": product.get("location", ""),
        "original_data": product  # Inclure toutes les données originales
    }
    
    # 3. Enregistrer sur la blockchain
    result = await blockchain_service.register_product_with_mongo(
        db=db,
        farmer_id=farmer_id,
        product_ref=product_id,  # Référence au produit original
        product_data=product_data
    )
    
    # 4. Mettre à jour le produit avec la référence blockchain
    if result and result.get("success"):
        db.products.update_one(
            {"_id": ObjectId(product_id)},
            {"$set": {
                "blockchain_trace_id": result.get("blockchain_product_id"),
                "blockchain_tx_hash": result.get("tx_hash"),
                "updated_at": datetime.utcnow()
            }}
        )
    
    return result