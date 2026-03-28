import 'package:flutter/material.dart';
import 'package:meteo/Weather/Screens/weather_screen.dart';
import 'package:meteo/constants.dart';

void main() {
  runApp(const MainApp());
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
      home: WeatherScreen(),
    );
  }
}
