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
  controlButton.classList.add("crosshair-icon");
  buttonDiv.appendChild(controlButton);

  return buttonDiv;
}

function createLocationSpinner(locationButton) {
  const spinner = new mojs.Shape({
    parent: locationButton,
    shape: "circle",
    stroke: "#f58c3b",
    strokeDasharray: "125, 125",
    strokeDashoffset: { 0: "-125" },
    strokeWidth: 4,
    fill: "none",
    left: "50%",
    top: "50%",
    rotate: { "-90": "270" },
    radius: 14,
    isShowStart: true,
    duration: 1200,
    easing: "quart.in",
    repeat: 999,
    isYoyo: true,
  });
  return spinner;
}

function startLocationSpinner(locationButton, spinner) {
  locationButton.classList.remove("crosshair-icon");
  spinner.play();
}

function stopLocationSpinner(locationButton, spinner) {
  locationButton.classList.add("crosshair-icon");
  spinner.stop();
  spinner._hide();
}

function handleLocationError(mapLocationButton, spinner) {
  stopLocationSpinner(mapLocationButton, spinner);
  showSnackbar();
}

function createWeatherDataSpinner() {
  const weatherSpinner = new mojs.Shape({
    parent: "#weather-data-loading-screen",
    shape: "circle",
    stroke: "#f58c3b",
    strokeDasharray: "100%",
    strokeDashoffset: { "-100%": "100%"},
    strokeWidth: 4,
    fill: "none",
    left: "50%",
    top: "50%",
    rotate: "-90",
    radius: 14,
    isShowStart: true,
    duration: 500,
    repeat: 999,
  });
  return weatherSpinner;
}

function startWeatherDataSpinner(weatherDataContainer, loadingScreen, spinner) {
  weatherDataContainer.innerHTML = ""
  loadingScreen.classList.remove("d-none");
  spinner.play();
}

function stopWeatherDataSpinner(loadingScreen, spinner) {
  loadingScreen.classList.add("d-none");
  spinner.stop();
  spinner._hide();
}

async function getWeatherData(lat, lon) {
    coords = {
      "lat": lat,
      "lon": lon,
    };
    const url_params = new URLSearchParams(coords).toString();
    const weatherAPIUrl = new URL(`${window.location.origin}${weatherAPIBaseUrl}?${url_params}`);
    const request = new Request(weatherAPIUrl, {
    method: "GET",
    headers: { "Content-Type": "text/html" },
  });
  return fetch(request)
    .then((response) => {
      return response.text();
    })
    .catch(function(err) {
      console.error(err);
    })
}

async function placeMarker(position, map, weatherDataContainer, loadingScreen, weatherDataSpinner) {
  startWeatherDataSpinner(weatherDataContainer, loadingScreen, weatherDataSpinner);
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
  let weatherData = await getWeatherData(marker.position.Gg, marker.position.Hg);
  displayWeatherData(weatherData);
  stopWeatherDataSpinner(loadingScreen, weatherDataSpinner);
}


function displayWeatherData(dataHTML) {
  const weatherDataContainer = document.getElementById("weather-data");
  weatherDataContainer.innerHTML = dataHTML;
}


async function initMap(weatherDataContainer, loadingScreen, weatherDataSpinner) {
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
    placeMarker(e.latLng, map, weatherDataContainer, loadingScreen, weatherDataSpinner);
  });
  return map;
}

async function addMapGeolocationButton(map) {
  const { Map } = await google.maps.importLibrary("maps");
  const customMapControlDiv = document.createElement("div");
  const locationButtonEl = createCenterOnUserLocationButton(map);
  const locationButton = locationButtonEl.querySelector("button");
  customMapControlDiv.appendChild(locationButtonEl);
  map.controls[google.maps.ControlPosition.TOP_RIGHT].push(
    customMapControlDiv
  );
  return locationButton;
}

async function initGeolocation(map, weatherDataContainer, locationButton, locationSpinner, loadingScreen, weatherDataSpinner) {
  // Ask for permission to get the user's location. If obtained, center map accordingly
  startLocationSpinner(locationButton, locationSpinner);
  navigator.geolocation.getCurrentPosition(
    async function (position) {
      map.setCenter({
        lat: position.coords.latitude,
        lng: position.coords.longitude,
      });
      stopLocationSpinner(locationButton, locationSpinner);
      let coords = new google.maps.LatLng(position.coords.latitude, position.coords.longitude);
      placeMarker(coords, map, weatherDataContainer, loadingScreen, weatherDataSpinner);
      startWeatherDataSpinner(weatherDataContainer, loadingScreen, weatherDataSpinner);
      let weatherData = await getWeatherData(position.coords.latitude, position.coords.longitude);
      displayWeatherData(weatherData);
      stopWeatherDataSpinner(loadingScreen, weatherDataSpinner);
    },
    function () {
      stopLocationSpinner(locationButton, locationSpinner);
      stopWeatherDataSpinner(loadingScreen, weatherDataSpinner);
      handleLocationError(locationButton, locationSpinner);
    }
  );

  locationButton.addEventListener("click", () => {
    startLocationSpinner(locationButton, locationSpinner);
    // Try HTML5 geolocation.
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const pos = {
            lat: position.coords.latitude,
            lng: position.coords.longitude,
          };
          map.setCenter(pos);
          stopLocationSpinner(locationButton, locationSpinner);
          let coords = new google.maps.LatLng(position.coords.latitude, position.coords.longitude);
          placeMarker(coords, map, weatherDataContainer, loadingScreen, weatherDataSpinner);
          startWeatherDataSpinner(weatherDataContainer, loadingScreen, weatherDataSpinner);
          let weatherData = await getWeatherData(position.coords.latitude, position.coords.longitude);
          displayWeatherData(weatherData);
          stopWeatherDataSpinner(loadingScreen, weatherDataSpinner);
        },
        () => {
          stopWeatherDataSpinner(loadingScreen, weatherDataSpinner);
          handleLocationError(locationButton, locationSpinner);
        }
      );
    } else {
      // Browser doesn't support Geolocation
      stopWeatherDataSpinner(loadingScreen, weatherDataSpinner);
      handleLocationError(locationButton, locationSpinner);
    }
  });
}

function showSnackbar() {
  let snackbar = document.getElementById("geolocation-failed-snackbar");
  snackbar.classList.remove("d-none");
  snackbar.classList.remove("m-fadeOut");
  snackbar.classList.add("m-fadeIn");

  setTimeout(hideSnackbar, 3000, snackbar);
}

function hideSnackbar(snackbar) {
  snackbar.classList.remove("m-fadeIn");
  snackbar.classList.add("m-fadeOut");
}

async function init() {
  const weatherDataContainer = document.getElementById("weather-data");
  const loadingScreen = document.getElementById("weather-data-loading-screen");
  const weatherDataSpinner = createWeatherDataSpinner();

  initMap(
    weatherDataContainer,
    loadingScreen,
    weatherDataSpinner,
  ).then(async (map) => {
    const locationButton = await addMapGeolocationButton(map);
    return {map, locationButton}
  }).then(({map, locationButton}) => {
    const locationSpinner = createLocationSpinner(locationButton);
    return {map, locationButton, locationSpinner}
  }).then(({map, locationButton, locationSpinner}) => {
    initGeolocation(map, weatherDataContainer, locationButton, locationSpinner, loadingScreen, weatherDataSpinner);
  })
}

init();