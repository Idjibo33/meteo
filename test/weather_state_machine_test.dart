import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meteo/model/failures.dart';
import 'package:meteo/theme.dart';
import 'package:meteo/view/screens/weather_screen.dart';
import 'package:meteo/viewmodel/theme_cubit.dart';
import 'package:meteo/viewmodel/weather_bloc.dart';
import 'package:weather/weather.dart';

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
    expect(success.position!.latitude, 13.5);
    expect(success.position!.longitude, 2.1);
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

    final ThemeCubit themeCubit = ThemeCubit();
    addTearDown(themeCubit.close);

    bloc.add(const StartWeather());
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<WeatherBloc>.value(value: bloc),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
        ],
        child: MaterialApp(
          theme: themeClair,
          darkTheme: themeSombre,
          themeMode: ThemeMode.dark,
          home: const WeatherScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Permission de localisation refusée.'), findsOneWidget);
    expect(find.byKey(const ValueKey('recherche_ville')), findsOneWidget);
    geolocator.error = null;
    await tester.tap(find.text('Réessayer la localisation'));
    await tester.pump();
    await tester.pump();

    expect(geolocator.calls, 2);
    expect(find.byKey(const ValueKey('weather_content')), findsOneWidget);
  });

  test(
    'AppResumed rafraîchit une observation périmée sans repositionner',
    () async {
      final FakeGeolocatorService geolocator = FakeGeolocatorService();
      final FakeWeatherService weather = FakeWeatherService();
      final WeatherBloc bloc = buildBloc(
        geolocator: geolocator,
        weather: weather,
      );
      addTearDown(bloc.close);

      bloc.add(const StartWeather());
      await bloc.stream.firstWhere(
        (WeatherState state) => state is WeatherSuccess,
      );

      bloc.add(const AppResumed());
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(weather.calls, 2);
      expect(geolocator.calls, 1);
    },
  );

  test('AppResumed respecte une observation encore fraîche', () async {
    final FakeGeolocatorService geolocator = FakeGeolocatorService();
    final FakeWeatherService weather = FakeWeatherService()
      ..weather = buildWeatherFixture(
        observationEpoch: epochSeconds(
          DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      );
    final WeatherBloc bloc = buildBloc(
      geolocator: geolocator,
      weather: weather,
    );
    addTearDown(bloc.close);

    bloc.add(const StartWeather());
    await bloc.stream.firstWhere(
      (WeatherState state) => state is WeatherSuccess,
    );

    bloc.add(const AppResumed());
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(weather.calls, 1);
    expect(geolocator.calls, 1);
  });

  test('AppResumed relance une météo en échec avec sa position', () async {
    final FakeGeolocatorService geolocator = FakeGeolocatorService();
    final FakeWeatherService weather = FakeWeatherService()
      ..error = Exception('timeout');
    final WeatherBloc bloc = buildBloc(
      geolocator: geolocator,
      weather: weather,
    );
    addTearDown(bloc.close);

    bloc.add(const StartWeather());
    await bloc.stream.firstWhere(
      (WeatherState state) => state is WeatherFailure,
    );

    weather.error = null;
    bloc.add(const AppResumed());
    final WeatherSuccess success =
        await bloc.stream.firstWhere(
              (WeatherState state) => state is WeatherSuccess,
            )
            as WeatherSuccess;

    expect(success.position!.latitude, 13.5);
    expect(weather.calls, 2);
    expect(geolocator.calls, 1);
  });

  test('un tick périodique rafraîchit avec la position déjà connue', () async {
    final StreamController<void> ticks = StreamController<void>.broadcast();
    addTearDown(ticks.close);
    final FakeGeolocatorService geolocator = FakeGeolocatorService();
    final FakeWeatherService weather = FakeWeatherService()
      ..weather = buildWeatherFixture(
        observationEpoch: epochSeconds(
          DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      );
    final WeatherBloc bloc = WeatherBloc(
      weatherService: weather,
      geolocatorService: geolocator,
      refreshTicks: (_) => ticks.stream,
    );
    addTearDown(bloc.close);

    bloc.add(const StartWeather());
    await bloc.stream.firstWhere(
      (WeatherState state) => state is WeatherSuccess,
    );

    ticks.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(weather.calls, 2);
    expect(geolocator.calls, 1);
  });

  test(
    'le générateur de ticks par défaut déclenche un rafraîchissement',
    () async {
      final FakeWeatherService weather = FakeWeatherService()
        ..weather = buildWeatherFixture(
          observationEpoch: epochSeconds(
            DateTime.now().subtract(const Duration(minutes: 2)),
          ),
        );
      final WeatherBloc bloc = WeatherBloc(
        weatherService: weather,
        geolocatorService: FakeGeolocatorService(),
        refreshInterval: const Duration(milliseconds: 10),
      );
      addTearDown(bloc.close);

      bloc.add(FetchWeather(buildTestPosition()));
      await bloc.stream.firstWhere(
        (WeatherState state) => state is WeatherSuccess,
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(weather.calls, greaterThanOrEqualTo(2));
    },
  );

  test('AppPaused suspend les ticks et AppResumed les relance', () async {
    final StreamController<void> ticks = StreamController<void>.broadcast();
    addTearDown(ticks.close);
    final FakeGeolocatorService geolocator = FakeGeolocatorService();
    final FakeWeatherService weather = FakeWeatherService()
      ..weather = buildWeatherFixture(
        observationEpoch: epochSeconds(
          DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      );
    final WeatherBloc bloc = WeatherBloc(
      weatherService: weather,
      geolocatorService: geolocator,
      refreshTicks: (_) => ticks.stream,
    );
    addTearDown(bloc.close);

    bloc.add(const StartWeather());
    await bloc.stream.firstWhere(
      (WeatherState state) => state is WeatherSuccess,
    );

    bloc.add(const AppPaused());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    ticks.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(weather.calls, 1);

    bloc.add(const AppResumed());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    ticks.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(weather.calls, 2);
    expect(geolocator.calls, 1);
  });

  test(
    'un chargement terminé en arrière-plan ne relance pas les ticks',
    () async {
      final StreamController<void> ticks = StreamController<void>.broadcast();
      addTearDown(ticks.close);
      final _WeatherServiceBloquant service = _WeatherServiceBloquant();
      final WeatherBloc bloc = WeatherBloc(
        weatherService: service,
        geolocatorService: FakeGeolocatorService(),
        refreshTicks: (_) => ticks.stream,
      );
      addTearDown(bloc.close);

      bloc.add(FetchWeather(buildTestPosition()));
      await bloc.stream.firstWhere(
        (WeatherState state) => state is WeatherLoading,
      );
      bloc.add(const AppPaused());
      service.completer.complete(
        buildWeatherFixture(
          observationEpoch: epochSeconds(
            DateTime.now().subtract(const Duration(minutes: 2)),
          ),
        ),
      );
      await bloc.stream.firstWhere(
        (WeatherState state) => state is WeatherSuccess,
      );

      ticks.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(service.calls, 1);
    },
  );

  test(
    'pause/resume rapide pendant une annulation lente relance les ticks',
    () async {
      final List<StreamController<void>> controllers =
          <StreamController<void>>[];
      final Completer<void> annulationLente = Completer<void>();
      final FakeWeatherService weather = FakeWeatherService()
        ..weather = buildWeatherFixture(
          observationEpoch: epochSeconds(
            DateTime.now().subtract(const Duration(minutes: 2)),
          ),
        );
      final WeatherBloc bloc = WeatherBloc(
        weatherService: weather,
        geolocatorService: FakeGeolocatorService(),
        refreshTicks: (_) {
          final StreamController<void> controller = StreamController<void>(
            onCancel: () => annulationLente.future,
          );
          controllers.add(controller);
          return controller.stream;
        },
      );
      addTearDown(bloc.close);
      addTearDown(() async {
        for (final StreamController<void> controller in controllers) {
          if (!controller.isClosed) {
            await controller.close();
          }
        }
      });

      bloc.add(FetchWeather(buildTestPosition()));
      await bloc.stream.firstWhere(
        (WeatherState state) => state is WeatherSuccess,
      );
      expect(controllers, hasLength(1));

      bloc.add(const AppPaused());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const AppResumed());
      await Future<void>.delayed(Duration.zero);

      annulationLente.complete();
      await Future<void>.delayed(Duration.zero);

      expect(controllers, hasLength(2));
      controllers.last.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(weather.calls, 2);
    },
  );

  test('close annule l’abonnement aux ticks', () async {
    final StreamController<void> ticks = StreamController<void>.broadcast();
    addTearDown(ticks.close);
    final WeatherBloc bloc = WeatherBloc(
      weatherService: FakeWeatherService(),
      geolocatorService: FakeGeolocatorService(),
      refreshTicks: (_) => ticks.stream,
    );

    bloc.add(FetchWeather(buildTestPosition()));
    await bloc.stream.firstWhere(
      (WeatherState state) => state is WeatherSuccess,
    );
    await bloc.close();

    expect(ticks.hasListener, isFalse);
  });

  test(
    'RefreshWeather pendant un chargement ne duplique pas l’appel',
    () async {
      final _WeatherServiceBloquant service = _WeatherServiceBloquant();
      final WeatherBloc bloc = WeatherBloc(
        weatherService: service,
        geolocatorService: FakeGeolocatorService(),
      );
      addTearDown(bloc.close);

      bloc.add(FetchWeather(buildTestPosition()));
      await bloc.stream.firstWhere(
        (WeatherState state) => state is WeatherLoading,
      );

      bloc.add(const RefreshWeather());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(service.calls, 1);

      service.completer.complete(buildWeatherFixture());
      await bloc.stream.firstWhere(
        (WeatherState state) => state is WeatherSuccess,
      );
    },
  );

  test(
    'WeatherLoading porte la dernière météo connue au rafraîchissement',
    () async {
      final FakeWeatherService weather = FakeWeatherService();
      final WeatherBloc bloc = WeatherBloc(
        weatherService: weather,
        geolocatorService: FakeGeolocatorService(),
      );
      addTearDown(bloc.close);

      bloc.add(FetchWeather(buildTestPosition()));
      final WeatherSuccess initial =
          await bloc.stream.firstWhere(
                (WeatherState state) => state is WeatherSuccess,
              )
              as WeatherSuccess;

      final Future<WeatherState> chargement = bloc.stream.firstWhere(
        (WeatherState state) => state is WeatherLoading,
      );
      bloc.add(const RefreshWeather());
      final WeatherLoading state = await chargement as WeatherLoading;

      expect(state.derniereMeteo, same(initial.weather));
      expect(state.position!.latitude, 13.5);
    },
  );

  test('SearchCity utilise la ville sans jamais géolocaliser', () async {
    final FakeGeolocatorService geolocator = FakeGeolocatorService();
    final FakeWeatherService weather = FakeWeatherService();
    final WeatherBloc bloc = buildBloc(
      geolocator: geolocator,
      weather: weather,
    );
    addTearDown(bloc.close);

    bloc.add(const SearchCity('  Paris  '));
    final WeatherSuccess success =
        await bloc.stream.firstWhere(
              (WeatherState state) => state is WeatherSuccess,
            )
            as WeatherSuccess;

    expect(success.ville, 'Paris');
    expect(success.position, isNull);
    expect(weather.lastCity, 'Paris');
    expect(weather.lastLatitude, isNull);
    expect(geolocator.calls, 0);
  });

  test('un refresh après recherche réutilise la ville', () async {
    final FakeWeatherService weather = FakeWeatherService();
    final WeatherBloc bloc = buildBloc(
      geolocator: FakeGeolocatorService(),
      weather: weather,
    );
    addTearDown(bloc.close);

    bloc.add(const SearchCity('Lyon'));
    await bloc.stream.firstWhere((WeatherState state) => state is WeatherSuccess);

    final Future<WeatherState> chargement = bloc.stream.firstWhere(
      (WeatherState state) => state is WeatherLoading,
    );
    bloc.add(const RefreshWeather());
    final WeatherLoading loading = await chargement as WeatherLoading;

    expect(loading.ville, 'Lyon');
    expect(loading.position, isNull);
    expect(weather.calls, 2);
    expect(weather.lastCity, 'Lyon');
  });

  test('après refus de localisation, la saisie d une ville reprend', () async {
    final FakeGeolocatorService geolocator = FakeGeolocatorService()
      ..error = PermissionDeniedException('denied');
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
    expect(failure.reason, isA<LocationPermissionFailure>());

    bloc.add(const SearchCity('Niamey'));
    final WeatherSuccess success =
        await bloc.stream.firstWhere(
              (WeatherState state) => state is WeatherSuccess,
            )
            as WeatherSuccess;

    expect(success.ville, 'Niamey');
    expect(weather.lastCity, 'Niamey');
    expect(geolocator.calls, 1);
  });

  test('ville introuvable : raison typée et ville conservée', () async {
    final FakeWeatherService weather = FakeWeatherService()
      ..error = Exception('404 city not found');
    final WeatherBloc bloc = buildBloc(
      geolocator: FakeGeolocatorService(),
      weather: weather,
    );
    addTearDown(bloc.close);

    bloc.add(const SearchCity('VilleQuiNexistePas'));
    final WeatherFailure failure =
        await bloc.stream.firstWhere(
              (WeatherState state) => state is WeatherFailure,
            )
            as WeatherFailure;

    expect(failure.reason, isA<VilleIntrouvableFailure>());
    expect(failure.ville, 'VilleQuiNexistePas');
    expect(failure.position, isNull);
  });

  test('SearchCity vide est ignorée', () async {
    final FakeWeatherService weather = FakeWeatherService();
    final WeatherBloc bloc = buildBloc(
      geolocator: FakeGeolocatorService(),
      weather: weather,
    );
    addTearDown(bloc.close);

    bloc.add(const SearchCity('   '));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, isA<WeatherInitial>());
    expect(weather.calls, 0);
  });
}

class _WeatherServiceBloquant extends FakeWeatherService {
  final Completer<Weather> completer = Completer<Weather>();

  @override
  Future<Weather> getWeather(double lat, double lon) {
    calls++;
    return completer.future;
  }
}
