# app/api/blockchain.py
"""
API endpoints pour la blockchain
Vérification et traçabilité des transactions
"""

from fastapi import APIRouter, Depends, HTTPException
from motor.motor_asyncio import AsyncIOMotorDatabase
import logging

from app.database import get_database
from app.services.blockchain_simulation import BlockchainSimulationService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/blockchain", tags=["Blockchain"])


@router.get("/verify/{transaction_id}")
async def verify_transaction(
    transaction_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Vérifier l'intégrité d'une transaction sur la blockchain
    
    Retourne:
    - verified: bool (true si la transaction est valide)
    - transaction_hash: Hash de la transaction
    - block_info: Informations du bloc (si miné)
    - confirmations: Nombre de confirmations
    """
    try:
        blockchain_service = BlockchainSimulationService(db)
        result = await blockchain_service.verify_transaction(transaction_id)
        
        if result["status"] == "error":
            raise HTTPException(status_code=404, detail=result["message"])
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur vérification: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/trace/{transaction_id}")
async def get_transaction_trace(
    transaction_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Récupérer la trace complète d'une transaction
    
    Inclut:
    - Détails de la transaction
    - Hash blockchain
    - Informations du bloc
    - Horodatage
    """
    try:
        blockchain_service = BlockchainSimulationService(db)
        result = await blockchain_service.get_transaction_trace(transaction_id)
        
        if result["status"] == "error":
            raise HTTPException(status_code=404, detail=result["message"])
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Erreur trace: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/stats")
async def get_blockchain_stats(
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Statistiques globales de la blockchain
    
    Retourne:
    - total_blocks: Nombre total de blocs
    - total_transactions: Nombre total de transactions
    - pending_transactions: Transactions en attente de minage
    - last_block: Informations du dernier bloc
    """
    try:
        blockchain_service = BlockchainSimulationService(db)
        result = await blockchain_service.get_blockchain_stats()
        
        if result["status"] == "error":
            raise HTTPException(status_code=500, detail=result["message"])
        
        return result
        
    except Exception as e:
        logger.error(f"❌ Erreur stats: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/mine-block")
async def mine_block(
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Force le minage d'un nouveau bloc
    
    Utile pour les tests ou pour miner les transactions en attente
    """
    try:
        blockchain_service = BlockchainSimulationService(db)
        result = await blockchain_service._mine_block()
        
        if result:
            return {
                "status": "success",
                "message": "Bloc miné avec succès",
                "block": result
            }
        else:
            return {
                "status": "info",
                "message": "Aucune transaction en attente"
            }
        
    except Exception as e:
        logger.error(f"❌ Erreur minage: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))