import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meteo/Helpers/error_messages.dart';
import 'package:meteo/Helpers/get_it.dart';
import 'package:meteo/Weather/Screens/weather_screen.dart';
import 'package:meteo/Weather/Services/geolocator_service.dart';
import 'package:meteo/Weather/bloc/weather_bloc.dart';
import 'package:meteo/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  await initializeDateFormatting('fr_FR');
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late Future<Position> _positionFuture;

  @override
  void initState() {
    super.initState();
    _positionFuture = getIt<GeolocatorService>().getPosition();
  }

  void _retry() {
    setState(() {
      _positionFuture = getIt<GeolocatorService>().getPosition();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: couleurBleue),
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Position>(
        future: _positionFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final Position position = snapshot.data!;
            return BlocProvider<WeatherBloc>(
              create: (context) => WeatherBloc()..add(FetchWeather(position)),
              child: const WeatherScreen(),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_off, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        friendlyLocationError(snapshot.error!),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _retry,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        },
      ),
    );
  }
}
