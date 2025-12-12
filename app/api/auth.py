from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from app.database import get_database
from app.schemas.auth import RegisterRequest, VerifyOTPRequest, LoginRequest, TokenResponse
from app.models.user import UserCreate, UserInDB, UserResponse, UserType
from app.core.otp_service import create_otp, verify_otp, send_otp_sms
from app.core.security import create_access_token
from bson import ObjectId
from datetime import datetime

router = APIRouter(prefix="/api/auth", tags=["Authentication"])

@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register(request: RegisterRequest, db: AsyncIOMotorDatabase = Depends(get_database)):
    """Inscription d'un nouvel utilisateur avec envoi d'OTP"""
    
    # Vérifier si l'utilisateur existe déjà
    existing_user = await db.users.find_one({"phone_number": request.phone_number})
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ce numéro est déjà enregistré"
        )
    
    # Créer l'utilisateur (non vérifié)
    user_data = UserCreate(
        phone_number=request.phone_number,
        name=request.name,
        user_type=UserType[request.user_type.upper()],
        location=request.location
    ).dict()
    
    user_data.update({
        "is_verified": False,
        "is_active": True,
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow()
    })
    
    # Insérer dans MongoDB
    result = await db.users.insert_one(user_data)
    
    # Générer et envoyer l'OTP
    otp_code = await create_otp(db, request.phone_number)
    await send_otp_sms(request.phone_number, otp_code)
    
    return {
        "message": "Code de vérification envoyé par SMS",
        "phone_number": request.phone_number,
        "user_id": str(result.inserted_id)
    }

@router.post("/verify-otp", response_model=TokenResponse)
async def verify_otp_code(request: VerifyOTPRequest, db: AsyncIOMotorDatabase = Depends(get_database)):
    """Vérification du code OTP et connexion"""
    
    # Vérifier le code OTP
    is_valid = await verify_otp(db, request.phone_number, request.code)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code invalide ou expiré"
        )
    
    # Récupérer et mettre à jour l'utilisateur
    user = await db.users.find_one_and_update(
        {"phone_number": request.phone_number},
        {
            "$set": {
                "is_verified": True,
                "updated_at": datetime.utcnow()
            }
        },
        return_document=True
    )
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utilisateur non trouvé"
        )
    
    # Créer le token JWT
    access_token = create_access_token(data={"sub": str(user["_id"])})
    
    return TokenResponse(access_token=access_token)

@router.post("/login")
async def login(request: LoginRequest, db: AsyncIOMotorDatabase = Depends(get_database)):
    """Connexion avec envoi d'OTP"""
    
    # Vérifier si l'utilisateur existe
    user = await db.users.find_one({"phone_number": request.phone_number})
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utilisateur non trouvé. Veuillez vous inscrire."
        )
    
    # Vérifier si l'utilisateur est actif
    if not user.get("is_active", True):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Compte désactivé"
        )
    
    # Générer et envoyer l'OTP
    otp_code = await create_otp(db, request.phone_number)
    await send_otp_sms(request.phone_number, otp_code)
    
    return {
        "message": "Code de vérification envoyé par SMS",
        "phone_number": request.phone_number
    }