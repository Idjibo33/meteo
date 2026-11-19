import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meteo/constants.dart';
import 'package:meteo/view/widgets/background.dart';
import 'package:meteo/view/screens/weather_screen.dart';
import 'package:meteo/viewmodel/weather_bloc.dart';
import 'package:weather/weather.dart';

import 'fixtures/weather_fixture.dart';

Future<void> pumpScreen(
  WidgetTester tester,
  WeatherBloc bloc, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<WeatherBloc>.value(
        value: bloc,
        child: const WeatherScreen(),
      ),
    ),
  );
}

/// Le `RefreshIndicator` arme son animation sur la première frame : quelques
/// pumps sont nécessaires avant que `onRefresh` soit réellement appelé.
Future<void> pumpRefresh(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump();
}

Future<WeatherBloc> pumpSuccess(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  Weather? weather,
}) async {
  final FakeWeatherService service = FakeWeatherService()..weather = weather;
  final WeatherBloc bloc = WeatherBloc(weatherService: service);
  addTearDown(bloc.close);

  bloc.add(FetchWeather(buildTestPosition()));
  await pumpScreen(tester, bloc, size: size);
  await tester.pump();
  await tester.pump();

  return bloc;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  testWidgets('borne le contenu à 480 px et le centre sur grand écran', (
    tester,
  ) async {
    await pumpSuccess(tester, size: const Size(1440, 900));

    final Finder content = find.byKey(const ValueKey('weather_content'));

    expect(tester.getSize(content).width, 480);
    expect(tester.getRect(content).left, (1440 - 480) / 2);
  });

  testWidgets('pleine largeur sur petit écran', (tester) async {
    await pumpSuccess(tester, size: const Size(360, 640));

    final Finder content = find.byKey(const ValueKey('weather_content'));

    expect(tester.getSize(content).width, 360);
  });

  testWidgets('pas de débordement dans une fenêtre courte (paysage)', (
    tester,
  ) async {
    await pumpSuccess(tester, size: const Size(640, 360));

    expect(tester.takeException(), isNull);
  });

  testWidgets('affiche les températures et les libellés corrects', (
    tester,
  ) async {
    await pumpSuccess(tester);

    expect(find.text('18 °C'), findsOneWidget);
    expect(find.text('17 °C'), findsOneWidget);
    expect(find.text('20 °C'), findsOneWidget);
    expect(find.text('Température min'), findsOneWidget);
    expect(find.text('Température max'), findsOneWidget);
    expect(find.text('Lever du soleil'), findsOneWidget);
    expect(find.text('Coucher du soleil'), findsOneWidget);
    expect(find.textContaining('Celsius'), findsNothing);
  });

  testWidgets('tronque un nom de ville trop long sans débordement', (
    tester,
  ) async {
    await pumpSuccess(
      tester,
      size: const Size(360, 640),
      weather: buildWeatherFixture(
        areaName: 'Ville-très-très-très-très-très-longue',
      ),
    );

    final Text city = tester.widget<Text>(
      find.textContaining('Ville-très-très'),
    );

    expect(city.maxLines, 1);
    expect(city.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('affiche une erreur conviviale et permet de réessayer', (
    tester,
  ) async {
    final FakeWeatherService service = FakeWeatherService()
      ..error = Exception('Invalid API key');
    final WeatherBloc bloc = WeatherBloc(weatherService: service);
    addTearDown(bloc.close);

    bloc.add(FetchWeather(buildTestPosition()));
    await pumpScreen(tester, bloc);
    await tester.pump();
    await tester.pump();

    expect(find.text('Clé API météo manquante ou invalide.'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    service.error = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    await tester.pump();

    expect(find.text('18 °C'), findsOneWidget);
  });

  testWidgets('affiche un aperçu animé pendant le chargement', (tester) async {
    final FakeWeatherService service = FakeWeatherService();
    final WeatherBloc bloc = WeatherBloc(weatherService: service);
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc);

    expect(find.byKey(const ValueKey('loading_skeleton')), findsOneWidget);
    expect(find.text('Préparation de la météo…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('utilise un fond noir et remplace l emoji par une icône', (
    tester,
  ) async {
    await pumpSuccess(tester);

    expect(find.textContaining('📍'), findsNothing);
    expect(find.byIcon(Icons.place_outlined), findsOneWidget);

    final ColoredBox fond = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(Background),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(fond.color, couleurFond);
  });

  testWidgets('le bouton Actualiser relance la météo sans repositionner', (
    tester,
  ) async {
    final FakeWeatherService service = FakeWeatherService();
    final FakeGeolocatorService geolocator = FakeGeolocatorService();
    final WeatherBloc bloc = WeatherBloc(
      weatherService: service,
      geolocatorService: geolocator,
    )..add(const StartWeather());
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc);
    await tester.pump();
    await tester.pump();

    expect(service.calls, 1);
    expect(geolocator.calls, 1);

    await tester.tap(find.byTooltip('Actualiser'));
    await tester.pump();
    await tester.pump();

    expect(service.calls, 2);
    expect(geolocator.calls, 1);
  });

  testWidgets('affiche À jour pour une observation récente', (tester) async {
    await pumpSuccess(
      tester,
      weather: buildWeatherFixture(
        observationEpoch: epochSeconds(
          DateTime.now().subtract(const Duration(minutes: 3)),
        ),
      ),
    );

    expect(find.textContaining('À jour'), findsOneWidget);
  });

  testWidgets('affiche l’âge d’une observation ancienne', (tester) async {
    await pumpSuccess(
      tester,
      weather: buildWeatherFixture(
        observationEpoch: epochSeconds(
          DateTime.now().subtract(const Duration(minutes: 25)),
        ),
      ),
    );

    expect(find.textContaining('Observé il y a 25 min'), findsOneWidget);
  });

  testWidgets('signale une observation périmée', (tester) async {
    await pumpSuccess(
      tester,
      weather: buildWeatherFixture(
        observationEpoch: epochSeconds(
          DateTime.now().subtract(const Duration(minutes: 90)),
        ),
      ),
    );

    expect(find.textContaining('Données périmées'), findsOneWidget);
  });

  testWidgets('le pull-to-refresh relance la météo sans repositionner', (
    tester,
  ) async {
    final FakeWeatherService service = FakeWeatherService();
    final FakeGeolocatorService geolocator = FakeGeolocatorService();
    final WeatherBloc bloc = WeatherBloc(
      weatherService: service,
      geolocatorService: geolocator,
    )..add(const StartWeather());
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc);
    await tester.pump();
    await tester.pump();
    expect(service.calls, 1);

    final RefreshIndicatorState indicator = tester.state<RefreshIndicatorState>(
      find.byType(RefreshIndicator),
    );
    indicator.show();
    await pumpRefresh(tester);

    expect(service.calls, 2);
    expect(geolocator.calls, 1);
  });

  testWidgets('le contenu reste visible avec une étape pendant le refresh', (
    tester,
  ) async {
    final Completer<Weather> secondeReponse = Completer<Weather>();
    final _ServiceParEtapes service = _ServiceParEtapes(<Future<Weather>>[
      Future<Weather>.value(buildWeatherFixture()),
      secondeReponse.future,
    ]);
    final WeatherBloc bloc = WeatherBloc(
      weatherService: service,
      geolocatorService: FakeGeolocatorService(),
    )..add(const StartWeather());
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc);
    await tester.pump();
    await tester.pump();

    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show();
    await pumpRefresh(tester);

    expect(find.byKey(const ValueKey('weather_content')), findsOneWidget);
    expect(find.text('Récupération de la météo…'), findsOneWidget);

    secondeReponse.complete(buildWeatherFixture());
    await tester.pump();
    await tester.pump();

    expect(find.text('Récupération de la météo…'), findsNothing);
    expect(find.byKey(const ValueKey('weather_content')), findsOneWidget);
  });

  testWidgets('un pull pendant un chargement en cours ne duplique pas l appel', (
    tester,
  ) async {
    final Completer<Weather> secondeReponse = Completer<Weather>();
    final _ServiceParEtapes service = _ServiceParEtapes(<Future<Weather>>[
      Future<Weather>.value(buildWeatherFixture()),
      secondeReponse.future,
    ]);
    final WeatherBloc bloc = WeatherBloc(
      weatherService: service,
      geolocatorService: FakeGeolocatorService(),
    )..add(const StartWeather());
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byTooltip('Actualiser'));
    await tester.pump();
    await tester.pump();
    expect(service.calls, 2);

    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show();
    await pumpRefresh(tester);

    expect(service.calls, 2);
    expect(find.text('Récupération de la météo…'), findsOneWidget);

    secondeReponse.complete(buildWeatherFixture());
    await tester.pump();
    await tester.pump();
  });
}

class _ServiceParEtapes extends FakeWeatherService {
  _ServiceParEtapes(this.reponses);

  final List<Future<Weather>> reponses;

  @override
  Future<Weather> getWeather(double lat, double lon) {
    calls++;
    return reponses.removeAt(0);
  }
}
