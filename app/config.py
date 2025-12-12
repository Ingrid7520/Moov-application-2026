# app/config.py
import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    # MongoDB
    MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
    MONGODB_DATABASE = os.getenv("MONGODB_DATABASE", "agrismart_db")
    
    # JWT
    SECRET_KEY = os.getenv("SECRET_KEY", "default-secret-key-change-me-please")
    ALGORITHM = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "10080"))
    
    # OTP
    OTP_EXPIRE_MINUTES = int(os.getenv("OTP_EXPIRE_MINUTES", "5"))
    OTP_LENGTH = int(os.getenv("OTP_LENGTH", "6"))
    
    # Africa's Talking
    AT_USERNAME = os.getenv("AT_USERNAME", "sandbox")
    AT_API_KEY = os.getenv("AT_API_KEY", "atsk_71a80459847ba3976087282ab3692c025a75278fe72d39adb755ba6f86e5a757fffeb164")
    AT_SENDER_ID = os.getenv("AT_SENDER_ID", "AGRISMART_CI")
    
    @classmethod
    def validate(cls):
        """Valider la configuration"""
        required = ["MONGODB_URL", "SECRET_KEY", "AT_USERNAME", "AT_API_KEY"]
        missing = [var for var in required if not getattr(cls, var)]
        if missing:
            raise ValueError(f"Variables manquantes dans .env: {missing}")

settings = Settings()

from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # ... (tes variables existantes)
    
    # Blockchain
    polygon_rpc_url: str = ""
    contract_address: str = ""
    private_key: str = ""  # Dev seulement
    chain_id: int = 80001
    
    # IPFS
    web3_storage_token: str = ""
    
    class Config:
        env_file = ".env"

settings = Settings()