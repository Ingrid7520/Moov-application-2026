from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime

class ProductRegisterRequest(BaseModel):
    farmer_id: str  # MongoDB user_id comme string
    product_name: str
    crop_type: str = Field(..., description="Cacao, Anacarde, Manioc, etc.")
    quantity: float
    location: Optional[str] = None
    harvest_date: Optional[datetime] = None
    product_ref: Optional[str] = None  # Référence à un document produit existant
    additional_data: Optional[Dict[str, Any]] = {}

class ProductRegisterResponse(BaseModel):
    success: bool
    product_id: int  # blockchain_product_id
    ipfs_cid: str
    tx_hash: Optional[str] = None
    block_number: Optional[int] = None
    ipfs_url: str
    mongo_id: Optional[str] = None
    message: Optional[str] = None

class ProductTraceResponse(BaseModel):
    _id: str
    farmer_id: str
    blockchain_product_id: int
    ipfs_cid: str
    tx_hash: Optional[str]
    block_number: Optional[int]
    metadata: Dict[str, Any]
    status: str
    created_at: datetime
    updated_at: datetime

class BlockchainStatus(BaseModel):
    connected: bool
    network: str
    contract_address: str
    account_balance: str
    last_block: int
    traces_in_db: int = 0

class BlockchainVerification(BaseModel):
    exists: bool
    farmer_address: Optional[str] = None
    ipfs_cid: Optional[str] = None
    timestamp: Optional[int] = None
    ipfs_url: Optional[str] = None
    verified_at: str

class TraceWithVerification(BaseModel):
    mongo_data: Optional[ProductTraceResponse] = None
    blockchain_verification: BlockchainVerification
    consistency_check: bool