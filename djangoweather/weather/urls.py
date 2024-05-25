from django.urls import path
from weather.views import WeatherDataView, WeatherView

urlpatterns = [
    path("", WeatherView.as_view(), name="index"),
    path("weather_api", WeatherDataView.as_view(), name="call_weather_api"),
]
