# app/api/notifications.py
from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.database import get_database
from app.models.notification import NotificationCreate, NotificationResponse, NotificationType
from app.core.dependencies import get_current_active_user
from bson import ObjectId
from typing import List
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/notifications", tags=["Notifications"])

def to_objectid(id_str: str) -> ObjectId:
    try:
        return ObjectId(id_str)
    except:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="ID invalide"
        )

def serialize_notification(notif: dict) -> dict:
    if not notif:
        return None
    notif["id"] = str(notif["_id"])
    notif.pop("_id", None)
    return notif

# ============================================================================
# CREATE - Créer une notification (système interne)
# ============================================================================
@router.post("", status_code=status.HTTP_201_CREATED, response_model=NotificationResponse)
async def create_notification(
    notification: NotificationCreate,
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Créer une notification (endpoint système)
    """
    notif_data = {
        "user_id": notification.user_id,
        "type": notification.type.value,
        "title": notification.title,
        "message": notification.message,
        "priority": notification.priority.value,
        "data": notification.data or {},
        "is_read": False,
        "created_at": datetime.utcnow(),
        "read_at": None
    }
    
    result = await db.notifications.insert_one(notif_data)
    created_notif = await db.notifications.find_one({"_id": result.inserted_id})
    
    logger.info(f"📢 Notification créée: {notification.title} pour user {notification.user_id}")
    
    return NotificationResponse(**serialize_notification(created_notif))

# ============================================================================
# READ - Lire les notifications de l'utilisateur
# ============================================================================
@router.get("", response_model=List[NotificationResponse])
async def get_my_notifications(
    unread_only: bool = False,
    limit: int = 50,
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Récupérer les notifications de l'utilisateur connecté
    
    - **unread_only**: Filtrer uniquement les non lues
    """
    query = {"user_id": str(current_user["_id"])}
    
    if unread_only:
        query["is_read"] = False
    
    cursor = db.notifications.find(query).sort("created_at", -1).limit(limit)
    notifications = await cursor.to_list(length=limit)
    
    logger.info(f"📬 {len(notifications)} notifications pour {current_user['name']}")
    
    return [NotificationResponse(**serialize_notification(n)) for n in notifications]

@router.get("/unread-count")
async def get_unread_count(
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Compter les notifications non lues
    """
    count = await db.notifications.count_documents({
        "user_id": str(current_user["_id"]),
        "is_read": False
    })
    
    return {"unread_count": count}

# ============================================================================
# UPDATE - Marquer comme lue
# ============================================================================
@router.patch("/{notification_id}/read")
async def mark_as_read(
    notification_id: str,
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Marquer une notification comme lue
    """
    notif = await db.notifications.find_one({"_id": to_objectid(notification_id)})
    
    if not notif:
        raise HTTPException(status_code=404, detail="Notification non trouvée")
    
    if str(notif["user_id"]) != str(current_user["_id"]):
        raise HTTPException(status_code=403, detail="Non autorisé")
    
    await db.notifications.update_one(
        {"_id": to_objectid(notification_id)},
        {
            "$set": {
                "is_read": True,
                "read_at": datetime.utcnow()
            }
        }
    )
    
    return {"message": "Notification marquée comme lue"}

@router.post("/mark-all-read")
async def mark_all_as_read(
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Marquer toutes les notifications comme lues
    """
    result = await db.notifications.update_many(
        {
            "user_id": str(current_user["_id"]),
            "is_read": False
        },
        {
            "$set": {
                "is_read": True,
                "read_at": datetime.utcnow()
            }
        }
    )
    
    return {"message": f"{result.modified_count} notifications marquées comme lues"}

# ============================================================================
# DELETE - Supprimer une notification
# ============================================================================
@router.delete("/{notification_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_notification(
    notification_id: str,
    current_user: dict = Depends(get_current_active_user),
    db: AsyncIOMotorDatabase = Depends(get_database)
):
    """
    Supprimer une notification
    """
    notif = await db.notifications.find_one({"_id": to_objectid(notification_id)})
    
    if not notif:
        raise HTTPException(status_code=404, detail="Notification non trouvée")
    
    if str(notif["user_id"]) != str(current_user["_id"]):
        raise HTTPException(status_code=403, detail="Non autorisé")
    
    await db.notifications.delete_one({"_id": to_objectid(notification_id)})
    
    logger.info(f"🗑️ Notification supprimée: {notification_id}")
    
    return None

# ============================================================================
# HELPER - Créer notification paiement
# ============================================================================
async def create_payment_notification(
    user_id: str,
    amount: float,
    product_name: str,
    success: bool,
    db: AsyncIOMotorDatabase
):
    """Helper pour créer une notification de paiement"""
    if success:
        title = "✅ Paiement réussi"
        message = f"Votre achat de {product_name} ({amount} FCFA) a été confirmé avec succès !"
        notif_type = NotificationType.PAYMENT_SUCCESS
    else:
        title = "❌ Paiement échoué"
        message = f"Le paiement de {amount} FCFA pour {product_name} a échoué. Veuillez réessayer."
        notif_type = NotificationType.PAYMENT_FAILED
    
    await db.notifications.insert_one({
        "user_id": user_id,
        "type": notif_type.value,
        "title": title,
        "message": message,
        "priority": "high",
        "data": {
            "amount": amount,
            "product_name": product_name
        },
        "is_read": False,
        "created_at": datetime.utcnow(),
        "read_at": None
    })
    
    logger.info(f"📢 Notification paiement créée pour user {user_id}")