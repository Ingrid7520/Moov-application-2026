# weather/services.py

import requests
import json
import logging
from django.conf import settings
from django.core.cache import cache
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)


class WeatherService:
    """Service de gestion de la météo agricole"""

    OPENWEATHER_BASE_URL = "https://api.openweathermap.org/data/2.5"
    CACHE_TIMEOUT = 1800  # 30 minutes

    @classmethod
    def get_weather_for_location(cls, latitude, longitude, location_name=None):
        """
        Récupère la météo complète pour une localisation
        """
        cache_key = f"weather_{latitude}_{longitude}"
        cached_data = cache.get(cache_key)

        if cached_data:
            logger.info(f"Cache hit pour {cache_key}")
            return cached_data

        try:
            # Récupérer le forecast d'abord pour pouvoir enrichir le current
            forecast = cls._get_forecast(latitude, longitude)

            current_weather = cls._get_current_weather(latitude, longitude, forecast=forecast)

            # Génération des alertes via Gemini (avec fallback)
            alerts = cls._generate_agricultural_alerts_with_gemini(
                location_name or "Votre position",
                current_weather,
                forecast
            )

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

            cache.set(cache_key, result, cls.CACHE_TIMEOUT)
            logger.info(f"Données météo mises en cache pour {cache_key}")

            return result

        except Exception as e:
            logger.error(f"Erreur récupération météo: {e}", exc_info=True)
            raise

    @classmethod
    def _get_current_weather(cls, lat, lon, forecast=None):
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

        # Utilisation des vraies min/max du jour depuis le forecast si disponible
        today_min = forecast[0]["temp_min"] if forecast else data["main"]["temp_min"]
        today_max = forecast[0]["temp_max"] if forecast else data["main"]["temp_max"]

        return {
            "temperature": round(data["main"]["temp"], 1),
            "feels_like": round(data["main"]["feels_like"], 1),
            "temp_min": round(today_min, 1),
            "temp_max": round(today_max, 1),
            "humidity": data["main"]["humidity"],
            "pressure": data["main"]["pressure"],
            "description": data["weather"][0]["description"].capitalize(),
            "icon": data["weather"][0]["icon"],
            "main": data["weather"][0]["main"],
            "wind_speed": round(data["wind"]["speed"] * 3.6, 1),  # m/s -> km/h
            "wind_direction": data["wind"].get("deg", 0),
            "clouds": data["clouds"]["all"],
            "visibility": data.get("visibility", 10000) / 1000,
            "rain_1h": data.get("rain", {}).get("1h", 0),
            "rain_3h": data.get("rain", {}).get("3h", 0),
            "sunrise": datetime.fromtimestamp(data["sys"]["sunrise"]).strftime("%H:%M"),
            "sunset": datetime.fromtimestamp(data["sys"]["sunset"]).strftime("%H:%M")
        }

    @classmethod
    def _get_forecast(cls, lat, lon):
        """Récupère et agrège les prévisions sur 5 jours"""
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

        daily_data = {}

        for item in data["list"]:
            dt = datetime.fromtimestamp(item["dt"])
            date_str = dt.strftime("%Y-%m-%d")

            if date_str not in daily_data:
                daily_data[date_str] = {
                    "dt": dt,
                    "temps": [],
                    "temp_mins": [],
                    "temp_maxs": [],
                    "humidities": [],
                    "pops": [],
                    "rain_mm": 0,
                    "wind_speeds": [],
                    "clouds": [],
                    "descriptions": [],
                    "icons": [],
                }

            main = item["main"]
            weather = item["weather"][0]

            day = daily_data[date_str]
            day["temps"].append(main["temp"])
            day["temp_mins"].append(main["temp_min"])
            day["temp_maxs"].append(main["temp_max"])
            day["humidities"].append(main["humidity"])
            day["pops"].append(item.get("pop", 0))
            day["rain_mm"] += item.get("rain", {}).get("3h", 0)
            day["wind_speeds"].append(item["wind"]["speed"])
            day["clouds"].append(item["clouds"]["all"])
            day["descriptions"].append(weather["description"])
            day["icons"].append(weather["icon"])

        daily_forecasts = []
        sorted_dates = sorted(daily_data.keys())[:5]

        for date_str in sorted_dates:
            day = daily_data[date_str]

            dominant_icon = max(set(day["icons"]), key=day["icons"].count)
            dominant_description = max(set(day["descriptions"]), key=day["descriptions"].count).capitalize()

            daily_forecasts.append({
                "date": date_str,
                "day_name": cls._get_day_name(day["dt"]),
                "temp": round(sum(day["temps"]) / len(day["temps"]), 1),
                "temp_min": round(min(day["temp_mins"]), 1),
                "temp_max": round(max(day["temp_maxs"]), 1),
                "humidity": round(sum(day["humidities"]) / len(day["humidities"])),
                "description": dominant_description,
                "icon": dominant_icon,
                "rain_probability": round(max(day["pops"]) * 100),
                "rain_mm": round(day["rain_mm"], 1),
                "wind_speed": round(max(day["wind_speeds"]) * 3.6, 1),
                "clouds": round(sum(day["clouds"]) / len(day["clouds"]))
            })

        return daily_forecasts

    @classmethod
    def _generate_agricultural_alerts_with_gemini(cls, location_name, current, forecast):
        """Génère des alertes via Gemini avec fallback sur version statique"""
        forecast_summary = "\n".join([
            f"- {day['day_name']} ({day['date']}): {day['temp_min']}–{day['temp_max']}°C, "
            f"humidité {day['humidity']}%, pluie {day['rain_probability']}%, vent {day['wind_speed']} km/h"
            for day in forecast
        ])

        prompt = f"""
Tu es un expert agronome spécialisé en agriculture tropicale en Côte d'Ivoire.
Analyse les données météo ci-dessous et génère entre 0 et 6 alertes agricoles pertinentes pour les cultures principales : cacao, riz, manioc, café, igname, banane plantain.

Priorités connues :
- Cacao : très sensible à l'humidité élevée (>80%) + chaleur → risque black pod et maladies fongiques ; aussi sensible à la sécheresse et à l'harmattan.
- Riz et manioc : risque d'inondation ou de sécheresse prolongée.
- Général : stress thermique (>35°C), vents forts, conditions idéales pour travaux.

Si aucune risque majeur, génère une alerte positive "conditions favorables".

Utilise des emojis pertinents dans les titres et messages.

Réponds EXCLUSIVEMENT en JSON valide avec cette structure :
{{
  "alerts": [
    {{
      "id": "unique_id_en_minuscules",
      "severity": "high|medium|low",
      "title": "Titre court avec emoji",
      "message": "Message clair et engageant",
      "recommendations": ["Conseil 1", "Conseil 2", "Conseil 3", "Conseil 4"]
    }}
  ]
}}

Données météo :
Localisation : {location_name}
Actuel : {current['temperature']}°C (ressenti {current['feels_like']}°C), humidité {current['humidity']}%, vent {current['wind_speed']} km/h
Prévisions 5 jours :
{forecast_summary}
"""

        try:
            chat_response = requests.post(
                "http://localhost:8000/api/chat/",  # À adapter si URL différente en prod
                json={"message": prompt},
                timeout=30
            )
            chat_response.raise_for_status()
            gemini_output = chat_response.json().get("response", "")  # Adaptez selon ta structure de réponse

            # Extraction du JSON (Gemini peut ajouter du texte autour)
            start = gemini_output.find("{")
            end = gemini_output.rfind("}") + 1
            if start == -1 or end == 0:
                raise ValueError("Aucun JSON trouvé dans la réponse Gemini")
            json_str = gemini_output[start:end]
            alerts_data = json.loads(json_str)
            alerts = alerts_data.get("alerts", [])

            logger.info(f"Alertes générées par Gemini : {len(alerts)} alerte(s)")
            return alerts

        except Exception as e:
            logger.error(f"Échec génération alertes Gemini : {e}. Utilisation du fallback statique.")
            return cls._generate_agricultural_alerts_static(current, forecast)

    @classmethod
    def _generate_agricultural_alerts_static(cls, current, forecast):
        """Fallback : version statique originale (au cas où Gemini échoue)"""
        alerts = []

        heavy_rain_days = [day for day in forecast if day["rain_probability"] > 70]
        if heavy_rain_days:
            alerts.append({
                "id": "heavy_rain",
                "severity": "high",
                "title": "Fortes pluies prévues",
                "message": f"Risque de pluie élevé dans les {len(heavy_rain_days)} prochains jours.",
                "recommendations": [
                    "Reporter les traitements phytosanitaires",
                    "Vérifier le drainage des parcelles",
                    "Protéger les jeunes plants",
                    "Éviter les applications d'engrais foliaires"
                ]
            })

        dry_days = [day for day in forecast if day["rain_probability"] < 20]
        if len(dry_days) >= 3 and current["rain_1h"] == 0:
            alerts.append({
                "id": "drought",
                "severity": "medium",
                "title": "Période sèche prolongée",
                "message": f"Pas de pluie significative prévue sur {len(dry_days)} jours.",
                "recommendations": [
                    "Prévoir l'irrigation si possible",
                    "Pailler le sol pour conserver l'humidité",
                    "Surveiller les signes de stress hydrique",
                    "Arroser tôt le matin ou tard le soir"
                ]
            })

        hot_days = [day for day in forecast if day["temp_max"] > 35]
        if hot_days or current["temperature"] > 35:
            alerts.append({
                "id": "heat_wave",
                "severity": "high",
                "title": "Températures élevées",
                "message": "Forte chaleur attendue. Risque de stress thermique pour les cultures.",
                "recommendations": [
                    "Augmenter la fréquence d'irrigation",
                    "Ombrager les cultures sensibles si possible",
                    "Éviter les travaux physiques aux heures chaudes",
                    "Surveiller les signes de flétrissement"
                ]
            })

        windy_days = [day for day in forecast if day["wind_speed"] > 40]
        if windy_days or current["wind_speed"] > 40:
            alerts.append({
                "id": "strong_wind",
                "severity": "medium",
                "title": "Vents forts prévus",
                "message": "Risque de dommages mécaniques aux cultures.",
                "recommendations": [
                    "Tutorer les plantes hautes",
                    "Reporter les traitements par pulvérisation",
                    "Protéger les jeunes plants",
                    "Vérifier la solidité des structures"
                ]
            })

        humid_days = [day for day in forecast if day["humidity"] > 85]
        if len(humid_days) >= 2 or current["humidity"] > 85:
            alerts.append({
                "id": "high_humidity",
                "severity": "medium",
                "title": "Humidité élevée - Risque de maladies",
                "message": "Conditions favorables au développement de champignons.",
                "recommendations": [
                    "Surveiller l'apparition de maladies fongiques",
                    "Espacer les plants pour améliorer l'aération",
                    "Éviter l'arrosage en soirée",
                    "Envisager un traitement préventif si nécessaire"
                ]
            })

        if not alerts:
            optimal_days = [day for day in forecast[:3]
                            if 20 < day["temp_max"] < 32 and 30 < day["rain_probability"] < 60 and day["wind_speed"] < 30]
            if optimal_days:
                alerts.append({
                    "id": "optimal",
                    "severity": "low",
                    "title": "Conditions favorables",
                    "message": "Bonnes conditions pour les travaux agricoles.",
                    "recommendations": [
                        "Bon moment pour planter",
                        "Conditions idéales pour les traitements",
                        "Période propice aux récoltes",
                        "Profitez-en pour les travaux de terrain"
                    ]
                })

        return alerts

    @classmethod
    def _get_day_name(cls, dt):
        days = {0: "Lundi", 1: "Mardi", 2: "Mercredi", 3: "Jeudi", 4: "Vendredi", 5: "Samedi", 6: "Dimanche"}
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
        """Récupère la météo par nom de ville"""
        api_key = settings.OPENWEATHER_API_KEY
        geo_url = "https://api.openweathermap.org/geo/1.0/direct"

        params = {
            "q": f"{city_name},CI",
            "limit": 1,
            "appid": api_key
        }

        response = requests.get(geo_url, params=params, timeout=10)
        logger.info(f"Geocoding status: {response.status_code}")
        logger.debug(f"Geocoding response: {response.text[:500]}")

        response.raise_for_status()
        geo_data = response.json()

        if not geo_data:
            raise ValueError(f"Ville '{city_name}' introuvable en Côte d'Ivoire")

        lat = geo_data[0]["lat"]
        lon = geo_data[0]["lon"]
        location_name = geo_data[0]["name"]

        return cls.get_weather_for_location(lat, lon, location_name)