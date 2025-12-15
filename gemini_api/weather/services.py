# weather/services.py

import requests
from django.conf import settings
from django.core.cache import cache
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)


class WeatherService:
    """Service de gestion de la météo agricole"""
    
    OPENWEATHER_BASE_URL = "https://api.openweathermap.org/data/2.5"
    CACHE_TIMEOUT = 1800  # 30 minutes
    
    @classmethod
    def get_weather_for_location(cls, latitude, longitude, location_name=None):
        """
        Récupère la météo complète pour une localisation
        
        Args:
            latitude (float): Latitude
            longitude (float): Longitude
            location_name (str): Nom de la localisation (optionnel)
        
        Returns:
            dict: Données météo complètes avec alertes agricoles
        """
        # Vérifier le cache
        cache_key = f"weather_{latitude}_{longitude}"
        cached_data = cache.get(cache_key)
        
        if cached_data:
            logger.info(f"Cache hit pour {cache_key}")
            return cached_data
        
        try:
            # Récupérer les données
            current_weather = cls._get_current_weather(latitude, longitude)
            forecast = cls._get_forecast(latitude, longitude)
            
            # Générer alertes agricoles intelligentes
            alerts = cls._generate_agricultural_alerts(current_weather, forecast)
            
            result = {
                "location": {
                    "name": location_name or "Votre position",
                    "latitude": latitude,
                    "longitude": longitude
                },
                "current": current_weather,
                "forecast": forecast,
                "alerts": alerts,
                "updated_at": datetime.now().isoformat()
            }
            
            # Mettre en cache
            cache.set(cache_key, result, cls.CACHE_TIMEOUT)
            logger.info(f"Données météo mises en cache pour {cache_key}")
            
            return result
            
        except Exception as e:
            logger.error(f"Erreur récupération météo: {e}")
            raise
    
    @classmethod
    def _get_current_weather(cls, lat, lon):
        """Récupère la météo actuelle via OpenWeatherMap"""
        api_key = settings.OPENWEATHER_API_KEY
        url = f"{cls.OPENWEATHER_BASE_URL}/weather"
        
        params = {
            "lat": lat,
            "lon": lon,
            "appid": api_key,
            "units": "metric",
            "lang": "fr"
        }
        
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        return {
            "temperature": round(data["main"]["temp"], 1),
            "feels_like": round(data["main"]["feels_like"], 1),
            "temp_min": round(data["main"]["temp_min"], 1),
            "temp_max": round(data["main"]["temp_max"], 1),
            "humidity": data["main"]["humidity"],
            "pressure": data["main"]["pressure"],
            "description": data["weather"][0]["description"].capitalize(),
            "icon": data["weather"][0]["icon"],
            "main": data["weather"][0]["main"],
            "wind_speed": round(data["wind"]["speed"] * 3.6, 1),  # m/s -> km/h
            "wind_direction": data["wind"].get("deg", 0),
            "clouds": data["clouds"]["all"],
            "visibility": data.get("visibility", 10000) / 1000,  # mètres -> km
            "rain_1h": data.get("rain", {}).get("1h", 0),
            "rain_3h": data.get("rain", {}).get("3h", 0),
            "sunrise": datetime.fromtimestamp(data["sys"]["sunrise"]).strftime("%H:%M"),
            "sunset": datetime.fromtimestamp(data["sys"]["sunset"]).strftime("%H:%M")
        }
    
    @classmethod
    def _get_forecast(cls, lat, lon):
        """Récupère les prévisions sur 5 jours"""
        api_key = settings.OPENWEATHER_API_KEY
        url = f"{cls.OPENWEATHER_BASE_URL}/forecast"
        
        params = {
            "lat": lat,
            "lon": lon,
            "appid": api_key,
            "units": "metric",
            "lang": "fr"
        }
        
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        # Regrouper par jour (prendre les prévisions de midi)
        daily_forecasts = []
        seen_dates = set()
        
        for item in data["list"]:
            dt = datetime.fromtimestamp(item["dt"])
            date_str = dt.strftime("%Y-%m-%d")
            
            # Prendre une prévision par jour (celle de midi de préférence)
            if date_str not in seen_dates and (dt.hour == 12 or len(seen_dates) < 5):
                daily_forecasts.append({
                    "date": date_str,
                    "day_name": cls._get_day_name(dt),
                    "temp": round(item["main"]["temp"], 1),
                    "temp_min": round(item["main"]["temp_min"], 1),
                    "temp_max": round(item["main"]["temp_max"], 1),
                    "humidity": item["main"]["humidity"],
                    "description": item["weather"][0]["description"].capitalize(),
                    "icon": item["weather"][0]["icon"],
                    "rain_probability": round(item.get("pop", 0) * 100),  # Probability of precipitation
                    "rain_mm": item.get("rain", {}).get("3h", 0),
                    "wind_speed": round(item["wind"]["speed"] * 3.6, 1),
                    "clouds": item["clouds"]["all"]
                })
                seen_dates.add(date_str)
            
            if len(daily_forecasts) >= 5:
                break
        
        return daily_forecasts
    
    @classmethod
    def _generate_agricultural_alerts(cls, current, forecast):
        """Génère des alertes intelligentes pour l'agriculture"""
        alerts = []
        
        # 1. ALERTE FORTE PLUIE
        heavy_rain_days = [day for day in forecast if day["rain_probability"] > 70]
        if heavy_rain_days:
            alerts.append({
                "id": "heavy_rain",
                "type": "weather",
                "severity": "high",
                "icon": "⚠️",
                "title": "Fortes pluies prévues",
                "message": f"Risque de pluie élevé dans les {len(heavy_rain_days)} prochains jours.",
                "recommendations": [
                    "Reporter les traitements phytosanitaires",
                    "Vérifier le drainage des parcelles",
                    "Protéger les jeunes plants",
                    "Éviter les applications d'engrais foliaires"
                ],
                "affected_days": [day["day_name"] for day in heavy_rain_days]
            })
        
        # 2. ALERTE SÉCHERESSE
        dry_days = [day for day in forecast if day["rain_probability"] < 20]
        if len(dry_days) >= 3 and current["rain_1h"] == 0:
            alerts.append({
                "id": "drought",
                "type": "weather",
                "severity": "medium",
                "icon": "☀️",
                "title": "Période sèche prolongée",
                "message": f"Pas de pluie significative prévue sur {len(dry_days)} jours.",
                "recommendations": [
                    "Prévoir l'irrigation si possible",
                    "Pailler le sol pour conserver l'humidité",
                    "Surveiller les signes de stress hydrique",
                    "Arroser tôt le matin ou tard le soir"
                ],
                "affected_days": [day["day_name"] for day in dry_days]
            })
        
        # 3. ALERTE FORTE CHALEUR
        hot_days = [day for day in forecast if day["temp_max"] > 35]
        if hot_days or current["temperature"] > 35:
            alerts.append({
                "id": "heat_wave",
                "type": "weather",
                "severity": "high",
                "icon": "🌡️",
                "title": "Températures élevées",
                "message": "Forte chaleur attendue. Risque de stress thermique pour les cultures.",
                "recommendations": [
                    "Augmenter la fréquence d'irrigation",
                    "Ombrager les cultures sensibles si possible",
                    "Éviter les travaux physiques aux heures chaudes",
                    "Surveiller les signes de flétrissement"
                ],
                "affected_days": [day["day_name"] for day in hot_days] if hot_days else ["Aujourd'hui"]
            })
        
        # 4. ALERTE VENT FORT
        windy_days = [day for day in forecast if day["wind_speed"] > 40]
        if windy_days or current["wind_speed"] > 40:
            alerts.append({
                "id": "strong_wind",
                "type": "weather",
                "severity": "medium",
                "icon": "💨",
                "title": "Vents forts prévus",
                "message": "Risque de dommages mécaniques aux cultures.",
                "recommendations": [
                    "Tutorer les plantes hautes",
                    "Reporter les traitements par pulvérisation",
                    "Protéger les jeunes plants",
                    "Vérifier la solidité des structures"
                ],
                "affected_days": [day["day_name"] for day in windy_days] if windy_days else ["Aujourd'hui"]
            })
        
        # 5. ALERTE HUMIDITÉ ÉLEVÉE (risque maladies)
        humid_days = [day for day in forecast if day["humidity"] > 85]
        if len(humid_days) >= 2 or current["humidity"] > 85:
            alerts.append({
                "id": "high_humidity",
                "type": "disease_risk",
                "severity": "medium",
                "icon": "💧",
                "title": "Humidité élevée - Risque de maladies",
                "message": "Conditions favorables au développement de champignons.",
                "recommendations": [
                    "Surveiller l'apparition de maladies fongiques",
                    "Espacer les plants pour améliorer l'aération",
                    "Éviter l'arrosage en soirée",
                    "Envisager un traitement préventif si nécessaire"
                ],
                "affected_days": [day["day_name"] for day in humid_days]
            })
        
        # 6. CONDITIONS IDÉALES
        if not alerts:
            optimal_days = [day for day in forecast[:3] if 
                          20 < day["temp_max"] < 32 and 
                          30 < day["rain_probability"] < 60 and
                          day["wind_speed"] < 30]
            
            if optimal_days:
                alerts.append({
                    "id": "optimal",
                    "type": "weather",
                    "severity": "low",
                    "icon": "✅",
                    "title": "Conditions favorables",
                    "message": "Bonnes conditions pour les travaux agricoles.",
                    "recommendations": [
                        "Bon moment pour planter",
                        "Conditions idéales pour les traitements",
                        "Période propice aux récoltes",
                        "Profitez-en pour les travaux de terrain"
                    ],
                    "affected_days": [day["day_name"] for day in optimal_days]
                })
        
        return alerts
    
    @classmethod
    def _get_day_name(cls, dt):
        """Retourne le nom du jour en français"""
        days = {
            0: "Lundi",
            1: "Mardi",
            2: "Mercredi",
            3: "Jeudi",
            4: "Vendredi",
            5: "Samedi",
            6: "Dimanche"
        }
        
        today = datetime.now().date()
        day_date = dt.date()
        
        if day_date == today:
            return "Aujourd'hui"
        elif day_date == today + timedelta(days=1):
            return "Demain"
        else:
            return days[dt.weekday()]
    
    @classmethod
    def get_weather_by_city(cls, city_name):
        """
        Récupère la météo par nom de ville
        
        Args:
            city_name (str): Nom de la ville
        
        Returns:
            dict: Données météo
        """
        # D'abord géocoder la ville pour obtenir lat/lon
        api_key = settings.OPENWEATHER_API_KEY
        geo_url = "http://api.openweathermap.org/geo/1.0/direct"
        
        params = {
            "q": f"{city_name},CI",  # CI pour Côte d'Ivoire
            "limit": 1,
            "appid": api_key
        }
        
        response = requests.get(geo_url, params=params, timeout=10)
        response.raise_for_status()
        geo_data = response.json()
        
        if not geo_data:
            raise ValueError(f"Ville '{city_name}' introuvable en Côte d'Ivoire")
        
        lat = geo_data[0]["lat"]
        lon = geo_data[0]["lon"]
        location_name = geo_data[0]["name"]
        
        return cls.get_weather_for_location(lat, lon, location_name)