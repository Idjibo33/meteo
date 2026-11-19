import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meteo/model/failures.dart';
import 'package:meteo/view/screens/weather_screen.dart';
import 'package:meteo/viewmodel/weather_bloc.dart';

import 'fixtures/weather_fixture.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  WeatherBloc buildBloc({
    required FakeGeolocatorService geolocator,
    FakeWeatherService? weather,
  }) {
    return WeatherBloc(
      weatherService: weather ?? FakeWeatherService(),
      geolocatorService: geolocator,
    );
  }

  test('StartWeather enchaîne localisation, chargement et succès', () async {
    final FakeGeolocatorService geolocator = FakeGeolocatorService();
    final FakeWeatherService weather = FakeWeatherService();
    final WeatherBloc bloc = buildBloc(
      geolocator: geolocator,
      weather: weather,
    );
    addTearDown(bloc.close);

    final List<WeatherState> states = <WeatherState>[];
    final StreamSubscription<WeatherState> subscription = bloc.stream.listen(
      states.add,
    );
    addTearDown(subscription.cancel);

    bloc.add(const StartWeather());
    await bloc.stream.firstWhere(
      (WeatherState state) => state is WeatherSuccess,
    );

    expect(
      states.any((WeatherState state) => state is WeatherLocating),
      isTrue,
    );
    expect(states.any((WeatherState state) => state is WeatherLoading), isTrue);
    final WeatherSuccess success =
        states.lastWhere((WeatherState state) => state is WeatherSuccess)
            as WeatherSuccess;
    expect(success.position.latitude, 13.5);
    expect(success.position.longitude, 2.1);
    expect(geolocator.calls, 1);
    expect(weather.calls, 1);
  });

  test('échec de localisation : raison typée, sans appel météo', () async {
    final FakeGeolocatorService geolocator = FakeGeolocatorService()
      ..error = LocationServiceDisabledException();
    final FakeWeatherService weather = FakeWeatherService();
    final WeatherBloc bloc = buildBloc(
      geolocator: geolocator,
      weather: weather,
    );
    addTearDown(bloc.close);

    bloc.add(const StartWeather());
    final WeatherFailure failure =
        await bloc.stream.firstWhere(
              (WeatherState state) => state is WeatherFailure,
            )
            as WeatherFailure;

    expect(failure.reason, isA<LocationDisabledFailure>());
    expect(failure.message, 'Service de localisation désactivé.');
    expect(failure.position, isNull);
    expect(failure.requiresRelocation, isTrue);
    expect(weather.calls, 0);
  });

  test('RetryLocation reprend la localisation après un échec', () async {
    final FakeGeolocatorService geolocator = FakeGeolocatorService()
      ..error = PermissionDeniedException('denied');
    final WeatherBloc bloc = buildBloc(geolocator: geolocator);
    addTearDown(bloc.close);

    bloc.add(const StartWeather());
    await bloc.stream.firstWhere(
      (WeatherState state) => state is WeatherFailure,
    );
    geolocator.error = null;
    bloc.add(const RetryLocation());
    final WeatherSuccess success =
        await bloc.stream.firstWhere(
              (WeatherState state) => state is WeatherSuccess,
            )
            as WeatherSuccess;

    expect(success.weather.areaName, 'Niamey');
    expect(geolocator.calls, 2);
  });

  test('échec météo : raison typée avec position conservée', () async {
    final FakeGeolocatorService geolocator = FakeGeolocatorService();
    final FakeWeatherService weather = FakeWeatherService()
      ..error = Exception('Invalid API key');
    final WeatherBloc bloc = buildBloc(
      geolocator: geolocator,
      weather: weather,
    );
    addTearDown(bloc.close);

    bloc.add(const StartWeather());
    final WeatherFailure failure =
        await bloc.stream.firstWhere(
              (WeatherState state) => state is WeatherFailure,
            )
            as WeatherFailure;

    expect(failure.reason, isA<ApiKeyFailure>());
    expect(failure.position, isNotNull);
    expect(failure.requiresRelocation, isFalse);
    expect(geolocator.calls, 1);
  });

  test('classification typée des erreurs météo et localisation', () {
    expect(
      classifyWeatherError(Exception('401 Unauthorized')),
      isA<ApiKeyFailure>(),
    );
    expect(classifyWeatherError(TimeoutException('t')), isA<NetworkFailure>());
    expect(classifyWeatherError(StateError('x')), isA<WeatherUnknownFailure>());

    expect(
      classifyLocationError(PermissionDeniedException('denied')),
      isA<LocationPermissionFailure>(),
    );
    expect(
      classifyLocationError(TimeoutException('t')),
      isA<LocationTimeoutFailure>(),
    );
    expect(
      classifyLocationError(StateError('x')),
      isA<LocationUnknownFailure>(),
    );
  });

  testWidgets('le bouton Réessayer suit la raison de l’échec', (tester) async {
    final FakeGeolocatorService geolocator = FakeGeolocatorService()
      ..error = PermissionDeniedException('denied');
    final WeatherBloc bloc = buildBloc(geolocator: geolocator);
    addTearDown(bloc.close);

    bloc.add(const StartWeather());
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<WeatherBloc>.value(
          value: bloc,
          child: const WeatherScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Permission de localisation refusée.'), findsOneWidget);
    geolocator.error = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    await tester.pump();

    expect(geolocator.calls, 2);
    expect(find.byKey(const ValueKey('weather_content')), findsOneWidget);
  });
}
