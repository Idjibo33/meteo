import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meteo/constants.dart';
import 'package:meteo/main.dart';
import 'package:meteo/theme.dart';
import 'package:meteo/view/widgets/background.dart';
import 'package:meteo/view/widgets/loading_weather.dart';
import 'package:meteo/view/widgets/proprieties.dart';
import 'package:meteo/view/screens/weather_screen.dart';
import 'package:meteo/viewmodel/theme_cubit.dart';
import 'package:meteo/viewmodel/weather_bloc.dart';
import 'package:weather/weather.dart';

import 'fixtures/weather_fixture.dart';

Future<void> pumpScreen(
  WidgetTester tester,
  WeatherBloc bloc, {
  Size size = const Size(390, 844),
  ThemeMode mode = ThemeMode.dark,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final ThemeCubit themeCubit = ThemeCubit();
  // ThemeCubit démarre en sombre ; on force le mode demandé pour les tests.
  if (mode == ThemeMode.light) {
    themeCubit.basculer();
  }
  addTearDown(themeCubit.close);

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<WeatherBloc>.value(value: bloc),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: MaterialApp(
        theme: themeClair,
        darkTheme: themeSombre,
        themeMode: mode,
        home: const WeatherScreen(),
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

  testWidgets('élargit le contenu à 1120 px et le centre sur desktop', (
    tester,
  ) async {
    await pumpSuccess(tester, size: const Size(1440, 900));

    final Finder content = find.byKey(const ValueKey('weather_content'));

    expect(tester.getSize(content).width, 1120);
    expect(tester.getRect(content).left, (1440 - 1120) / 2);
  });

  testWidgets('pleine largeur sur petit écran', (tester) async {
    await pumpSuccess(tester, size: const Size(360, 640));

    final Finder content = find.byKey(const ValueKey('weather_content'));

    expect(tester.getSize(content).width, 360);
  });

  testWidgets('garde la mise en page compacte sur téléphone', (tester) async {
    await pumpSuccess(tester, size: const Size(390, 844));

    final Finder content = find.byKey(const ValueKey('weather_content'));

    expect(tester.getSize(content).width, 390);
    expect(find.byKey(const ValueKey('mise_en_page_tablette')), findsNothing);
    expect(find.byKey(const ValueKey('mise_en_page_bureau')), findsNothing);
  });

  testWidgets('répartit les détails en deux colonnes sur tablette', (
    tester,
  ) async {
    await pumpSuccess(tester, size: const Size(800, 1000));

    expect(find.byKey(const ValueKey('mise_en_page_tablette')), findsOneWidget);
    expect(tester.widget<Proprieties>(find.byType(Proprieties)).colonnes, 2);

    // Le premier détail de chaque colonne est aligné sur la même ligne.
    final double vent = tester.getTopLeft(find.text('Vent')).dy;
    final double pluie = tester.getTopLeft(find.text('Pluie (1 h)')).dy;
    expect((vent - pluie).abs(), lessThan(8));
  });

  testWidgets('place le héros à côté des détails sur desktop', (tester) async {
    await pumpSuccess(tester, size: const Size(1440, 900));

    expect(find.byKey(const ValueKey('mise_en_page_bureau')), findsOneWidget);
    expect(find.byKey(const ValueKey('duo_hero_details')), findsOneWidget);

    final double heroTaille = tester
        .getSize(find.image(const AssetImage('assets/6.png')))
        .width;
    expect(heroTaille, 180);
    expect(
      tester.getRect(find.image(const AssetImage('assets/6.png'))).right,
      lessThan(tester.getRect(find.text('DÉTAILS')).left),
    );
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
    expect(find.text('Ressenti 18 °C'), findsOneWidget);
    expect(find.text('17 °C'), findsOneWidget);
    expect(find.text('20 °C'), findsOneWidget);
    expect(find.image(const AssetImage('assets/6.png')), findsOneWidget);
    expect(find.byType(WeatherShimmer), findsNothing);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
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
    expect(find.text('Ressenti 18 °C'), findsOneWidget);
  });

  testWidgets('refus de localisation propose la saisie d une ville', (
    tester,
  ) async {
    final FakeGeolocatorService geolocator = FakeGeolocatorService()
      ..error = PermissionDeniedException('denied');
    final FakeWeatherService service = FakeWeatherService();
    final WeatherBloc bloc = WeatherBloc(
      weatherService: service,
      geolocatorService: geolocator,
    );
    addTearDown(bloc.close);

    bloc.add(const StartWeather());
    await pumpScreen(tester, bloc);
    await tester.pump();
    await tester.pump();

    expect(find.text('Permission de localisation refusée.'), findsOneWidget);
    expect(find.byKey(const ValueKey('recherche_ville')), findsOneWidget);
    expect(find.text('Réessayer la localisation'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('recherche_ville')),
      'Paris',
    );
    await tester.tap(find.text('Voir la météo'));
    await tester.pump();
    await tester.pump();

    expect(service.lastCity, 'Paris');
    expect(find.text('18 °C'), findsOneWidget);
    expect(geolocator.calls, 1);
  });

  testWidgets(
    'affiche l écran des résultats avec des shimmers pendant le chargement',
    (tester) async {
      final FakeWeatherService service = FakeWeatherService();
      final WeatherBloc bloc = WeatherBloc(weatherService: service);
      addTearDown(bloc.close);

      await pumpScreen(tester, bloc);

      expect(find.byKey(const ValueKey('loading_skeleton')), findsOneWidget);
      expect(find.text('Préparation de la météo…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(find.byType(WeatherShimmer), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

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

  testWidgets(
    'le bouton de thème et la cible accessible cohabitent avec le pull-to-refresh',
    (tester) async {
      await pumpSuccess(tester);

      expect(find.byTooltip('Changer de thème'), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byTooltip('Actualiser'), findsNothing);
      expect(find.bySemanticsLabel('Actualiser'), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    },
  );

  testWidgets('la bascule repaint l écran du noir au blanc puis retour', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final FakeWeatherService service = FakeWeatherService()
      ..weather = buildWeatherFixture();
    final WeatherBloc bloc = WeatherBloc(weatherService: service)
      ..add(FetchWeather(buildTestPosition()));
    addTearDown(bloc.close);

    // On pompe le vrai câblage de l'application : MaterialApp doit suivre le
    // ThemeCubit, sinon le bouton change l'état sans repeindre l'écran.
    await tester.pumpWidget(MainApp(weatherBloc: bloc));
    await tester.pump();
    await tester.pump();

    Color couleurDuFond() => tester
        .widget<ColoredBox>(
          find.descendant(
            of: find.byType(Background),
            matching: find.byType(ColoredBox),
          ),
        )
        .color;

    Finder iconeDuBouton(IconData icon) => find.descendant(
      of: find.byType(IconButton),
      matching: find.byIcon(icon),
    );

    expect(couleurDuFond(), couleurFond);
    expect(iconeDuBouton(Icons.wb_sunny_outlined), findsOneWidget);

    await tester.tap(find.byTooltip('Changer de thème'));
    // MaterialApp anime le thème : la première frame applique l'état du cubit,
    // la seconde fait avancer l'animation jusqu'à la nouvelle palette.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(couleurDuFond(), couleurFondClair);
    expect(iconeDuBouton(Icons.dark_mode_outlined), findsOneWidget);

    await tester.tap(find.byTooltip('Changer de thème'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(couleurDuFond(), couleurFond);
    expect(iconeDuBouton(Icons.wb_sunny_outlined), findsOneWidget);
  });

  testWidgets('l action accessible Actualiser relance sans repositionner', (
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

    await tester.tap(find.bySemanticsLabel('Actualiser'));
    await tester.pump();
    await tester.pump();

    expect(service.calls, 2);
    expect(geolocator.calls, 1);
  });

  testWidgets('affiche les mesures détaillées avec une icône chacune', (
    tester,
  ) async {
    await pumpSuccess(
      tester,
      weather: buildWeatherFixture(
        feelsLikeKelvin: 292.15,
        windMetersPerSecond: 5.28,
        windDegree: 90,
        humidity: 8,
        pressure: 1012,
        cloudiness: 12,
        rainLastHour: 0,
      ),
    );

    expect(find.text('Ressenti 19 °C'), findsOneWidget);

    expect(find.text('Vent'), findsOneWidget);
    expect(find.text('19 km/h'), findsOneWidget);
    expect(find.text('Est'), findsOneWidget);
    expect(find.byIcon(Icons.air_outlined), findsOneWidget);

    expect(find.text('Humidité'), findsOneWidget);
    expect(find.text('8 %'), findsOneWidget);
    expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);

    expect(find.text('Pression'), findsOneWidget);
    expect(find.byIcon(Icons.speed_outlined), findsOneWidget);

    expect(find.text('Nuages'), findsOneWidget);
    expect(find.text('12 %'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);

    expect(find.text('Pluie (1 h)'), findsOneWidget);
    expect(find.text('0,0 mm'), findsOneWidget);
    expect(find.byIcon(Icons.umbrella_outlined), findsOneWidget);

    expect(
      find.descendant(
        of: find.byType(Proprieties),
        matching: find.byIcon(Icons.wb_sunny_outlined),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.nights_stay_outlined), findsOneWidget);
    expect(find.text('Lever du soleil'), findsOneWidget);
    expect(find.text('Coucher du soleil'), findsOneWidget);
  });

  testWidgets('place min et max juste sous la température', (tester) async {
    await pumpSuccess(tester);

    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);

    final double max = tester.getBottomLeft(find.text('20 °C')).dy;
    final double details = tester.getTopLeft(find.text('DÉTAILS')).dy;

    expect(max, lessThan(details));
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

  testWidgets('affiche l heure de la dernière mise à jour', (tester) async {
    await pumpSuccess(tester);

    expect(find.textContaining('Actualisé à '), findsOneWidget);
    expect(find.textContaining('Observé le'), findsOneWidget);
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
    expect(find.textContaining('Observé le'), findsNothing);
    expect(find.byType(WeatherShimmer), findsWidgets);
    expect(find.byType(Image), findsNothing);

    secondeReponse.complete(buildWeatherFixture());
    await tester.pump();
    await tester.pump();

    expect(find.text('Récupération de la météo…'), findsNothing);
    expect(find.textContaining('Observé le'), findsOneWidget);
    expect(find.byType(WeatherShimmer), findsNothing);
    expect(find.image(const AssetImage('assets/6.png')), findsOneWidget);
    expect(find.byKey(const ValueKey('weather_content')), findsOneWidget);
  });

  testWidgets(
    'un pull pendant un chargement en cours ne duplique pas l appel',
    (tester) async {
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
      expect(service.calls, 2);

      tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show();
      await pumpRefresh(tester);

      expect(service.calls, 2);
      expect(find.text('Récupération de la météo…'), findsOneWidget);

      secondeReponse.complete(buildWeatherFixture());
      await tester.pump();
      await tester.pump();
    },
  );

  testWidgets('la liste rebondit aux deux extrémités', (tester) async {
    await pumpSuccess(tester);

    final CustomScrollView vue = tester.widget<CustomScrollView>(
      find.byType(CustomScrollView),
    );

    expect(vue.physics, isA<BouncingScrollPhysics>());
  });

  testWidgets('l appBar affiche la région épinglée', (tester) async {
    await pumpSuccess(tester);

    final Finder appBar = find.byType(SliverAppBar);

    expect(appBar, findsOneWidget);
    expect(
      find.descendant(of: appBar, matching: find.text('Niamey NE')),
      findsOneWidget,
    );
    expect(tester.widget<SliverAppBar>(appBar).pinned, isTrue);
  });

  testWidgets('le contenu est porté par des slivers', (tester) async {
    await pumpSuccess(tester);

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(find.byType(SliverToBoxAdapter), findsWidgets);
  });

  testWidgets('l illustration de la température est grande', (tester) async {
    await pumpSuccess(tester);

    final Image illustration = tester.widget<Image>(
      find.image(const AssetImage('assets/6.png')),
    );

    expect(illustration.width, 140);
    expect(illustration.height, 140);
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
