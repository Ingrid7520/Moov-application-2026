# Structure du Projet AgriSmart CI

## 📦 Vue d'ensemble

```
AgriSmart/
├── .env                          # Configuration (variables d'environnement)
├── .gitignore                    # Fichiers git à ignorer
├── requirements.txt              # Dépendances Python
├── start.bat                     # Script démarrage (Windows)
├── run.sh                        # Script démarrage (Linux/macOS)
├── STRUCTURE.md                  # Ce fichier
│
├── app/                          # 📱 Application principale
│   ├── __init__.py
│   ├── main.py                   # Entrée principale FastAPI (tous les endpoints)
│   ├── config.py                 # Configuration (settings, variables)
│   ├── database.py               # Connexion MongoDB
│   │
│   ├── api/                      # 🔌 Endpoints (routeurs)
│   │   ├── __init__.py
│   │   ├── auth.py               # Endpoints authentification
│   │   ├── payment.py            # Endpoints paiement
│   │   ├── products.py           # Endpoints produits
│   │   ├── users.py              # Endpoints utilisateurs
│   │   ├── weather.py            # Endpoints météo
│   │   └── test.py               # 🆕 Endpoints de test (NEW)
│   │
│   ├── core/                     # 🔧 Logique métier
│   │   ├── __init__.py
│   │   ├── security.py           # JWT, hachage mdp, authentification
│   │   ├── dependencies.py       # Dépendances FastAPI
│   │   └── otp_service.py        # Service OTP (génération, vérification)
│   │
│   ├── models/                   # 📊 Modèles de données (Pydantic v2)
│   │   ├── __init__.py           # Exporte tous les modèles
│   │   ├── user.py               # Modèle User
│   │   ├── product.py            # Modèle Product
│   │   ├── blockchain.py         # Modèle Blockchain
│   │   ├── chat.py               # Modèle Chat
│   │   ├── disease.py            # Modèle Disease
│   │   ├── market.py             # Modèle Market
│   │   ├── otp.py                # Modèle OTP
│   │   ├── transaction.py        # Modèle Transaction
│   │   └── weather.py            # Modèle Weather
│   │
│   ├── schemas/                  # 📋 Schémas requête/réponse
│   │   ├── __init__.py
│   │   ├── auth.py               # Schémas inscription, vérification OTP, login
│   │   ├── product.py            # Schémas produit
│   │   └── user.py               # Schémas utilisateur
│   │
│   └── utils/                    # 🛠️ Utilitaires
│       ├── __init__.py
│       └── sms.py                # Service SMS (Africa's Talking)
│
├── scripts/                      # 🧪 Scripts utilitaires (vide après nettoyage)
│   ├── init_database.py          # Initialisation BD
│   └── setup_mongodb.py          # Setup MongoDB
│
├── test/                         # 🧪 Tests (vide)
│
├── alembic/                      # 🔄 Migrations BD (Alembic)
│   └── ...
│
└── venv/                         # 🐍 Environnement virtuel Python (ignoré en git)
    └── (site-packages, etc.)
```

## 🚀 Démarrage de l'application

### Via PowerShell (Windows)
```powershell
cd "C:\Users\Admin\OneDrive - ENSEA\Documents\Ingrid\Moov\AgriSmart"
python -m uvicorn app.main:app --reload
```

L'app démarre sur `http://localhost:8000`

### Documentation interactive
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 🧪 Endpoints de test (à utiliser pour valider)

Tous les endpoints de test sont disponibles sous `/api/test`. Accède à http://localhost:8000/docs pour voir l'interface interactive.

### Endpoints disponibles

#### 1️⃣ **Inscription avec OTP**
```
POST /api/test/register-with-otp
```
**Request:**
```json
{
  "phone_number": "+2250719378709",
  "full_name": "Test User",
  "password": "password123"
}
```
**Response:**
```json
{
  "message": "Compte créé avec succès. Code OTP envoyé.",
  "phone_number": "+2250719378709",
  "user_id": "...",
  "sms_sent": true,
  "test_otp": "123456",
  "otp_expires_in_minutes": 5
}
```

#### 2️⃣ **Cleanup et Réinscription**
Utile pour réutiliser le même numéro dans plusieurs tests.

```
POST /api/test/cleanup-and-register
```
**Request:**
```json
{
  "phone_number": "+2250719378709",
  "full_name": "Test User",
  "password": "password123"
}
```

#### 3️⃣ **Vérifier l'OTP**
```
POST /api/test/verify-otp
```
**Request:**
```json
{
  "phone_number": "+2250719378709",
  "otp_code": "123456"
}
```
**Response:**
```json
{
  "message": "Vérification réussie",
  "access_token": "eyJhbGc...",
  "token_type": "bearer",
  "user": {
    "phone_number": "+2250719378709",
    "full_name": "Test User",
    "is_verified": true
  }
}
```

#### 4️⃣ **Voir l'historique SMS**
```
GET /api/test/sms-history
```
**Response:**
```json
{
  "mode": "sandbox/demo",
  "total_sms": 5,
  "recent_sms": [
    {
      "timestamp": "2025-12-11T10:30:45.123456",
      "phone": "+2250719378709",
      "message": "Votre code de vérification AgriSmart CI est: 123456. Valide pour 5 minutes.",
      "status": "sent"
    }
  ]
}
```

#### 5️⃣ **Vérifier le statut BD**
```
GET /api/test/db-status
```
**Response:**
```json
{
  "database": "agrismart_db",
  "connected": true,
  "collections": ["users", "otp_codes", ...],
  "stats": {
    "users_count": 5,
    "otp_codes_count": 3
  }
}
```

#### 6️⃣ **Nettoyer TOUTES les données de test**
⚠️ Supprime tous les utilisateurs et OTP.
```
DELETE /api/test/cleanup-all-test-data
```

## 📝 Endpoints principales de l'API (en production)

### Authentification
- `POST /api/auth/register` - Inscription
- `POST /api/auth/verify-otp` - Vérifier OTP
- `POST /api/auth/login` - Connexion
- `POST /api/auth/refresh-token` - Rafraîchir token
- `GET /api/auth/me` - Profil courant

### Produits
- `GET /api/products` - Liste produits
- `POST /api/products` - Créer produit
- `GET /api/products/{id}` - Détail produit
- `PUT /api/products/{id}` - Modifier produit
- `DELETE /api/products/{id}` - Supprimer produit

### Utilisateurs
- `GET /api/users/{id}` - Détail utilisateur
- `PUT /api/users/{id}` - Modifier profil

### Marché
- `GET /api/market/prices` - Prix du marché

### Météo
- `GET /api/weather/{location}` - Météo par localisation

### Paiements
- `POST /api/payments` - Initier paiement
- `GET /api/payments/{id}` - Détail paiement

## 🔧 Configuration (.env)

```env
# MongoDB
MONGODB_URL=mongodb://localhost:27017
MONGODB_DATABASE=agrismart_db

# JWT
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=10080

# OTP
OTP_EXPIRE_MINUTES=5
OTP_LENGTH=6

# Africa's Talking (SMS)
AT_USERNAME=sandbox
AT_API_KEY=votre_clef_api_sandbox
AT_SENDER_ID=AGRISMART_CI
```

## 🗑️ Fichiers supprimés (nettoyage)

Les fichiers suivants ont été **supprimés** car inutiles :
- `scripts/test_auth.py`
- `scripts/test_otp_flow.py`
- `scripts/test_otp_real.py`
- `scripts/check_mongodb.py`
- `scripts/check_mongodb_details.py`
- `scripts/show_users.py`
- `scripts/check_status.py`
- `scripts/test_connection.py`
- `sms_demo_logs.json`

**Raison**: Les endpoints de test dans `/api/test` remplacent tous ces scripts.

## 📦 Dépendances principales

```
fastapi          # Framework web
uvicorn          # Serveur ASGI
pydantic         # Validation données (v2)
motor            # Async MongoDB
pymongo          # Driver MongoDB
pyjwt            # JWT tokens
passlib          # Hachage mdp
python-dotenv    # Gestion .env
africastalking   # SMS API
```

## 🎯 Points clés de l'architecture

1. **Pydantic v2**: Models et validation de données avec Pydantic v2 (field_validator, model_config)
2. **Async/await**: Tout est asynchrone pour optimiser les perfs
3. **MongoDB**: BD NoSQL avec Motor pour l'async
4. **JWT**: Authentification sans état
5. **OTP SMS**: Vérification à 2 facteurs via Africa's Talking
6. **Modularité**: Séparation claire entre routes, modèles, logique métier
7. **Tests intégrés**: Endpoints `/api/test` pour validation rapide

## 🔐 Sécurité

- Passwords: Hachés avec bcrypt (passlib)
- JWT: HS256 avec SECRET_KEY
- CORS: Actuellement ouvert (à restreindre en production)
- OTP: 6 chiffres, expiration 5 minutes
- Rate limiting: À implémenter

## 🚀 Prochaines étapes recommandées

1. ✅ Tester les endpoints via Swagger UI
2. ✅ Vérifier que SMS est reçu (ajouter ton numéro aux Test Numbers AT)
3. ⏳ Implémenter rate limiting
4. ⏳ Ajouter logging structuré
5. ⏳ Écrire tests unitaires
6. ⏳ Documenter les erreurs possibles
7. ⏳ Optimiser les performances BD
8. ⏳ Préparer déploiement (production config)

---

**Version**: 1.0.0  
**Dernière mise à jour**: 2025-12-11  
**Auteur**: AgriSmart CI Team
