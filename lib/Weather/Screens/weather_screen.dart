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
import 'package:meteo/Weather/failures.dart';
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
                      return const _WeatherProgress();
                    case WeatherLocating():
                      return const _WeatherProgress(
                        label: 'Recherche de votre position…',
                      );
                    case WeatherLoading():
                      return const _WeatherProgress(
                        label: 'Récupération de la météo…',
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
                    case WeatherFailure(:final reason):
                      return Center(child: _WeatherFailureView(reason: reason));
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

class _WeatherProgress extends StatelessWidget {
  const _WeatherProgress({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator.adaptive(),
          if (label != null) ...[
            const Gap(16),
            Text(
              label!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: couleurBlanche),
            ),
          ],
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
          formatCurrentDateOrDash(weather.date),
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
  const _WeatherFailureView({required this.reason});

  final WeatherFailureReason reason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            reason.requiresRelocation ? Icons.location_off : Icons.cloud_off,
            size: 48,
            color: couleurSecondaire,
          ),
          const Gap(16),
          Text(
            reason.message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: couleurBlanche),
          ),
          const Gap(16),
          FilledButton(
            onPressed: () => context.read<WeatherBloc>().add(
              reason.requiresRelocation
                  ? const RetryLocation()
                  : const RefreshWeather(),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
