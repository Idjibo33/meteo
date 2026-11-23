import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meteo/theme.dart';
import 'package:meteo/view/screens/weather_screen.dart';
import 'package:meteo/view/widgets/lifecycle_observer.dart';
import 'package:meteo/viewmodel/theme_cubit.dart';
import 'package:meteo/viewmodel/weather_bloc.dart';

import 'fixtures/weather_fixture.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  testWidgets('le retour au premier plan rafraîchit une observation périmée', (
    tester,
  ) async {
    final FakeWeatherService service = FakeWeatherService()
      ..weather = buildWeatherFixture(
        observationEpoch: epochSeconds(
          DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      );
    final FakeGeolocatorService geolocator = FakeGeolocatorService();
    final WeatherBloc bloc = WeatherBloc(
      weatherService: service,
      geolocatorService: geolocator,
    );
    addTearDown(bloc.close);
    bloc.add(const StartWeather());

    final ThemeCubit themeCubit = ThemeCubit();
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
          themeMode: ThemeMode.dark,
          home: const WeatherLifecycleObserver(child: WeatherScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(service.calls, 1);

    // ignore: invalid_use_of_protected_member
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    // ignore: invalid_use_of_protected_member
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    addTearDown(() {
      // ignore: invalid_use_of_protected_member
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
    await tester.pump();
    await tester.pump();

    expect(service.calls, 2);
    expect(geolocator.calls, 1);
  });

  testWidgets(
    'le retour au premier plan relance la localisation après un refus',
    (tester) async {
      final FakeGeolocatorService geolocator = FakeGeolocatorService()
        ..error = PermissionDeniedException('refusé');
      final WeatherBloc bloc = WeatherBloc(
        weatherService: FakeWeatherService(),
        geolocatorService: geolocator,
      );
      addTearDown(bloc.close);
      bloc.add(const StartWeather());

      final ThemeCubit themeCubit = ThemeCubit();
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
            themeMode: ThemeMode.dark,
            home: const WeatherLifecycleObserver(child: WeatherScreen()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(geolocator.calls, 1);
      expect(find.text('Permission de localisation refusée.'), findsOneWidget);

      // L'utilisateur accorde la position dans les réglages puis revient.
      geolocator.error = null;
      // ignore: invalid_use_of_protected_member
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      // ignore: invalid_use_of_protected_member
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      addTearDown(() {
        // ignore: invalid_use_of_protected_member
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      });
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(geolocator.calls, 2);
      expect(bloc.state, isA<WeatherSuccess>());
    },
  );
}
