from fastapi import APIRouter, Depends, HTTPException
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.database import get_database
from app.models.blockchain import ProductTraceCreate, ProductTraceResponse
from app.schemas.blockchain import ProductTraceRequest, FarmerTracesResponse, BlockchainStatus
import logging
from datetime import datetime
from bson import ObjectId

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/blockchain",
    tags=["blockchain"]
)

@router.post("/products/register", response_model=ProductTraceResponse)
async def register_product(
    request: ProductTraceRequest,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Enregistre une trace produit dans MongoDB"""
    try:
        trace_data = {
            "farmer_phone": request.farmer_phone,
            "product_name": request.product_name,
            "product_type": request.product_type,
            "quantity": request.quantity,
            "location": request.location,
            "harvest_date": request.harvest_date.isoformat() if request.harvest_date else None,
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat()
        }
        
        result = await db.blockchain_traces.insert_one(trace_data)
        
        return ProductTraceResponse(
            id=str(result.inserted_id),
            farmer_phone=request.farmer_phone,
            product_name=request.product_name,
            product_type=request.product_type,
            quantity=request.quantity,
            location=request.location,
            harvest_date=request.harvest_date,
            created_at=datetime.utcnow()
        )
        
    except Exception as e:
        logger.error(f"Erreur enregistrement trace: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/products/trace/{trace_id}", response_model=ProductTraceResponse)
async def get_product_trace(
    trace_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Récupère une trace par son ID MongoDB"""
    try:
        trace = await db.blockchain_traces.find_one({"_id": ObjectId(trace_id)})
        
        if not trace:
            raise HTTPException(status_code=404, detail="Trace non trouvée")
        
        return ProductTraceResponse(
            id=str(trace["_id"]),
            farmer_phone=trace.get("farmer_phone"),
            product_name=trace.get("product_name"),
            product_type=trace.get("product_type"),
            quantity=trace.get("quantity"),
            location=trace.get("location"),
            harvest_date=trace.get("harvest_date"),
            created_at=datetime.fromisoformat(trace.get("created_at", datetime.utcnow().isoformat()))
        )
        
    except Exception as e:
        logger.error(f"Erreur récupération trace: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/farmers/{farmer_phone}/traces", response_model=FarmerTracesResponse)
async def get_farmer_traces(
    farmer_phone: str,
    limit: int = 50,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Récupère toutes les traces d'un agriculteur"""
    try:
        cursor = db.blockchain_traces.find({"farmer_phone": farmer_phone}).limit(limit)
        traces = await cursor.to_list(length=limit)
        
        trace_list = [
            ProductTraceResponse(
                id=str(trace["_id"]),
                farmer_phone=trace.get("farmer_phone"),
                product_name=trace.get("product_name"),
                product_type=trace.get("product_type"),
                quantity=trace.get("quantity"),
                location=trace.get("location"),
                harvest_date=trace.get("harvest_date"),
                created_at=datetime.fromisoformat(trace.get("created_at", datetime.utcnow().isoformat()))
            )
            for trace in traces
        ]
        
        return FarmerTracesResponse(
            farmer_phone=farmer_phone,
            total_traces=len(trace_list),
            traces=trace_list
        )
        
    except Exception as e:
        logger.error(f"Erreur traces agriculteur: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/status", response_model=BlockchainStatus)
async def get_blockchain_status(
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """Statut des traces dans MongoDB"""
    try:
        traces_count = await db.blockchain_traces.count_documents({})
        
        return BlockchainStatus(
            database="MongoDB",
            collection="blockchain_traces",
            total_traces=traces_count,
            status="operational"
        )
        
    except Exception as e:
        logger.error(f"Erreur statut: {e}")
        raise HTTPException(status_code=500, detail=str(e))
