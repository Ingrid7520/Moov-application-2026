# weather/urls.py

from django.urls import path
from .views import (
    WeatherByCoordinatesView,
    WeatherByCityView,
    WeatherTestView
)

urlpatterns = [
    path('coordinates/', WeatherByCoordinatesView.as_view(), name='weather_coordinates'),
    path('city/', WeatherByCityView.as_view(), name='weather_city'),
    path('test/', WeatherTestView.as_view(), name='weather_test'),
]