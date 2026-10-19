import 'package:geolocator/geolocator.dart';
import 'package:meteo/Weather/Services/weather_service.dart';
import 'package:weather/weather.dart';

Weather buildWeatherFixture({
  String areaName = 'Niamey',
  String country = 'NE',
  double tempKelvin = 291.55,
  double tempMinKelvin = 290.35,
  double tempMaxKelvin = 293.05,
  String weatherMain = 'Clear',
  String weatherDescription = 'ciel dégagé',
}) {
  return Weather({
    'coord': {'lat': 13.5, 'lon': 2.1},
    'weather': [
      {
        'id': 800,
        'main': weatherMain,
        'description': weatherDescription,
        'icon': '01d',
      },
    ],
    'main': {
      'temp': tempKelvin,
      'feels_like': tempKelvin,
      'temp_min': tempMinKelvin,
      'temp_max': tempMaxKelvin,
      'pressure': 1013,
      'humidity': 40,
    },
    'sys': {
      'country': country,
      'sunrise': 1729210000,
      'sunset': 1729250000,
    },
    'name': areaName,
    'dt': 1729230000,
  });
}

Position buildTestPosition() {
  return Position(
    latitude: 13.5,
    longitude: 2.1,
    timestamp: DateTime(2026, 1, 1),
    accuracy: 1,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

class FakeWeatherService extends WeatherService {
  Object? error;
  Weather? weather;
  int calls = 0;
  double? lastLatitude;
  double? lastLongitude;

  @override
  Future<Weather> getWeather(double lat, double lon) {
    calls++;
    lastLatitude = lat;
    lastLongitude = lon;
    final Object? failure = error;
    if (failure != null) {
      return Future<Weather>.error(failure);
    }
    return Future<Weather>.value(weather ?? buildWeatherFixture());
  }
}
