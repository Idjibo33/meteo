import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:meteo/Helpers/format_date.dart';
import 'package:meteo/Helpers/weather_condition.dart';
import 'package:meteo/Weather/Widgets/background.dart';
import 'package:meteo/Weather/Widgets/proprieties.dart';
import 'package:meteo/Weather/bloc/weather_bloc.dart';
import 'package:meteo/constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart';

class WeatherScreen extends StatelessWidget {
  final Position position;
  const WeatherScreen({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: FractionallySizedBox(
              widthFactor: constraints.maxWidth > 500 ? 0.5 : 1,
              child: Stack(
                children: [
                  Background(),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: BlocBuilder<WeatherBloc, WeatherState>(
                        builder: (context, state) {
                          if (state is WeatherInitial) {
                            return const Center(
                              child: CircularProgressIndicator.adaptive(),
                            );
                          }
                          if (state is WeatherSuccess) {
                            final Weather weather = state.weather;
                            final Temperature temperature =
                                weather.temperature!;
                            return Column(
                              children: [
                                Gap(12),
                                Text(
                                  '📍${weather.areaName} ${weather.country}',
                                  style: TextStyle(
                                    color: couleurBlanche,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25,
                                  ),
                                ),
                                Image.asset(
                                  getWeatherDescriptionImage(
                                    weather.weatherMain!,
                                  ),
                                ),

                                Text(
                                  '${temperature.celsius!.round()}°C',
                                  style: TextStyle(
                                    fontSize: 50,
                                    color: couleurBleue,
                                  ),
                                ),
                                Text(
                                  weather.weatherDescription!,
                                  style: TextStyle(
                                    fontSize: 25,
                                    color: couleurBleue,
                                  ),
                                ),
                                Text(
                                  formatCurrentDate(weather.date!),
                                  style: TextStyle(color: couleurSecondaire),
                                ),
                                Gap(50),

                                Proprieties(weather: weather),
                              ],
                            );
                          }
                          if (state is WeatherFailure) {
                            return Center(child: Text(state.message));
                          } else {
                            return const Center(
                              child: Text("Une erreur est survenue"),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
