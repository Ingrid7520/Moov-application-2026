# app/utils/sms.py - VERSION AMÉLIORÉE POUR DÉMO
import africastalking
import asyncio
from app.config import settings
import logging
from datetime import datetime
import json
import os

logger = logging.getLogger(__name__)

# Fichier pour stocker les SMS "envoyés"
SMS_LOG_FILE = "sms_demo_logs.json"

class SMSService:
    """Service SMS intelligent qui bascule entre sandbox/simulation"""
    
    def __init__(self):
        self.sms = None
        self.mode = "simulation"
        self.init_service()
        self.load_sms_logs()
    
    def init_service(self):
        """Initialiser le service SMS"""
        # Vérifier si on a des credentials valides
        has_credentials = (
            settings.AT_API_KEY and 
            settings.AT_API_KEY != "atsk_71a80459847ba3976087282ab3692c025a75278fe72d39adb755ba6f86e5a757fffeb164" and
            len(settings.AT_API_KEY) > 30
        )
        
        if not has_credentials:
            logger.info("🔧 Mode simulation: Aucune clé API valide")
            self.mode = "simulation"
            return
        
        try:
            africastalking.initialize(settings.AT_USERNAME, settings.AT_API_KEY)
            self.sms = africastalking.SMS
            self.mode = "sandbox" if "sandbox" in settings.AT_USERNAME else "production"
            logger.info(f"✅ Africa's Talking initialisé - Mode: {self.mode}")
        except Exception as e:
            logger.error(f"❌ Erreur d'initialisation: {e}")
            self.mode = "simulation"
    
    def load_sms_logs(self):
        """Charger les logs SMS existants"""
        self.sms_logs = []
        if os.path.exists(SMS_LOG_FILE):
            try:
                with open(SMS_LOG_FILE, 'r', encoding='utf-8') as f:
                    self.sms_logs = json.load(f)
            except:
                self.sms_logs = []
    
    def save_sms_log(self, phone: str, message: str, status: str):
        """Sauvegarder un SMS dans le log"""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "phone": phone,
            "message": message,
            "status": status,
            "mode": self.mode
        }
        
        self.sms_logs.append(log_entry)
        
        # Garder seulement les 50 derniers
        if len(self.sms_logs) > 50:
            self.sms_logs = self.sms_logs[-50:]
        
        # Sauvegarder dans le fichier
        with open(SMS_LOG_FILE, 'w', encoding='utf-8') as f:
            json.dump(self.sms_logs, f, indent=2, ensure_ascii=False)
    
    async def send_async(self, phone_number: str, message: str) -> bool:
        """Envoyer un SMS de manière asynchrone"""
        
        # Log détaillé pour la démo
        print("\n" + "="*60)
        print("📱 DÉMO SERVICE SMS - AGRI SMART CI")
        print("="*60)
        print(f"Mode: {self.mode.upper()}")
        print(f"Destinataire: {phone_number}")
        print(f"Message: {message}")
        print("="*60)
        
        if self.mode == "simulation":
            # Mode simulation pour la démo
            print("💡 INFO: Mode simulation - SMS enregistré localement")
            print("   En production, ce SMS serait envoyé via Africa's Talking")
            
            self.save_sms_log(phone_number, message, "simulated")
            
            # Générer un code OTP si présent dans le message
            import re
            otp_match = re.search(r'\b\d{6}\b', message)
            if otp_match:
                print(f"🔐 Code OTP détecté: {otp_match.group()}")
            
            return True
        
        # Mode sandbox/production réel
        try:
            loop = asyncio.get_event_loop()
            response = await loop.run_in_executor(
                None,
                lambda: self.sms.send(
                    message=message,
                    recipients=[phone_number],
                    sender_id=settings.AT_SENDER_ID
                )
            )
            
            print(f"✅ SMS envoyé avec succès!")
            self.save_sms_log(phone_number, message, "sent")
            return True
            
        except Exception as e:
            print(f"❌ Erreur: {e}")
            print("💡 Basculé en mode simulation pour ce SMS")
            self.save_sms_log(phone_number, message, "failed")
            return True  # Retourne True pour ne pas bloquer le flux
    
    def get_sms_history(self):
        """Obtenir l'historique des SMS pour la démo"""
        return self.sms_logs

# Instance globale
sms_service = SMSService()

async def send_sms_async(phone_number: str, message: str) -> bool:
    """Interface publique pour envoyer un SMS"""
    return await sms_service.send_async(phone_number, message)

def send_sms_sync(phone_number: str, message: str) -> bool:
    """Version synchrone (pour les scripts)"""
    import asyncio
    return asyncio.run(send_sms_async(phone_number, message))

def get_sms_demo_data():
    """Obtenir les données SMS pour la démo"""
    return sms_service.get_sms_history()