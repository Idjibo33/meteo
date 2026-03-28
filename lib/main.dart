import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meteo/Helpers/get_it.dart';
import 'package:meteo/Weather/Screens/weather_screen.dart';
import 'package:meteo/Weather/Services/geolocator_service.dart';
import 'package:meteo/Weather/bloc/weather_bloc.dart';
import 'package:meteo/constants.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MainApp());
  configureDependencies();
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: couleurBleue),
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: getIt<GeolocatorService>().getPosition(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final Position pos = snapshot.data!;
            return BlocProvider<WeatherBloc>(
              create: (context) => WeatherBloc()..add(FetchWeather(pos)),

              child: WeatherScreen(position: pos),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text(snapshot.error.toString())),
            );
          } else {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator.adaptive()),
            );
          }
        },
      ),
    );
  }
}
