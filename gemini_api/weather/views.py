# weather/views.py

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .services import WeatherService
import logging

logger = logging.getLogger(__name__)


class WeatherByCoordinatesView(APIView):
    """
    Récupère la météo par coordonnées GPS
    
    POST /api/weather/coordinates/
    Body: {
        "latitude": 5.3599517,
        "longitude": -4.0082563,
        "location_name": "Abidjan" (optionnel)
    }
    """
    
    def post(self, request):
        latitude = request.data.get("latitude")
        longitude = request.data.get("longitude")
        location_name = request.data.get("location_name")
        
        # Validation
        if latitude is None or longitude is None:
            return Response({
                "error": "Les paramètres 'latitude' et 'longitude' sont requis"
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Convertir en float
            latitude = float(latitude)
            longitude = float(longitude)
            
            # Vérifier la validité des coordonnées
            if not (-90 <= latitude <= 90) or not (-180 <= longitude <= 180):
                return Response({
                    "error": "Coordonnées GPS invalides"
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Récupérer la météo
            weather_data = WeatherService.get_weather_for_location(
                latitude, 
                longitude, 
                location_name
            )
            
            return Response(weather_data, status=status.HTTP_200_OK)
            
        except ValueError as e:
            logger.error(f"Erreur de validation: {e}")
            return Response({
                "error": "Format des coordonnées invalide"
            }, status=status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            logger.error(f"Erreur récupération météo: {e}")
            return Response({
                "error": "Impossible de récupérer les données météo",
                "details": str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class WeatherByCityView(APIView):
    """
    Récupère la météo par nom de ville
    
    POST /api/weather/city/
    Body: {
        "city": "Abidjan"
    }
    """
    
    def post(self, request):
        city_name = request.data.get("city")
        
        if not city_name:
            return Response({
                "error": "Le paramètre 'city' est requis"
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            weather_data = WeatherService.get_weather_by_city(city_name)
            return Response(weather_data, status=status.HTTP_200_OK)
            
        except ValueError as e:
            logger.error(f"Ville introuvable: {e}")
            return Response({
                "error": str(e)
            }, status=status.HTTP_404_NOT_FOUND)
            
        except Exception as e:
            logger.error(f"Erreur récupération météo: {e}")
            return Response({
                "error": "Impossible de récupérer les données météo",
                "details": str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class WeatherTestView(APIView):
    """
    Endpoint de test pour vérifier la configuration
    
    GET /api/weather/test/
    """
    
    def get(self, request):
        # Test avec Abidjan par défaut
        try:
            weather_data = WeatherService.get_weather_for_location(
                latitude=5.3599517,
                longitude=-4.0082563,
                location_name="Abidjan"
            )
            
            return Response({
                "status": "success",
                "message": "Configuration météo opérationnelle",
                "sample_data": weather_data
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                "status": "error",
                "message": "Erreur de configuration",
                "details": str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)