@echo off
echo ========================================
echo   LANCEMENT AGRI SMART CI
echo ========================================
echo.

cd /d "C:\Users\Admin\OneDrive - ENSEA\Documents\Ingrid\Moov\AgriSmart"

echo 1. Verification de l'environnement...
python --version
echo.

echo 2. Installation des dependances...
pip install fastapi uvicorn pydantic python-jose passlib python-multipart python-dotenv --quiet
echo.

echo 3. Demarrage du serveur...
echo.
echo 🌐 L'application sera disponible sur: http://localhost:8000
echo 📚 Documentation: http://localhost:8000/docs
echo.
echo Appuyez sur CTRL+C pour arreter
echo.

python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000