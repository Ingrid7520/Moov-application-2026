"""
Configuration blockchain (obsolète - AgriSmart utilise maintenant MongoDB).

Ce fichier est conservé pour la compatibilité, mais toutes les fonctionnalités
blockchain sont maintenant implémentées via MongoDB et le service blockchain_service.
"""

# Stub pour éviter les imports cassés
def get_web3_instance():
    """Obsolète - MongoDB est utilisé à la place"""
    raise NotImplementedError("Web3 n'est pas utilisé. Utilisez blockchain_service avec MongoDB.")

def get_contract_instance(w3=None):
    """Obsolète - MongoDB est utilisé à la place"""
    raise NotImplementedError("Les contrats Web3 ne sont pas utilisés. Utilisez blockchain_service avec MongoDB.")

def get_account():
    """Obsolète - MongoDB est utilisé à la place"""
    raise NotImplementedError("Web3 accounts ne sont pas utilisés. Utilisez blockchain_service avec MongoDB.")
