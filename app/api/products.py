# app/api/products.py
# ✅ VERSION AVEC SUPPORT IMAGES
from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.database import get_database
from app.models.product import ProductCreate, ProductUpdate, ProductResponse, ProductStatus, ProductType
from app.core.dependencies import get_current_active_user
from bson import ObjectId
from typing import List, Optional
from datetime import datetime
import logging
import base64

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/products", tags=["Products"])

def to_objectid(id_str: str) -> ObjectId:
    try:
        return ObjectId(id_str)
    except:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="ID invalide"
        )

def serialize_product(product: dict) -> dict:
    if not product:
        return None
    product["id"] = str(product["_id"])
    product.pop("_id", None)
    return product

def validate_images(images: List[str]) -> List[str]:
    """
    Valider les images base64
    - Max 5 images
    - Max 5MB par image
    """
    if not images:
        return []
    
    if len(images) > 5:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Maximum 5 images autorisées"
        )
    
    validated_images = []
    for idx, img in enumerate(images):
        # Vérifier format base64
        if not img.startswith('data:image/'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Image {idx+1}: Format invalide (doit commencer par 'data:image/')"
            )
        
        # Vérifier taille (environ 5MB = 6.67MB en base64)
        if len(img) > 7000000:  # 7MB en base64 ≈ 5MB image
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Image {idx+1}: Taille maximale 5MB dépassée"
            )
        
        validated_images.append(img)
    
    return validated_images

# ============================================================================
# CREATE - Créer un nouveau produit AVEC IMAGES
# ============================================================================
@router.post("", status_code=status.HTTP_201_CREATED, response_model=ProductResponse)
async def create_product(
    product: ProductCreate,
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Créer un nouveau produit avec images
    
    - **images**: Liste de 0 à 5 images en base64 (format: data:image/png;base64,...)
    """
    user_type = current_user.get("user_type", "")
    if user_type not in ["producer", "both", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les producteurs peuvent créer des produits"
        )
    
    # Valider les images
    validated_images = validate_images(product.images or [])
    
    product_data = {
        "name": product.name,
        "product_type": product.product_type.value,
        "quantity": product.quantity,
        "unit_price": product.unit_price,
        "location": product.location,
        "description": product.description or "",
        "harvest_date": product.harvest_date or datetime.utcnow(),
        "quality_grade": product.quality_grade.value if product.quality_grade else "B",
        "images": validated_images,  # ✅ STOCKAGE IMAGES BASE64
        "owner_id": str(current_user["_id"]),
        "owner_phone": current_user["phone_number"],
        "owner_name": current_user["name"],
        "status": ProductStatus.AVAILABLE.value,
        "views": 0,
        "favorite_count": 0,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    }
    
    result = await db.products.insert_one(product_data)
    created_product = await db.products.find_one({"_id": result.inserted_id})
    
    logger.info(f"✅ Produit créé: {product.name} avec {len(validated_images)} image(s)")
    
    return ProductResponse(**serialize_product(created_product))

# ============================================================================
# READ - Lire les produits
# ============================================================================
@router.get("", response_model=List[ProductResponse])
async def get_products(
    product_type: Optional[ProductType] = None,
    status: Optional[ProductStatus] = None,
    location: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    owner_id: Optional[str] = None,
    limit: int = 100,
    skip: int = 0,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Lister les produits avec images
    """
    query = {}
    
    if product_type:
        query["product_type"] = product_type.value
    if status:
        query["status"] = status.value
    if location:
        query["location"] = {"$regex": location, "$options": "i"}
    if owner_id:
        query["owner_id"] = owner_id
    if min_price is not None or max_price is not None:
        query["unit_price"] = {}
        if min_price is not None:
            query["unit_price"]["$gte"] = min_price
        if max_price is not None:
            query["unit_price"]["$lte"] = max_price
    
    cursor = db.products.find(query).sort("created_at", -1).skip(skip).limit(limit)
    products = await cursor.to_list(length=limit)
    
    return [ProductResponse(**serialize_product(product)) for product in products]

@router.get("/my-products", response_model=List[ProductResponse])
async def get_my_products(
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Récupérer tous les produits de l'utilisateur
    """
    query = {"owner_id": str(current_user["_id"])}
    
    cursor = db.products.find(query).sort("created_at", -1)
    products = await cursor.to_list(length=None)
    
    logger.info(f"📦 {len(products)} produits trouvés pour {current_user['name']}")
    
    return [ProductResponse(**serialize_product(product)) for product in products]

@router.get("/{product_id}", response_model=ProductResponse)
async def get_product(
    product_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Obtenir un produit avec ses images
    """
    product = await db.products.find_one({"_id": to_objectid(product_id)})
    
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit non trouvé"
        )
    
    # Incrémenter le compteur de vues
    await db.products.update_one(
        {"_id": to_objectid(product_id)},
        {"$inc": {"views": 1}}
    )
    
    return ProductResponse(**serialize_product(product))

# ============================================================================
# UPDATE - Mettre à jour un produit AVEC IMAGES
# ============================================================================
@router.put("/{product_id}", response_model=ProductResponse)
async def update_product(
    product_id: str,
    product_update: ProductUpdate,
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Mettre à jour un produit (y compris les images)
    """
    product = await db.products.find_one({"_id": to_objectid(product_id)})
    
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit non trouvé"
        )
    
    if str(product["owner_id"]) != str(current_user["_id"]) and current_user.get("user_type") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous n'êtes pas autorisé à modifier ce produit"
        )
    
    update_data = {}
    
    if product_update.name is not None:
        update_data["name"] = product_update.name
    if product_update.description is not None:
        update_data["description"] = product_update.description
    if product_update.quantity is not None:
        update_data["quantity"] = product_update.quantity
    if product_update.unit_price is not None:
        update_data["unit_price"] = product_update.unit_price
    if product_update.status is not None:
        update_data["status"] = product_update.status.value
    if product_update.quality_grade is not None:
        update_data["quality_grade"] = product_update.quality_grade.value
    
    # ✅ MISE À JOUR DES IMAGES
    if product_update.images is not None:
        validated_images = validate_images(product_update.images)
        update_data["images"] = validated_images
        logger.info(f"🖼️ {len(validated_images)} image(s) mises à jour pour produit {product_id}")
    
    update_data["updated_at"] = datetime.utcnow()
    
    await db.products.update_one(
        {"_id": to_objectid(product_id)},
        {"$set": update_data}
    )
    
    updated_product = await db.products.find_one({"_id": to_objectid(product_id)})
    
    logger.info(f"✏️ Produit mis à jour: {product_id}")
    
    return ProductResponse(**serialize_product(updated_product))

# ============================================================================
# DELETE - Supprimer un produit
# ============================================================================
@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product(
    product_id: str,
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Supprimer un produit
    """
    product = await db.products.find_one({"_id": to_objectid(product_id)})
    
    if not product:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Produit non trouvé"
        )
    
    if str(product["owner_id"]) != str(current_user["_id"]) and current_user.get("user_type") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous n'êtes pas autorisé à supprimer ce produit"
        )
    
    await db.products.delete_one({"_id": to_objectid(product_id)})
    
    logger.info(f"🗑️ Produit supprimé: {product_id}")
    
    return None

# ============================================================================
# ACTIONS SUPPLÉMENTAIRES
# ============================================================================
@router.patch("/{product_id}/toggle-status")
async def toggle_product_status(
    product_id: str,
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Basculer le statut entre AVAILABLE et SOLD
    """
    product = await db.products.find_one({"_id": to_objectid(product_id)})
    
    if not product:
        raise HTTPException(status_code=404, detail="Produit non trouvé")
    
    if str(product["owner_id"]) != str(current_user["_id"]):
        raise HTTPException(status_code=403, detail="Non autorisé")
    
    current_status = product.get("status", "available")
    new_status = "sold" if current_status == "available" else "available"
    
    await db.products.update_one(
        {"_id": to_objectid(product_id)},
        {"$set": {"status": new_status, "updated_at": datetime.utcnow()}}
    )
    
    return {"message": "Statut mis à jour", "new_status": new_status}