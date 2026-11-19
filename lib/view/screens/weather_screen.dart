import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:meteo/Helpers/format_date.dart';
import 'package:meteo/Helpers/format_temperature.dart';
import 'package:meteo/Helpers/freshness.dart';
import 'package:meteo/Helpers/max_width_container.dart';
import 'package:meteo/Helpers/weather_condition.dart';
import 'package:meteo/constants.dart';
import 'package:meteo/model/failures.dart';
import 'package:meteo/view/widgets/background.dart';
import 'package:meteo/view/widgets/loading_weather.dart';
import 'package:meteo/view/widgets/proprieties.dart';
import 'package:meteo/viewmodel/weather_bloc.dart';
import 'package:weather/weather.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: couleurFond,
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
                      return const WeatherLoadingView();
                    case WeatherLocating():
                      return const WeatherLoadingView(
                        label: 'Recherche de votre position…',
                      );
                    case WeatherLoading(:final derniereMeteo):
                      if (derniereMeteo == null) {
                        return const WeatherLoadingView(
                          label: 'Récupération de la météo…',
                        );
                      }
                      return Stack(
                        children: [
                          _contentRafraichissable(context, derniereMeteo),
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 24,
                            child: IgnorePointer(
                              child: WeatherRefreshLine(
                                label: 'Récupération de la météo…',
                              ),
                            ),
                          ),
                        ],
                      );
                    case WeatherSuccess(:final weather):
                      return _contentRafraichissable(context, weather);
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

  Widget _contentRafraichissable(BuildContext context, Weather weather) {
    return RefreshIndicator(
      color: couleurAccent,
      backgroundColor: couleurFond,
      onRefresh: () => _rafraichir(context),
      child: SingleChildScrollView(
        key: const ValueKey('weather_content'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: _WeatherContent(weather: weather),
      ),
    );
  }

  Future<void> _rafraichir(BuildContext context) async {
    final WeatherBloc bloc = context.read<WeatherBloc>();
    // Le bloc ignore un RefreshWeather pendant un chargement : ne pas attendre
    // un état final qui n'arrivera pas (le bouton ou un tick a déjà lancé l'appel).
    if (bloc.state is WeatherLoading) {
      return;
    }
    final Future<WeatherState> fin = bloc.stream.firstWhere(
      (WeatherState state) =>
          state is WeatherSuccess || state is WeatherFailure,
    );
    bloc.add(const RefreshWeather());
    await fin;
  }
}

class _WeatherContent extends StatelessWidget {
  const _WeatherContent({required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeatherHeader(weather: weather),
        const Gap(40),
        _WeatherHero(weather: weather),
        const Gap(40),
        const _SectionLabel(label: 'Détails'),
        const Gap(8),
        Proprieties(weather: weather),
        const Gap(24),
      ],
    );
  }
}

class _WeatherHeader extends StatelessWidget {
  const _WeatherHeader({required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    final DateTime maintenant = DateTime.now();
    final FraicheurMeteo fraicheur = evaluerFraicheur(
      weather.date,
      maintenant,
    );
    final bool aJour = fraicheur == FraicheurMeteo.aJour;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.place_outlined, size: 18, color: couleurAccent),
            const Gap(8),
            Expanded(
              child: Text(
                '${weather.areaName} ${weather.country}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: couleurTexte,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Actualiser',
              onPressed: () =>
                  context.read<WeatherBloc>().add(const RefreshWeather()),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              color: couleurAccent,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ],
        ),
        const Gap(8),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: aJour ? couleurAccent : couleurFond,
                border: aJour
                    ? null
                    : Border.all(color: couleurTexteSecondaire, width: 1),
                shape: BoxShape.circle,
              ),
            ),
            const Gap(8),
            Expanded(
              child: Text(
                '${formatFraicheur(weather.date, maintenant)} ∙ '
                'Observé le ${formatDateAvecFuseau(weather.date, weather.toJson()?['timezone'])}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: couleurTexteSecondaire,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeatherHero extends StatelessWidget {
  const _WeatherHero({required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          getWeatherDescriptionImage(weather.weatherMain),
          width: 112,
          height: 112,
          color: couleurAccent,
          colorBlendMode: BlendMode.srcIn,
          excludeFromSemantics: true,
        ),
        const Gap(8),
        Text(
          formatTemperature(weather.temperature?.celsius),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: couleurTexte,
            fontSize: 88,
            height: 1,
            fontWeight: FontWeight.w200,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const Gap(12),
        Text(
          weather.weatherDescription ?? '',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: couleurAccent,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: couleurAccent,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
      ),
    );
  }
}

class _WeatherFailureView extends StatelessWidget {
  const _WeatherFailureView({required this.reason});

  final WeatherFailureReason reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: couleurSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: couleurBordure),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            reason.requiresRelocation
                ? Icons.location_off_outlined
                : Icons.cloud_off_outlined,
            size: 40,
            color: couleurAccent,
          ),
          const Gap(16),
          Text(
            reason.message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: couleurTexte, fontSize: 15),
          ),
          const Gap(20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: couleurAccent,
              foregroundColor: couleurFond,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
