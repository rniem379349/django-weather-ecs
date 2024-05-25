let marker;
const weatherAPIBaseUrl = document
  .querySelector("#weather_api_url")
  .getAttribute("data-url");


function createCenterOnUserLocationButton(map) {
  // Create a "center on user's location" button for the custom map controls
  const buttonDiv = document.createElement("div");
  buttonDiv.classList.add("map-button-background");
  const controlButton = document.createElement("button");
  controlButton.title = "Click to center the map on your location";
  controlButton.type = "button";
  controlButton.classList.add("map-center-on-location-button");
  buttonDiv.appendChild(controlButton);

  // Add the user location icon button
  // const icon = document.createElement("span");
  // icon.classList.add("material-icons");
  // icon.innerText = "my_location";
  // controlButton.appendChild(icon);

  return buttonDiv;
}


async function getWeatherData(position) {
    console.log(position);
    console.log(weatherAPIBaseUrl);
    coords = {
      "lat": position.Gg,
      "lon": position.Hg,
    };
    const url_params = new URLSearchParams(coords).toString();
    console.log(url_params)
    const weatherAPIUrl = new URL(`${window.location.origin}${weatherAPIBaseUrl}?${url_params}`);
    console.log(weatherAPIUrl);
    const request = new Request(weatherAPIUrl, {
    method: "GET",
    headers: { "Content-Type": "text/html" },
  });
  return fetch(request)
    .then((response) => {
      console.log('rresp', response);
      return response.text();
    })
    .catch(function(err) {
      console.log('error: ', err);
    })
}

async function placeMarker(position, map) {
  const { AdvancedMarkerElement } = await google.maps.importLibrary("marker");
  if (marker == null) {
    marker = new AdvancedMarkerElement({
      position: position,
      map: map
    });
  } else {
    marker.position = position;
  }
  map.panTo(position);
  let weatherData = await getWeatherData(marker.position);
  displayWeatherData(weatherData);
}


function displayWeatherData(dataHTML) {
  const weatherDataContainer = document.getElementById("weather-data");
  weatherDataContainer.innerHTML = dataHTML;
}


async function initMap() {
  const { Map } = await google.maps.importLibrary("maps");
  const mapOptions = {
    center: { lat: 50.0630014, lng: 19.9369794 },
    clickableIcons: false,
    fullscreenControl: false,
    mapTypeControl: false,
    streetViewControl: false,
    zoom: 4,
    mapId: '341a5b9eaceb1994',
  };

  const map = new Map(document.getElementById("map"), mapOptions);
  map.addListener('click', (e) => {
    placeMarker(e.latLng, map);
  });
  const customMapControlDiv = document.createElement("div");
  const locationButton = createCenterOnUserLocationButton(map);
  customMapControlDiv.appendChild(locationButton);
  console.log('mapcont: ', customMapControlDiv);
  map.controls[google.maps.ControlPosition.TOP_RIGHT].push(
    customMapControlDiv
  );
}

initMap();
