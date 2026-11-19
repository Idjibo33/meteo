import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/model/services/weather_service.dart';
import 'package:weather/weather.dart';

import 'fixtures/weather_fixture.dart';

class _FabriqueFausse extends WeatherFactory {
  _FabriqueFausse({
    required this.actuel,
    required this.previsions,
    this.echecForecast = false,
  }) : super('clef-de-test');

  final Weather actuel;
  final List<Weather> previsions;
  final bool echecForecast;
  int appelsCourants = 0;
  int appelsForecast = 0;

  @override
  Future<Weather> currentWeatherByLocation(double lat, double lon) async {
    appelsCourants++;
    return actuel;
  }

  @override
  Future<List<Weather>> fiveDayForecastByLocation(
    double lat,
    double lon,
  ) async {
    appelsForecast++;
    if (echecForecast) {
      throw Exception('forecast indisponible');
    }
    return previsions;
  }
}

void main() {
  test('complète les extremas avec les prévisions du jour', () async {
    final Weather actuel = buildWeatherFixture(
      tempKelvin: 310.15,
      tempMinKelvin: 310.15,
      tempMaxKelvin: 310.15,
      observationEpoch: epochSeconds(DateTime.utc(2026, 11, 19, 10)),
    );
    final _FabriqueFausse fabrique = _FabriqueFausse(
      actuel: actuel,
      previsions: <Weather>[
        buildWeatherFixture(
          tempMinKelvin: 306.15,
          tempMaxKelvin: 314.15,
          observationEpoch: epochSeconds(DateTime.utc(2026, 11, 19, 12)),
        ),
      ],
    );
    final WeatherService service = WeatherService(factory: fabrique);

    final Weather resultat = await service.getWeather(13.5, 2.1);

    expect(fabrique.appelsCourants, 1);
    expect(fabrique.appelsForecast, 1);
    expect(resultat.tempMin?.celsius, closeTo(33, 0.01));
    expect(resultat.tempMax?.celsius, closeTo(41, 0.01));
  });

  test('garde la météo courante si le forecast échoue', () async {
    final Weather actuel = buildWeatherFixture();
    final _FabriqueFausse fabrique = _FabriqueFausse(
      actuel: actuel,
      previsions: const <Weather>[],
      echecForecast: true,
    );
    final WeatherService service = WeatherService(factory: fabrique);

    final Weather resultat = await service.getWeather(13.5, 2.1);

    expect(resultat.tempMin?.celsius, actuel.tempMin?.celsius);
    expect(resultat.tempMax?.celsius, actuel.tempMax?.celsius);
  });
}
