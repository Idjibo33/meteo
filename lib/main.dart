import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meteo/Helpers/get_it.dart';
import 'package:meteo/view/screens/weather_screen.dart';
import 'package:meteo/view/widgets/lifecycle_observer.dart';
import 'package:meteo/viewmodel/weather_bloc.dart';
import 'package:meteo/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  await initializeDateFormatting('fr_FR');
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: couleurAccent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: couleurFond,
      ),
      debugShowCheckedModeBanner: false,
      home: BlocProvider<WeatherBloc>(
        create: (_) => WeatherBloc()..add(const StartWeather()),
        child: const WeatherLifecycleObserver(child: WeatherScreen()),
      ),
    );
  }
}
