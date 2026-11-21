import 'package:geolocator/geolocator.dart';
import 'package:meteo/model/prevision_jour.dart';
import 'package:meteo/model/services/geolocator_service.dart';
import 'package:meteo/model/services/weather_service.dart';
import 'package:weather/weather.dart';

int epochSeconds(DateTime date) => date.millisecondsSinceEpoch ~/ 1000;

Weather buildWeatherFixture({
  String areaName = 'Niamey',
  String country = 'NE',
  double tempKelvin = 291.55,
  double tempMinKelvin = 290.35,
  double tempMaxKelvin = 293.05,
  String weatherMain = 'Clear',
  String weatherDescription = 'ciel dégagé',
  String weatherIcon = '01d',
  int weatherConditionCode = 800,
  int observationEpoch = 1729230000,
  int fuseau = 3600,
  double? feelsLikeKelvin,
  double? windMetersPerSecond,
  double? windDegree,
  double? humidity,
  double? pressure,
  double? cloudiness,
  double? rainLastHour,
}) {
  return Weather({
    'coord': {'lat': 13.5, 'lon': 2.1},
    'weather': [
      {
        'id': weatherConditionCode,
        'main': weatherMain,
        'description': weatherDescription,
        'icon': weatherIcon,
      },
    ],
    'main': {
      'temp': tempKelvin,
      'feels_like': feelsLikeKelvin ?? tempKelvin,
      'temp_min': tempMinKelvin,
      'temp_max': tempMaxKelvin,
      'pressure': pressure ?? 1013,
      'humidity': humidity ?? 40,
    },
    'wind': {'speed': ?windMetersPerSecond, 'deg': ?windDegree},
    'clouds': {'all': ?cloudiness},
    'rain': {'1h': ?rainLastHour},
    'sys': {'country': country, 'sunrise': 1729210000, 'sunset': 1729250000},
    'name': areaName,
    'dt': observationEpoch,
    'timezone': fuseau,
  });
}

/// Deux tranches par jour sur cinq jours, à midi et 18 h local (fuseau +1).
List<Weather> buildForecastFixture({
  int fuseau = 3600,
  int nombreJours = 5,
  DateTime? departUtc,
}) {
  final DateTime base = departUtc ?? DateTime.utc(2026, 11, 22, 11);
  return List<Weather>.generate(nombreJours * 2, (int index) {
    final DateTime date = base.add(
      Duration(days: index ~/ 2, hours: (index % 2) * 6),
    );
    return buildWeatherFixture(
      observationEpoch: epochSeconds(date),
      fuseau: fuseau,
      tempMinKelvin: 290.15 + index,
      tempMaxKelvin: 300.15 + index,
    );
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
  WeatherReport? rapport;
  int calls = 0;
  double? lastLatitude;
  double? lastLongitude;
  String? lastCity;

  WeatherReport _rapportOuParDefaut() =>
      rapport ?? WeatherReport(actuel: weather ?? buildWeatherFixture());

  @override
  Future<Weather> getWeather(double lat, double lon) async =>
      (await getReport(lat, lon)).actuel;

  @override
  Future<Weather> getWeatherByCity(String ville) async =>
      (await getReportByCity(ville)).actuel;

  @override
  Future<WeatherReport> getReport(double lat, double lon) {
    calls++;
    lastLatitude = lat;
    lastLongitude = lon;
    final Object? failure = error;
    if (failure != null) {
      return Future<WeatherReport>.error(failure);
    }
    return Future<WeatherReport>.value(_rapportOuParDefaut());
  }

  @override
  Future<WeatherReport> getReportByCity(String ville) {
    calls++;
    lastCity = ville;
    final Object? failure = error;
    if (failure != null) {
      return Future<WeatherReport>.error(failure);
    }
    return Future<WeatherReport>.value(_rapportOuParDefaut());
  }
}

class FakeGeolocatorService extends GeolocatorService {
  Object? error;
  Position? position;
  int calls = 0;

  @override
  Future<Position> getPosition() {
    calls++;
    final Object? failure = error;
    if (failure != null) {
      return Future<Position>.error(failure);
    }
    return Future<Position>.value(position ?? buildTestPosition());
  }
}
