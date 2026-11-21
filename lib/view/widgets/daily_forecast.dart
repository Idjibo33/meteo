import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:meteo/Helpers/format_temperature.dart';
import 'package:meteo/Helpers/weather_condition.dart';
import 'package:meteo/constants.dart';
import 'package:meteo/model/prevision_jour.dart';
import 'package:meteo/view/widgets/loading_weather.dart';
import 'package:meteo/view/widgets/section_label.dart';

/// Prévisions journalières : même structure pendant le chargement, seules les
/// valeurs sont remplacées par des shimmers.
class DailyForecast extends StatelessWidget {
  const DailyForecast({
    super.key,
    required this.previsions,
    this.chargement = false,
  });

  final List<PrevisionJour> previsions;
  final bool chargement;

  static const int _nombreJours = 5;

  @override
  Widget build(BuildContext context) {
    final Palette palette = context.palette;
    final bool sansDonnees = previsions.isEmpty;

    return Column(
      key: const ValueKey('previsions'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel(label: 'Prévisions 5 jours'),
        const Gap(8),
        if (chargement && sansDonnees)
          ...List<Widget>.generate(
            _nombreJours,
            (int index) =>
                _LignePrevision(chargement: true, jour: null, index: index),
          )
        else if (sansDonnees)
          Text(
            'Prévisions indisponibles.',
            style: TextStyle(color: palette.texteSecondaire, fontSize: 13),
          )
        else
          ...previsions.asMap().entries.map(
            (MapEntry<int, PrevisionJour> entree) => _LignePrevision(
              jour: entree.value,
              index: entree.key,
              chargement: chargement,
            ),
          ),
      ],
    );
  }
}

class _LignePrevision extends StatelessWidget {
  const _LignePrevision({
    required this.jour,
    required this.index,
    required this.chargement,
  });

  final PrevisionJour? jour;
  final int index;
  final bool chargement;

  @override
  Widget build(BuildContext context) {
    final Palette palette = context.palette;
    final bool shimmer = chargement || jour == null;
    final String libelle = jour == null
        ? ''
        : jour!.estAujourdhui
        ? 'Aujourd’hui'
        : DateFormat('EEE d', 'fr_FR').format(jour!.date);

    return Container(
      key: ValueKey('prevision_$index'),
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.bordure)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: shimmer
                ? const WeatherShimmer(width: 64, height: 14)
                : Text(
                    libelle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.texte, fontSize: 14),
                  ),
          ),
          const Gap(12),
          if (shimmer)
            const WeatherShimmer(width: 28, height: 28, borderRadius: 14)
          else
            Image.asset(
              getWeatherDescriptionImage(jour!.representant),
              width: 28,
              height: 28,
              color: palette.accent,
              colorBlendMode: BlendMode.srcIn,
              excludeFromSemantics: true,
            ),
          const Gap(12),
          Expanded(
            child: shimmer
                ? const WeatherShimmer(width: 70, height: 12)
                : Text(
                    jour!.representant.weatherDescription ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.texteSecondaire,
                      fontSize: 12,
                    ),
                  ),
          ),
          if (shimmer)
            const WeatherShimmer(width: 86, height: 14)
          else
            Text(
              '${formatTemperature(jour!.temperatureMin)} / '
              '${formatTemperature(jour!.temperatureMax)}',
              style: TextStyle(
                color: palette.texte,
                fontSize: 14,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}
