import json
from datetime import datetime

import requests
from django.templatetags.static import static
from django.views.generic import TemplateView

WEATHER_API_URL = "https://api.open-meteo.com/v1/forecast?latitude={latitude}&longitude={longitude}&current=temperature_2m,is_day,precipitation,cloud_cover&hourly=temperature_2m,precipitation_probability,precipitation,cloud_cover&forecast_days=3"  # noqa: E501


# Create your views here.
class WeatherView(TemplateView):
    template_name = "weather/home.html"
    site_title = "Explore the wevva!"


class WeatherDataView(TemplateView):
    template_name = "weather/weather_data.html"

    def get_timezone_from_geo_coords(self, lat, lon):
        return ""

    def call_weather_api(self):
        latitude = self.request.GET.get("lat", 0)
        longitude = self.request.GET.get("lon", 0)
        # tzone = self.get_timezone_from_geo_coords(latitude, longitude)
        url = WEATHER_API_URL.format(
            latitude=latitude,
            longitude=longitude,
        )
        weather_api_request = requests.get(url)
        json_data = {"error": "Weather API call returned a non-200 status code."}
        if weather_api_request.status_code == 200:
            json_data = json.loads(weather_api_request.content)
        # from pprint import pprint
        # pprint(json_data)
        return json_data

    def format_api_data(self, weather_data):
        weather_data = self.format_lat_lon_values(weather_data)
        weather_data = self.convert_timestamps_to_datetime(weather_data)
        weather_data = self.add_weather_icons(weather_data)
        return weather_data

    def format_lat_lon_values(self, weather_data):
        lat = weather_data["latitude"]
        lon = weather_data["longitude"]
        f_lat = f"{lat}\u00b0 N"
        f_lon = f"{lon}\u00b0 E"
        if lat < 0:
            f_lat = f"{abs(lat)}\u00b0 S"
        if lon < 0:
            f_lon = f"{abs(lon)}\u00b0 W"
        weather_data["latitude"] = f_lat
        weather_data["longitude"] = f_lon
        return weather_data

    def convert_timestamps_to_datetime(self, weather_data):
        for index, iso_timestamp in enumerate(weather_data["hourly"]["time"]):
            f_time = datetime.fromisoformat(iso_timestamp)
            weather_data["hourly"]["time"][index] = f_time
        return weather_data

    def add_weather_icons(self, weather_data):
        weather_data["hourly"]["icons"] = []
        for i in range(len(weather_data["hourly"]["time"])):
            if (
                weather_data["hourly"]["time"][i].hour > 20
                or weather_data["hourly"]["time"][i].hour < 6
            ):
                icon = static("weather/icons/moon.svg")
            else:
                icon = static("weather/icons/sun.svg")
            if weather_data["hourly"]["cloud_cover"][i] > 25:
                icon = static("weather/icons/cloud.svg")
            if weather_data["hourly"]["precipitation"][i] > 0:
                icon = static("weather/icons/cloud-drizzle.svg")
                if weather_data["hourly"]["precipitation"][i] > 2:
                    icon = static("weather/icons/cloud-rain.svg")
                if weather_data["hourly"]["temperature_2m"][i] < 0:
                    icon = static("weather/icons/cloud-snow.svg")
            weather_data["hourly"]["icons"].append(icon)

        return weather_data

    def generate_forecast(self, weather_data):
        temp = weather_data["current"]["temperature_2m"]
        forecast_map = {
            "supercold": """Oh boy, how are you still alive?
                Shouldn't you be frozen like Elsa? My recommendation - GET OUT""",
            "freezing": """Could be worse, but it's still freezing out there.
                May I suggest a nice sauna?""",
            "cold": """Not really freezing, but still kind of cold -
                so wear a nice beanie, a trendy scarf and some dang ol' mittens man""",
            "warm": """Pretty warm! Some would say this is the sweet spot -
                you can walk outside with a t-shirt
                and not get sweaty just walking around. Enjoy!""",
            "hot": """It's warming up, like in a sauna - but it's outside!
                Stay hydrated.""",
            "superhot": """Man, just staying in the shadow makes you sweat -
                consider moving underground, like a lizard(?)""",
            "deadlyhot": """\N{melting face} \N{melting face} \N{melting face}
                RUN. \N{melting face} \N{melting face} \N{melting face}""",
            "no_idea": "I have no idea...",
        }
        forecast_img_map = {
            "supercold": static("weather/img/supercold.jpg"),
            "freezing": static("weather/img/freezing.jpg"),
            "cold": static("weather/img/cold.jpg"),
            "warm": static("weather/img/nice.jpg"),
            "hot": static("weather/img/hot.jpeg"),
            "superhot": static("weather/img/superhot.jpg"),
            "deadlyhot": static("weather/img/deadlyhot.jpg"),
            "no_idea": static("weather/img/nice.jpg"),
        }
        chosen_forecast = None
        match temp:
            case temp if temp < -20:
                chosen_forecast = forecast_map["supercold"]
                forecast_img = forecast_img_map["supercold"]
            case temp if -20 <= temp < 0:
                chosen_forecast = forecast_map["freezing"]
                forecast_img = forecast_img_map["freezing"]
            case temp if 0 <= temp < 10:
                chosen_forecast = forecast_map["cold"]
                forecast_img = forecast_img_map["cold"]
            case temp if 10 <= temp < 25:
                chosen_forecast = forecast_map["warm"]
                forecast_img = forecast_img_map["warm"]
            case temp if 20 <= temp < 30:
                chosen_forecast = forecast_map["hot"]
                forecast_img = forecast_img_map["hot"]
            case temp if 30 <= temp < 40:
                chosen_forecast = forecast_map["superhot"]
                forecast_img = forecast_img_map["superhot"]
            case temp if temp >= 40:
                chosen_forecast = forecast_map["deadlyhot"]
                forecast_img = forecast_img_map["deadlyhot"]
            case _:
                chosen_forecast = forecast_map["no_idea"]
                forecast_img = forecast_img_map["no_idea"]
        return chosen_forecast, forecast_img

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        weather_data = self.format_api_data(self.call_weather_api())
        context["weather_data"] = weather_data
        forecast, forecast_img = self.generate_forecast(weather_data)
        context["forecast"] = forecast
        context["forecast_img"] = forecast_img
        context["hourly_forecast"] = zip(
            weather_data["hourly"]["time"],
            weather_data["hourly"]["temperature_2m"],
            weather_data["hourly"]["icons"],
        )
        return context
