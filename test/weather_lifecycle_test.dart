import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meteo/view/screens/weather_screen.dart';
import 'package:meteo/view/widgets/lifecycle_observer.dart';
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

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<WeatherBloc>.value(
          value: bloc,
          child: const WeatherLifecycleObserver(child: WeatherScreen()),
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
}
