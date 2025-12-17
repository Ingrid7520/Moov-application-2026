# app/services/moov_payment_service.py
"""
Service pour gérer les paiements Moov Money (MODE SIMULATION)
Gère les transactions, mise à jour des stocks, et création des commandes
Intégration blockchain pour la sécurité et la traçabilité
"""

from motor.motor_asyncio import AsyncIOMotorDatabase
from bson import ObjectId
from datetime import datetime, timedelta
import random
import string
import logging

logger = logging.getLogger(__name__)

# Import du service blockchain
from app.services.blockchain_simulation import BlockchainSimulationService

class MoovPaymentService:
    """Service de paiement Moov Money simulé"""
    
    def generate_transaction_id(self) -> str:
        """Générer un ID de transaction unique"""
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        random_part = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
        return f"AGRI-{timestamp}-{random_part}"
    
    def generate_otp(self) -> str:
        """Générer un code OTP aléatoire (simulation)"""
        return ''.join(random.choices(string.digits, k=6))
    
    async def initiate_payment(
        self,
        db: AsyncIOMotorDatabase,
        buyer_phone: str,
        amount: float,
        product_id: str,
        buyer_id: str,
        seller_id: str,
        quantity: float,
        unit_price: float,
        description: str = "Achat AgriSmart",
        delivery_date: str = None,
        delivery_location: str = None
    ) -> dict:
        """
        Initier un paiement Moov Money
        """
        try:
            # 1. Vérifier le produit
            product = await db.products.find_one({"_id": ObjectId(product_id)})
            if not product:
                return {
                    "status": "error",
                    "message": "Produit non trouvé",
                    "otp_code": None,  # ← AJOUT
                }
            
            # Vérifier le stock disponible
            if product["quantity"] < quantity:
                return {
                    "status": "error",
                    "message": f"Stock insuffisant. Disponible: {product['quantity']} kg",
                    "otp_code": None,  # ← AJOUT
                }
            
            # Vérifier que le produit est disponible
            if product.get("status") != "available":
                return {
                    "status": "error",
                    "message": "Ce produit n'est plus disponible à la vente",
                    "otp_code": None,  # ← AJOUT
                }
            
            # 2. Générer les identifiants de transaction
            transaction_id = self.generate_transaction_id()
            otp_code = self.generate_otp()
            
            # 3. Calculer la date de livraison par défaut (3 jours ouvrés)
            if not delivery_date:
                delivery_date = (datetime.utcnow() + timedelta(days=3)).isoformat()
            
            if not delivery_location:
                delivery_location = product.get("location", "À définir")
            
            # 4. Créer la transaction
            transaction_data = {
                "transaction_id": transaction_id,
                "product_id": product_id,
                "product_name": product["name"],
                "buyer_id": buyer_id,
                "seller_id": seller_id,
                "seller_phone": product.get("owner_phone"),
                "buyer_phone": buyer_phone,
                "quantity": quantity,
                "unit_price": unit_price,
                "total_amount": amount,
                "status": "pending",
                "payment_method": "moov_money",
                "payment_reference": None,
                "moov_status": "pending",
                "otp_code": otp_code,
                "delivery_date": delivery_date,
                "delivery_location": delivery_location,
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow(),
            }
            
            result = await db.transactions.insert_one(transaction_data)
            
            logger.info(f"💳 Transaction créée: {transaction_id} - Montant: {amount} FCFA")
            logger.info(f"🔢 CODE OTP (DEV): {otp_code}")
            
            # ← CORRECTION: TOUJOURS retourner otp_code
            return {
                "status": "success",
                "message": "Paiement initié avec succès",
                "transaction_id": transaction_id,
                "transaction_db_id": str(result.inserted_id),
                "amount": amount,
                "otp_code": otp_code,  # ← TOUJOURS PRÉSENT
                "buyer_phone": buyer_phone,
                "seller_name": product.get("owner_name"),
                "product_name": product["name"],
                "delivery_date": delivery_date,
                "delivery_location": delivery_location,
                "error_code": None,  # ← AJOUT pour compatibilité
                "moov_response": {
                    "status": "pending",
                    "message": "Entrez le code OTP pour confirmer le paiement"
                }
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur initiation paiement: {str(e)}")
            return {
                "status": "error",
                "message": f"Erreur lors de l'initiation: {str(e)}",
                "otp_code": None,  # ← AJOUT
                "error_code": "INIT_ERROR",  # ← AJOUT
            }
    
    async def confirm_payment(
        self,
        db: AsyncIOMotorDatabase,
        transaction_id: str,
        otp_code: str = None
    ) -> dict:
        """
        Confirmer un paiement avec le code OTP
        """
        try:
            # 1. Récupérer la transaction
            transaction = await db.transactions.find_one({"transaction_id": transaction_id})
            
            if not transaction:
                return {
                    "status": "error",
                    "message": "Transaction non trouvée"
                }
            
            # Vérifier que la transaction est en attente
            if transaction["status"] != "pending":
                return {
                    "status": "error",
                    "message": f"Transaction déjà {transaction['status']}"
                }
            
            # 2. Vérifier l'OTP (en mode simulation, on peut accepter "123456")
            stored_otp = transaction.get("otp_code")
            if otp_code and otp_code != stored_otp and otp_code != "123456":
                return {
                    "status": "error",
                    "message": "Code OTP invalide"
                }
            
            # 3. Mettre à jour le stock du produit
            product = await db.products.find_one({"_id": ObjectId(transaction["product_id"])})
            
            if not product:
                return {
                    "status": "error",
                    "message": "Produit non trouvé"
                }
            
            new_quantity = product["quantity"] - transaction["quantity"]
            
            # Si le stock tombe à 0, marquer comme vendu
            new_status = "sold" if new_quantity <= 0 else "available"
            
            await db.products.update_one(
                {"_id": ObjectId(transaction["product_id"])},
                {
                    "$set": {
                        "quantity": new_quantity,
                        "status": new_status,
                        "updated_at": datetime.utcnow()
                    }
                }
            )
            
            # 4. Mettre à jour la transaction
            payment_reference = f"MOOV-{self.generate_transaction_id()}"
            
            await db.transactions.update_one(
                {"transaction_id": transaction_id},
                {
                    "$set": {
                        "status": "paid",
                        "moov_status": "success",
                        "payment_reference": payment_reference,
                        "confirmed_at": datetime.utcnow(),
                        "updated_at": datetime.utcnow()
                    },
                    "$unset": {"otp_code": ""}
                }
            )
            
            # 5. Créer l'enregistrement d'achat pour l'acheteur
            purchase_data = {
                "transaction_id": transaction_id,
                "buyer_id": transaction["buyer_id"],
                "product_id": transaction["product_id"],
                "product_name": transaction["product_name"],
                "seller_id": transaction["seller_id"],
                "quantity": transaction["quantity"],
                "unit_price": transaction["unit_price"],
                "total_paid": transaction["total_amount"],
                "delivery_date": transaction.get("delivery_date"),
                "delivery_location": transaction.get("delivery_location"),
                "delivery_status": "pending",
                "created_at": datetime.utcnow()
            }
            
            await db.purchases.insert_one(purchase_data)
            
            # 6. ← NOUVEAU: Enregistrer sur la blockchain
            blockchain_service = BlockchainSimulationService(db)
            blockchain_result = await blockchain_service.create_transaction_record(
                transaction_id=transaction_id,
                product_id=transaction["product_id"],
                buyer_id=transaction["buyer_id"],
                seller_id=transaction["seller_id"],
                amount=transaction["total_amount"],
                quantity=transaction["quantity"],
                product_name=transaction["product_name"]
            )
            
            logger.info(f"✅ Paiement confirmé: {transaction_id}")
            logger.info(f"📦 Stock mis à jour: {product['name']} - Nouveau stock: {new_quantity} kg")
            
            if blockchain_result.get("status") == "success":
                logger.info(f"🔗 Transaction enregistrée sur blockchain: {blockchain_result['transaction_hash'][:16]}...")
            
            return {
                "status": "success",
                "message": "Paiement confirmé avec succès",
                "transaction_id": transaction_id,
                "payment_reference": payment_reference,
                "amount": transaction["total_amount"],
                "new_product_stock": new_quantity,
                "delivery_date": transaction.get("delivery_date"),
                "delivery_location": transaction.get("delivery_location"),
                "blockchain": {
                    "transaction_hash": blockchain_result.get("transaction_hash"),
                    "blockchain_id": blockchain_result.get("blockchain_id"),
                    "secured": blockchain_result.get("status") == "success",
                },
                "moov_response": {
                    "status": "success",
                    "reference": payment_reference
                }
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur confirmation paiement: {str(e)}")
            return {
                "status": "error",
                "message": f"Erreur lors de la confirmation: {str(e)}"
            }
    
    async def get_transaction_status(
        self,
        db: AsyncIOMotorDatabase,
        transaction_id: str
    ) -> dict:
        """Récupérer le statut d'une transaction"""
        try:
            transaction = await db.transactions.find_one({"transaction_id": transaction_id})
            
            if not transaction:
                return {
                    "status": "error",
                    "message": "Transaction non trouvée"
                }
            
            transaction["_id"] = str(transaction["_id"])
            
            return {
                "status": "success",
                "transaction": transaction
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur récupération statut: {str(e)}")
            return {
                "status": "error",
                "message": str(e)
            }
    
    async def get_user_transactions(
        self,
        db: AsyncIOMotorDatabase,
        user_id: str,
        role: str = "buyer",
        limit: int = 50
    ) -> dict:
        """Récupérer l'historique des transactions d'un utilisateur"""
        try:
            query = {}
            if role == "buyer":
                query["buyer_id"] = user_id
            elif role == "seller":
                query["seller_id"] = user_id
            
            cursor = db.transactions.find(query).sort("created_at", -1).limit(limit)
            transactions = await cursor.to_list(length=limit)
            
            for trans in transactions:
                trans["_id"] = str(trans["_id"])
                trans["created_at"] = trans["created_at"].isoformat()
                trans["updated_at"] = trans["updated_at"].isoformat()
            
            return {
                "status": "success",
                "count": len(transactions),
                "transactions": transactions
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur récupération historique: {str(e)}")
            return {
                "status": "error",
                "message": str(e)
            }
    
    async def get_user_purchases(
        self,
        db: AsyncIOMotorDatabase,
        buyer_id: str,
        limit: int = 50
    ) -> dict:
        """Récupérer les achats d'un utilisateur"""
        try:
            cursor = db.purchases.find({"buyer_id": buyer_id}).sort("created_at", -1).limit(limit)
            purchases = await cursor.to_list(length=limit)
            
            for purchase in purchases:
                purchase["_id"] = str(purchase["_id"])
                purchase["created_at"] = purchase["created_at"].isoformat()
            
            return {
                "status": "success",
                "count": len(purchases),
                "purchases": purchases
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur récupération achats: {str(e)}")
            return {
                "status": "error",
                "message": str(e)
            }
    
    async def get_payment_summary(
        self,
        db: AsyncIOMotorDatabase,
        user_id: str,
        role: str = "buyer"
    ) -> dict:
        """Obtenir un résumé des paiements"""
        try:
            query = {"buyer_id": user_id} if role == "buyer" else {"seller_id": user_id}
            
            pipeline = [
                {"$match": query},
                {
                    "$group": {
                        "_id": "$status",
                        "count": {"$sum": 1},
                        "total": {"$sum": "$total_amount"},
                        "average": {"$avg": "$total_amount"}
                    }
                }
            ]
            
            stats = await db.transactions.aggregate(pipeline).to_list(None)
            
            total_count = sum(s["count"] for s in stats)
            total_amount = sum(s["total"] for s in stats)
            
            by_status = {}
            for stat in stats:
                by_status[stat["_id"]] = {
                    "count": stat["count"],
                    "total": stat["total"],
                    "average": stat["average"]
                }
            
            return {
                "status": "success",
                "total_transactions": total_count,
                "total_amount": total_amount,
                "by_status": by_status
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur calcul résumé: {str(e)}")
            return {
                "status": "error",
                "message": str(e)
            }
    
    async def refund_payment(
        self,
        db: AsyncIOMotorDatabase,
        transaction_id: str,
        reason: str = "Remboursement demandé"
    ) -> dict:
        """Effectuer un remboursement (remettre le stock)"""
        try:
            transaction = await db.transactions.find_one({"transaction_id": transaction_id})
            
            if not transaction:
                return {"status": "error", "message": "Transaction non trouvée"}
            
            if transaction["status"] != "paid":
                return {"status": "error", "message": "Seules les transactions payées peuvent être remboursées"}
            
            await db.products.update_one(
                {"_id": ObjectId(transaction["product_id"])},
                {
                    "$inc": {"quantity": transaction["quantity"]},
                    "$set": {"status": "available", "updated_at": datetime.utcnow()}
                }
            )
            
            await db.transactions.update_one(
                {"transaction_id": transaction_id},
                {
                    "$set": {
                        "status": "refunded",
                        "refund_reason": reason,
                        "refunded_at": datetime.utcnow(),
                        "updated_at": datetime.utcnow()
                    }
                }
            )
            
            logger.info(f"💰 Remboursement effectué: {transaction_id}")
            
            return {
                "status": "success",
                "message": "Remboursement effectué avec succès",
                "transaction_id": transaction_id,
                "refunded_amount": transaction["total_amount"]
            }
            
        except Exception as e:
            logger.error(f"❌ Erreur remboursement: {str(e)}")
            return {"status": "error", "message": str(e)}