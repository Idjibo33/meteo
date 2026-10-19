import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:meteo/Helpers/format_date.dart';
import 'package:meteo/Helpers/format_temperature.dart';
import 'package:meteo/Helpers/max_width_container.dart';
import 'package:meteo/Helpers/weather_condition.dart';
import 'package:meteo/Weather/Widgets/background.dart';
import 'package:meteo/Weather/Widgets/proprieties.dart';
import 'package:meteo/Weather/bloc/weather_bloc.dart';
import 'package:meteo/constants.dart';
import 'package:weather/weather.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Background(),
          SafeArea(
            child: MaxWidthContainer(
              child: BlocBuilder<WeatherBloc, WeatherState>(
                builder: (context, state) {
                  switch (state) {
                    case WeatherInitial():
                      return const Center(
                        child: CircularProgressIndicator.adaptive(),
                      );
                    case WeatherSuccess(:final weather):
                      return SingleChildScrollView(
                        key: const ValueKey('weather_content'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: _WeatherContent(weather: weather),
                      );
                    case WeatherFailure(:final message):
                      return Center(
                        child: _WeatherFailureView(message: message),
                      );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherContent extends StatelessWidget {
  final Weather weather;

  const _WeatherContent({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Gap(12),
        Text(
          '📍${weather.areaName} ${weather.country}',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: couleurBlanche,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        Image.asset(getWeatherDescriptionImage(weather.weatherMain)),
        Text(
          formatTemperature(weather.temperature?.celsius),
          style: const TextStyle(
            fontSize: 50,
            color: couleurBleue,
          ),
        ),
        Text(
          weather.weatherDescription ?? '',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 25,
            color: couleurBleue,
          ),
        ),
        Text(
          formatCurrentDate(weather.date ?? DateTime.now()),
          textAlign: TextAlign.center,
          style: const TextStyle(color: couleurSecondaire),
        ),
        const Gap(50),
        Proprieties(weather: weather),
      ],
    );
  }
}

class _WeatherFailureView extends StatelessWidget {
  final String message;

  const _WeatherFailureView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: couleurSecondaire),
          const Gap(16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: couleurBlanche),
          ),
          const Gap(16),
          FilledButton(
            onPressed: () => context.read<WeatherBloc>().add(
                  const RefreshWeather(),
                ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
