from datetime import datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field
from bson import ObjectId

class ProductTrace(BaseModel):
    """Modèle pour la traçabilité blockchain (MongoDB)"""
    # MongoDB génère automatiquement _id
    
    # Référence à tes produits existants
    product_ref: Optional[str] = None  # Référence à ton modèle Product MongoDB
    farmer_id: str  # Référence à l'utilisateur
    blockchain_product_id: int  # ID unique sur la blockchain
    ipfs_cid: str
    tx_hash: str
    block_number: Optional[int] = None
    metadata: Dict[str, Any] = {}  # Données complètes du produit
    status: str = "registered"  # registered, sold, delivered, etc.
    
    # Timestamps
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
    
    class Config:
        json_encoders = {
            datetime: lambda v: v.isoformat(),
            ObjectId: lambda v: str(v)
        }
        allow_population_by_field_name = True

class BlockchainEvent(BaseModel):
    """Modèle pour les événements blockchain"""
    event_name: str
    tx_hash: str
    block_number: int
    data: Dict[str, Any] = {}
    processed: bool = False
    created_at: datetime = Field(default_factory=datetime.utcnow)