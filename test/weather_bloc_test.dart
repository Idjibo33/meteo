import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/Weather/bloc/weather_bloc.dart';

import 'fixtures/weather_fixture.dart';

void main() {
  test('émet WeatherSuccess quand le service répond', () async {
    final FakeWeatherService service = FakeWeatherService();
    final WeatherBloc bloc = WeatherBloc(weatherService: service);
    addTearDown(bloc.close);

    bloc.add(FetchWeather(buildTestPosition()));
    final WeatherState state = await bloc.stream.firstWhere(
      (WeatherState state) => state is WeatherSuccess,
    );

    expect(service.calls, 1);
    expect(service.lastLatitude, 13.5);
    expect(service.lastLongitude, 2.1);
    expect((state as WeatherSuccess).weather.areaName, 'Niamey');
  });

  test('émet un message convivial quand le service échoue', () async {
    final FakeWeatherService service = FakeWeatherService()
      ..error = Exception('Invalid API key');
    final WeatherBloc bloc = WeatherBloc(weatherService: service);
    addTearDown(bloc.close);

    bloc.add(FetchWeather(buildTestPosition()));
    final WeatherState state = await bloc.stream.firstWhere(
      (WeatherState state) => state is WeatherFailure,
    );

    expect(
      (state as WeatherFailure).message,
      'Clé API météo manquante ou invalide.',
    );
  });

  test('RefreshWeather relance la dernière position connue', () async {
    final FakeWeatherService service = FakeWeatherService()
      ..error = Exception('Invalid API key');
    final WeatherBloc bloc = WeatherBloc(weatherService: service);
    addTearDown(bloc.close);

    bloc.add(FetchWeather(buildTestPosition()));
    await bloc.stream.firstWhere(
      (WeatherState state) => state is WeatherFailure,
    );

    service.error = null;
    bloc.add(RefreshWeather());
    final WeatherState state = await bloc.stream.firstWhere(
      (WeatherState state) => state is WeatherSuccess,
    );

    expect(service.calls, 2);
    expect((state as WeatherSuccess).weather.areaName, 'Niamey');
  });

  test('RefreshWeather sans position connue ne fait aucun appel', () async {
    final FakeWeatherService service = FakeWeatherService();
    final WeatherBloc bloc = WeatherBloc(weatherService: service);
    addTearDown(bloc.close);

    bloc.add(RefreshWeather());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(service.calls, 0);
    expect(bloc.state, isA<WeatherInitial>());
  });
}
