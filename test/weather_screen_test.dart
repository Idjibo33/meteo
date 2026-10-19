import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meteo/Weather/Screens/weather_screen.dart';
import 'package:meteo/Weather/bloc/weather_bloc.dart';
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

  testWidgets('borne le contenu à 480 px et le centre sur grand écran',
      (tester) async {
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

  testWidgets('pas de débordement dans une fenêtre courte (paysage)',
      (tester) async {
    await pumpSuccess(tester, size: const Size(640, 360));

    expect(tester.takeException(), isNull);
  });

  testWidgets('affiche les températures et les libellés corrects',
      (tester) async {
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

  testWidgets('tronque un nom de ville trop long sans débordement',
      (tester) async {
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

  testWidgets('affiche une erreur conviviale et permet de réessayer',
      (tester) async {
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

  testWidgets('affiche un indicateur pendant le chargement', (tester) async {
    final FakeWeatherService service = FakeWeatherService();
    final WeatherBloc bloc = WeatherBloc(weatherService: service);
    addTearDown(bloc.close);

    await pumpScreen(tester, bloc);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
