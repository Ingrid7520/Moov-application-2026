#!/bin/bash

echo "========================================"
echo "   AGRI SMART CI - MongoDB Edition"
echo "========================================"
echo ""

# Vérifier les dépendances
echo "🔍 Vérification des dépendances..."
python -c "import motor" 2>/dev/null || {
    echo "📦 Installation de motor (MongoDB driver)..."
    pip install motor pymongo --quiet
}

# Initialiser la base de données
echo "🗄️  Initialisation de MongoDB..."
python scripts/init_mongodb.py

echo ""
echo "✅ Préparation terminée!"
echo ""
echo "🚀 Démarrage du serveur..."
echo ""
echo "🌐 URL: http://localhost:8000"
echo "📚 Documentation: http://localhost:8000/docs"
echo "🔐 OTP de test: 123456"
echo ""
echo "📊 Collections MongoDB:"
echo "   • users          - Utilisateurs"
echo "   • products       - Produits agricoles"
echo "   • transactions   - Transactions"
echo "   • market_prices  - Prix du marché"
echo "   • weather_data   - Données météo"
echo ""
echo "========================================"
echo ""

python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000