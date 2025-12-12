import aiohttp
import json
from typing import Dict, Any
from app.config import settings
import logging

logger = logging.getLogger(__name__)

class IPFSService:
    """Service pour interagir avec IPFS via web3.storage (gratuit)"""
    
    def __init__(self):
        self.api_token = settings.web3_storage_token
        self.base_url = "https://api.web3.storage"
        
    async def upload_json(self, data: Dict[str, Any]) -> str:
        """Upload des données JSON sur IPFS, retourne le CID"""
        if not self.api_token:
            logger.warning("WEB3_STORAGE_TOKEN non configuré, simulation d'upload")
            return "simulated_cid_12345"  # Pour le développement sans token
        
        headers = {
            "Authorization": f"Bearer {self.api_token}",
            "Content-Type": "application/json"
        }
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.base_url}/upload",
                    headers=headers,
                    data=json.dumps(data, ensure_ascii=False)
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        cid = result.get("cid")
                        logger.info(f"Données uploadées sur IPFS avec CID: {cid}")
                        return cid
                    else:
                        error_text = await response.text()
                        logger.error(f"Erreur IPFS upload: {error_text}")
                        raise Exception(f"IPFS upload failed: {error_text}")
        except Exception as e:
            logger.error(f"Exception lors de l'upload IPFS: {e}")
            raise
    
    def get_ipfs_url(self, cid: str) -> str:
        """Retourne l'URL publique pour accéder aux données"""
        return f"https://{cid}.ipfs.w3s.link"

# Instance globale
ipfs_service = IPFSService()