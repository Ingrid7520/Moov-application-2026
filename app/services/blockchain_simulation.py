# app/services/blockchain_simulation.py
"""
Service de simulation Blockchain pour AgriSmart CI
Sécurise les transactions par traçabilité et Smart Contracts
"""

from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from datetime import datetime, timedelta
import hashlib
import json
import random
import string
import logging

logger = logging.getLogger(__name__)


class BlockchainSimulationService:
    """Service de blockchain simulée pour la traçabilité des transactions"""
    
    def __init__(self, db: AsyncIOMotorDatabase):
        self.db = db
        self.difficulty = 2  # Difficulté du proof-of-work (nombre de zéros)
    
    def _generate_hash(self, data: dict) -> str:
        """Génère un hash SHA-256 des données"""
        json_string = json.dumps(data, sort_keys=True, default=str)
        return hashlib.sha256(json_string.encode()).hexdigest()
    
    def _generate_block_id(self) -> str:
        """Génère un ID de bloc unique"""
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        random_part = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
        return f"BLOCK-{timestamp}-{random_part}"
    
    async def create_transaction_record(
        self,
        transaction_id: str,
        product_id: str,
        buyer_id: str,
        seller_id: str,
        amount: float,
        quantity: float,
        product_name: str
    ) -> dict:
        """
        Enregistre une transaction sur la blockchain
        
        Cette fonction est appelée automatiquement après confirmation d'un paiement
        """
        try:
            # 1. Créer l'enregistrement blockchain
            blockchain_record = {
                "transaction_id": transaction_id,
                "product_id": product_id,
                "buyer_id": buyer_id,
                "seller_id": seller_id,
                "amount": amount,
                "quantity": quantity,
                "product_name": product_name,
                "timestamp": datetime.utcnow(),
                "block_id": None,  # Sera assigné lors du minage
                "block_hash": None,
                "previous_hash": None,
                "status": "pending",  # pending -> mined -> confirmed
                "confirmations": 0,
                "created_at": datetime.utcnow(),
            }
            
            # 2. Calculer le hash de la transaction
            transaction_hash = self._generate_hash(blockchain_record)
            blockchain_record["transaction_hash"] = transaction_hash
            
            # 3. Insérer dans la collection blockchain
            result = await self.db.blockchain_records.insert_one(blockchain_record)
            
            logger.info(f"🔗 Transaction blockchain créée: {transaction_hash[:16]}...")
            
            # 4. Créer un bloc si nécessaire (minage automatique)
            await self._auto_mine_block()
            
            return {
                "status": "success",
                "message": "Transaction enregistrée sur la blockchain",
                "transaction_hash": transaction_hash,
                "blockchain_id": str(result.inserted_id),
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur blockchain: {str(e)}")
            return {
                "status": "error",
                "message": str(e)
            }
    
    async def _auto_mine_block(self):
        """Mine automatiquement un bloc toutes les 5 transactions"""
        try:
            # Compter les transactions en attente
            pending_count = await self.db.blockchain_records.count_documents({"status": "pending"})
            
            # Miner si on a 5 transactions ou plus
            if pending_count >= 5:
                await self._mine_block()
        except Exception as e:
            logger.error(f"❌ Erreur auto-mining: {str(e)}")
    
    async def _mine_block(self) -> dict:
        """
        Mine un nouveau bloc avec les transactions en attente
        Proof-of-Work simplifié
        """
        try:
            # 1. Récupérer les transactions en attente
            pending_transactions = await self.db.blockchain_records.find(
                {"status": "pending"}
            ).limit(10).to_list(length=10)
            
            if not pending_transactions:
                return None
            
            # 2. Récupérer le dernier bloc
            last_block = await self.db.blockchain_blocks.find_one(
                {},
                sort=[("block_number", -1)]
            )
            
            block_number = (last_block["block_number"] + 1) if last_block else 0
            previous_hash = last_block["block_hash"] if last_block else "0" * 64
            
            # 3. Créer le nouveau bloc
            block_id = self._generate_block_id()
            
            block_data = {
                "block_id": block_id,
                "block_number": block_number,
                "timestamp": datetime.utcnow(),
                "transactions": [str(tx["_id"]) for tx in pending_transactions],
                "transaction_count": len(pending_transactions),
                "previous_hash": previous_hash,
                "nonce": 0,
                "miner": "AgriSmart-Node-1",
            }
            
            # 4. Proof-of-Work (trouver un nonce valide)
            while True:
                block_hash = self._generate_hash(block_data)
                if block_hash.startswith("0" * self.difficulty):
                    break
                block_data["nonce"] += 1
                
                # Limiter à 10000 tentatives en simulation
                if block_data["nonce"] > 10000:
                    break
            
            block_data["block_hash"] = block_hash
            
            # 5. Enregistrer le bloc
            await self.db.blockchain_blocks.insert_one(block_data)
            
            # 6. Mettre à jour les transactions
            transaction_ids = [tx["_id"] for tx in pending_transactions]
            await self.db.blockchain_records.update_many(
                {"_id": {"$in": transaction_ids}},
                {
                    "$set": {
                        "status": "mined",
                        "block_id": block_id,
                        "block_hash": block_hash,
                        "previous_hash": previous_hash,
                        "block_number": block_number,
                        "mined_at": datetime.utcnow(),
                        "confirmations": 1,
                    }
                }
            )
            
            logger.info(f"⛏️ Bloc miné: {block_id} - {len(pending_transactions)} transactions")
            
            return {
                "block_id": block_id,
                "block_number": block_number,
                "block_hash": block_hash,
                "transactions": len(pending_transactions),
                "nonce": block_data["nonce"],
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur minage: {str(e)}")
            return None
    
    async def verify_transaction(self, transaction_id: str) -> dict:
        """Vérifie l'intégrité d'une transaction sur la blockchain"""
        try:
            # 1. Récupérer l'enregistrement blockchain
            record = await self.db.blockchain_records.find_one(
                {"transaction_id": transaction_id}
            )
            
            if not record:
                return {
                    "status": "error",
                    "message": "Transaction non trouvée sur la blockchain",
                    "verified": False,
                }
            
            # 2. Vérifier le hash
            stored_hash = record.get("transaction_hash")
            record_copy = record.copy()
            record_copy.pop("_id", None)
            record_copy.pop("transaction_hash", None)
            
            calculated_hash = self._generate_hash(record_copy)
            hash_valid = (stored_hash == calculated_hash)
            
            # 3. Vérifier le bloc (si miné)
            block_valid = True
            block_info = None
            
            if record.get("status") == "mined" and record.get("block_id"):
                block = await self.db.blockchain_blocks.find_one(
                    {"block_id": record["block_id"]}
                )
                
                if block:
                    block_info = {
                        "block_number": block["block_number"],
                        "block_hash": block["block_hash"],
                        "timestamp": block["timestamp"].isoformat(),
                    }
                else:
                    block_valid = False
            
            # 4. Résultat de vérification
            is_verified = hash_valid and block_valid
            
            return {
                "status": "success",
                "verified": is_verified,
                "transaction_id": transaction_id,
                "transaction_hash": stored_hash,
                "hash_valid": hash_valid,
                "block_valid": block_valid,
                "blockchain_status": record.get("status"),
                "confirmations": record.get("confirmations", 0),
                "block_info": block_info,
                "timestamp": record["timestamp"].isoformat(),
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur vérification: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "verified": False,
            }
    
    async def get_transaction_trace(self, transaction_id: str) -> dict:
        """Récupère la trace complète d'une transaction"""
        try:
            # 1. Transaction originale
            transaction = await self.db.transactions.find_one(
                {"transaction_id": transaction_id}
            )
            
            if not transaction:
                raise Exception("Transaction non trouvée")
            
            # 2. Enregistrement blockchain
            blockchain_record = await self.db.blockchain_records.find_one(
                {"transaction_id": transaction_id}
            )
            
            # 3. Bloc (si miné)
            block = None
            if blockchain_record and blockchain_record.get("block_id"):
                block = await self.db.blockchain_blocks.find_one(
                    {"block_id": blockchain_record["block_id"]}
                )
            
            # 4. Construire la trace
            trace = {
                "transaction_id": transaction_id,
                "amount": transaction["total_amount"],
                "product": transaction["product_name"],
                "buyer_id": transaction["buyer_id"],
                "seller_id": transaction["seller_id"],
                "status": transaction["status"],
                "created_at": transaction["created_at"].isoformat(),
                "blockchain": None,
            }
            
            if blockchain_record:
                trace["blockchain"] = {
                    "transaction_hash": blockchain_record.get("transaction_hash"),
                    "status": blockchain_record.get("status"),
                    "confirmations": blockchain_record.get("confirmations", 0),
                    "block_number": blockchain_record.get("block_number"),
                    "block_hash": blockchain_record.get("block_hash"),
                    "mined_at": blockchain_record.get("mined_at", "").isoformat() if blockchain_record.get("mined_at") else None,
                }
            
            if block:
                trace["blockchain"]["block_info"] = {
                    "block_id": block["block_id"],
                    "timestamp": block["timestamp"].isoformat(),
                    "previous_hash": block["previous_hash"],
                    "nonce": block["nonce"],
                }
            
            return {
                "status": "success",
                "trace": trace,
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur trace: {str(e)}")
            return {
                "status": "error",
                "message": str(e)
            }
    
    async def get_blockchain_stats(self) -> dict:
        """Statistiques globales de la blockchain"""
        try:
            total_blocks = await self.db.blockchain_blocks.count_documents({})
            total_transactions = await self.db.blockchain_records.count_documents({})
            pending_transactions = await self.db.blockchain_records.count_documents({"status": "pending"})
            mined_transactions = await self.db.blockchain_records.count_documents({"status": "mined"})
            
            # Dernier bloc
            last_block = await self.db.blockchain_blocks.find_one(
                {},
                sort=[("block_number", -1)]
            )
            
            return {
                "status": "success",
                "stats": {
                    "total_blocks": total_blocks,
                    "total_transactions": total_transactions,
                    "pending_transactions": pending_transactions,
                    "mined_transactions": mined_transactions,
                    "last_block": {
                        "block_number": last_block["block_number"] if last_block else 0,
                        "block_hash": last_block["block_hash"][:16] + "..." if last_block else None,
                        "timestamp": last_block["timestamp"].isoformat() if last_block else None,
                    } if last_block else None,
                }
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur stats: {str(e)}")
            return {
                "status": "error",
                "message": str(e)
            }