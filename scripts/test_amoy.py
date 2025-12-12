import os
from web3 import Web3
from dotenv import load_dotenv

load_dotenv()

# URL Amoy
amoy_url = os.getenv("POLYGON_RPC_URL")

print("🧪 Test de connexion Polygon Amoy (ex-Mumbai)...")
print(f"URL: {amoy_url}")

if not amoy_url:
    print("❌ POLYGON_RPC_URL non défini")
    exit(1)

# Connexion
w3 = Web3(Web3.HTTPProvider(amoy_url))

if w3.is_connected():
    print("✅ CONNECTÉ À POLYGON AMOY !")
    print(f"📦 Dernier bloc: {w3.eth.block_number}")
    
    # Vérifie la chain ID
    chain_id = w3.eth.chain_id
    print(f"🔗 Chain ID: {chain_id}")
    print(f"📝 Attendue: 80002 (Amoy)")
    
    # Test compte
    private_key = os.getenv("PRIVATE_KEY")
    if private_key and private_key.startswith("0x"):
        account = w3.eth.account.from_key(private_key)
        balance = w3.eth.get_balance(account.address)
        balance_matic = w3.from_wei(balance, 'ether')
        
        print(f"\n👤 Ton adresse: {account.address}")
        print(f"💰 Solde: {balance_matic:.4f} MATIC")
        
        if balance_matic < 0.01:
            print("\n⚠️  BESOIN DE MATIC DE TEST !")
            print("🔗 Faucet Amoy: https://faucet.polygon.technology/")
            print("📋 IMPORTANT: Sélectionne 'Amoy' comme réseau")
            print(f"📋 Colle cette adresse: {account.address}")
    else:
        print("⚠️  PRIVATE_KEY manquante dans .env")
else:
    print("❌ Non connecté")
    print("Vérifie que:")
    print("1. L'URL contient 'polygon-amoy' et non 'polygon-mumbai'")
    print("2. Tu as bien créé le projet sur Infura")