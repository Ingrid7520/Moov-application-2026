#!/usr/bin/env python3
import os
import json
import subprocess
from pathlib import Path
from dotenv import load_dotenv

# Charger les variables d'environnement
load_dotenv()

def deploy_contract():
    print("🚀 Déploiement du contrat sur Polygon Mumbai...")
    
    # Vérifier que Hardhat est installé
    try:
        subprocess.run(["npx", "hardhat", "--version"], check=True, capture_output=True)
    except:
        print("❌ Hardhat n'est pas installé. Installez-le avec: npm install --save-dev hardhat")
        return
    
    # Vérifier les variables d'environnement
    required_vars = ["POLYGON_RPC_URL", "PRIVATE_KEY"]
    missing = [var for var in required_vars if not os.getenv(var)]
    
    if missing:
        print(f"❌ Variables manquantes dans .env: {', '.join(missing)}")
        return
    
    # Déployer avec Hardhat
    print("📝 Compilation et déploiement en cours...")
    
    try:
        # Compiler
        compile_result = subprocess.run(
            ["npx", "hardhat", "compile"],
            cwd="contracts",
            capture_output=True,
            text=True
        )
        
        if compile_result.returncode != 0:
            print(f"❌ Erreur de compilation: {compile_result.stderr}")
            return
        
        print("✅ Contrat compilé avec succès")
        
        # Déployer
        deploy_result = subprocess.run(
            ["npx", "hardhat", "run", "scripts/deploy.js", "--network", "mumbai"],
            cwd="contracts",
            capture_output=True,
            text=True
        )
        
        if deploy_result.returncode != 0:
            print(f"❌ Erreur de déploiement: {deploy_result.stderr}")
            return
        
        print(deploy_result.stdout)
        
        # Lire l'adresse déployée depuis le fichier d'artefacts
        artifacts_dir = Path("app/services/contract_artifacts")
        contract_file = list(artifacts_dir.glob("AgriSmartTraceability.json"))[0]
        
        with open(contract_file) as f:
            artifact = json.load(f)
        
        # Trouver l'adresse dans la sortie ou utiliser une valeur par défaut
        contract_address = "0x..."  # À remplacer manuellement après déploiement
        for line in deploy_result.stdout.split('\n'):
            if "Contract deployed to:" in line:
                contract_address = line.split(":")[1].strip()
                break
        
        print(f"\n✅ Contrat déployé avec succès!")
        print(f"📝 Adresse du contrat: {contract_address}")
        
        # Mettre à jour le .env
        env_path = Path(".env")
        with open(env_path, "a") as f:
            f.write(f"\nCONTRACT_ADDRESS={contract_address}\n")
        
        print(f"📄 .env mis à jour avec l'adresse du contrat")
        
        # Copier l'ABI dans le bon dossier
        abi_path = Path("app/services/contract_abi.json")
        with open(abi_path, "w") as f:
            json.dump(artifact["abi"], f)
        
        print(f"📄 ABI sauvegardé dans: {abi_path}")
        
    except Exception as e:
        print(f"❌ Erreur lors du déploiement: {e}")

if __name__ == "__main__":
    deploy_contract()