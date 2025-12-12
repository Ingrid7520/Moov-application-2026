from web3 import Web3
import json
import time
import logging
from datetime import datetime
from typing import Dict, Any
from bson import ObjectId

from app.config import settings
from app.core.blockchain_config import get_web3_instance, get_contract_instance, get_account
from app.services.ipfs_service import ipfs_service

logger = logging.getLogger(__name__)

class BlockchainService:
    """Service blockchain adapté pour MongoDB"""
    
    def __init__(self):
        self.w3 = get_web3_instance()
        self.contract = get_contract_instance(self.w3)
        self.account = get_account()
    
    async def register_product(
        self, 
        farmer_id: str,
        product_ref: str = None,
        product_data: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """Enregistre un produit sur la blockchain et MongoDB"""
        
        if product_data is None:
            product_data = {}
        
        # 1. Upload sur IPFS
        logger.info("Upload des données sur IPFS...")
        
        # Préparer les données pour IPFS
        ipfs_data = {
            **product_data,
            "farmer_id": farmer_id,
            "product_ref": product_ref,
            "registered_at": datetime.utcnow().isoformat(),
            "system": "AgriSmart CI"
        }
        
        ipfs_cid = await ipfs_service.upload_json(ipfs_data)
        
        # 2. Générer un ID unique pour la blockchain
        import hashlib
        unique_string = f"{farmer_id}{ipfs_cid}{int(time.time())}"
        blockchain_product_id = int(hashlib.sha256(unique_string.encode()).hexdigest()[:8], 16)
        
        # 3. Envoyer sur la blockchain
        logger.info(f"Enregistrement sur blockchain: ID {blockchain_product_id}")
        
        try:
            # Estimer le gas
            gas_estimate = self.contract.functions.registerProduct(
                blockchain_product_id,
                ipfs_cid
            ).estimate_gas({'from': self.account.address})
            
            # Construire la transaction
            tx = self.contract.functions.registerProduct(
                blockchain_product_id,
                ipfs_cid
            ).build_transaction({
                'from': self.account.address,
                'nonce': self.w3.eth.get_transaction_count(self.account.address),
                'gas': gas_estimate + 50000,
                'gasPrice': self.w3.eth.gas_price,
                'chainId': settings.CHAIN_ID
            })
            
            # Signer et envoyer
            signed_tx = self.w3.eth.account.sign_transaction(tx, settings.PRIVATE_KEY)
            tx_hash = self.w3.eth.send_raw_transaction(signed_tx.rawTransaction)
            tx_hash_hex = tx_hash.hex()
            
            # Attendre la confirmation
            receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash, timeout=60)
            
            return {
                "success": True,
                "blockchain_product_id": blockchain_product_id,
                "ipfs_cid": ipfs_cid,
                "tx_hash": tx_hash_hex,
                "block_number": receipt.blockNumber,
                "ipfs_url": ipfs_service.get_ipfs_url(ipfs_cid)
            }
            
        except Exception as e:
            logger.error(f"Erreur blockchain: {e}")
            return {
                "success": False,
                "error": str(e),
                "blockchain_product_id": blockchain_product_id,
                "ipfs_cid": ipfs_cid
            }
    
    def save_to_mongodb(
        self, 
        db, 
        farmer_id: str,
        blockchain_result: Dict[str, Any],
        product_ref: str = None,
        product_data: Dict[str, Any] = None
    ) -> str:
        """Sauvegarde la trace dans MongoDB"""
        
        if product_data is None:
            product_data = {}
        
        trace_document = {
            "product_ref": product_ref,
            "farmer_id": farmer_id,
            "blockchain_product_id": blockchain_result["blockchain_product_id"],
            "ipfs_cid": blockchain_result["ipfs_cid"],
            "tx_hash": blockchain_result.get("tx_hash"),
            "block_number": blockchain_result.get("block_number"),
            "metadata": {
                **product_data,
                "ipfs_url": ipfs_service.get_ipfs_url(blockchain_result["ipfs_cid"]),
                "blockchain_status": "success" if blockchain_result["success"] else "failed"
            },
            "status": "registered",
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        result = db.product_traces.insert_one(trace_document)
        return str(result.inserted_id)
    
    async def register_product_with_mongo(
        self,
        db,
        farmer_id: str,
        product_ref: str = None,
        product_data: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """Processus complet: blockchain + MongoDB"""
        
        # 1. Enregistrer sur blockchain
        blockchain_result = await self.register_product(
            farmer_id=farmer_id,
            product_ref=product_ref,
            product_data=product_data
        )
        
        # 2. Sauvegarder dans MongoDB
        mongo_id = None
        if blockchain_result["success"]:
            mongo_id = self.save_to_mongodb(
                db=db,
                farmer_id=farmer_id,
                blockchain_result=blockchain_result,
                product_ref=product_ref,
                product_data=product_data
            )
        
        # 3. Retourner le résultat complet
        return {
            **blockchain_result,
            "mongo_id": mongo_id,
            "farmer_id": farmer_id,
            "product_ref": product_ref
        }
    
    def get_product_trace(self, db, trace_id: str = None, blockchain_id: int = None) -> Dict[str, Any]:
        """Récupère une trace depuis MongoDB"""
        query = {}
        
        if trace_id:
            query["_id"] = ObjectId(trace_id)
        elif blockchain_id:
            query["blockchain_product_id"] = blockchain_id
        else:
            return {"success": False, "error": "ID requis"}
        
        trace = db.product_traces.find_one(query)
        
        if trace:
            # Convertir ObjectId en string
            trace["_id"] = str(trace["_id"])
            return {"success": True, "trace": trace}
        else:
            return {"success": False, "error": "Trace non trouvée"}
    
    def get_farmer_traces(self, db, farmer_id: str, limit: int = 50) -> Dict[str, Any]:
        """Récupère toutes les traces d'un agriculteur"""
        traces = list(db.product_traces.find(
            {"farmer_id": farmer_id}
        ).sort("created_at", -1).limit(limit))
        
        # Convertir ObjectId
        for trace in traces:
            trace["_id"] = str(trace["_id"])
        
        return {"success": True, "traces": traces, "count": len(traces)}
    
    def verify_on_blockchain(self, blockchain_product_id: int) -> Dict[str, Any]:
        """Vérifie un produit sur la blockchain"""
        try:
            farmer_address, ipfs_cid, timestamp = self.contract.functions.getProductInfo(
                blockchain_product_id
            ).call()
            
            return {
                "success": True,
                "exists": True,
                "farmer_address": farmer_address,
                "ipfs_cid": ipfs_cid,
                "timestamp": timestamp,
                "ipfs_url": ipfs_service.get_ipfs_url(ipfs_cid),
                "verified_at": datetime.utcnow().isoformat()
            }
        except Exception as e:
            if "Product does not exist" in str(e):
                return {"success": True, "exists": False}
            return {"success": False, "error": str(e)}

# Instance globale
blockchain_service = BlockchainService()