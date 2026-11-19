import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:meteo/Helpers/format_date.dart';
import 'package:meteo/Helpers/format_weather_details.dart';
import 'package:meteo/constants.dart';
import 'package:meteo/view/widgets/loading_weather.dart';
import 'package:weather/weather.dart';

/// Les mesures affichées sous le héros : une colonne, des valeurs alignées,
/// une icône par ligne et aucun cadre. Pendant un chargement, seules les
/// valeurs sont remplacées par des shimmers.
class Proprieties extends StatelessWidget {
  const Proprieties({
    super.key,
    required this.weather,
    this.chargement = false,
    this.colonnes = 1,
  });

  final Weather? weather;
  final bool chargement;
  final int colonnes;

  @override
  Widget build(BuildContext context) {
    final Palette palette = context.palette;
    final bool mesurer = !chargement && weather != null;
    final int? fuseau = weather?.toJson()?['timezone'];

    final List<_Detail> mesures = <_Detail>[
      _Detail(
        icon: Icons.air_outlined,
        label: 'Vent',
        value: mesurer ? formatVentVitesse(weather!.windSpeed) : null,
        suffix: mesurer ? formatVentDirection(weather!.windDegree) : null,
        suffixWidth: 28,
      ),
      _Detail(
        icon: Icons.water_drop_outlined,
        label: 'Humidité',
        value: mesurer ? formatPourcentage(weather!.humidity) : null,
      ),
      _Detail(
        icon: Icons.speed_outlined,
        label: 'Pression',
        value: mesurer ? formatPression(weather!.pressure) : null,
      ),
      _Detail(
        icon: Icons.cloud_outlined,
        label: 'Nuages',
        value: mesurer ? formatPourcentage(weather!.cloudiness) : null,
      ),
      _Detail(
        icon: Icons.umbrella_outlined,
        label: 'Pluie (1 h)',
        value: mesurer ? formatPluie(weather!.rainLastHour) : null,
      ),
    ];

    final List<_Detail> soleil = <_Detail>[
      _Detail(
        icon: Icons.wb_sunny_outlined,
        label: 'Lever du soleil',
        value: mesurer ? formatHeureAvecFuseau(weather!.sunrise, fuseau) : null,
      ),
      _Detail(
        icon: Icons.nights_stay_outlined,
        label: 'Coucher du soleil',
        value: mesurer ? formatHeureAvecFuseau(weather!.sunset, fuseau) : null,
      ),
    ];

    if (colonnes == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < mesures.length; i++) ...[
            _DetailRow(detail: mesures[i]),
            if (i < mesures.length - 1)
              Divider(color: palette.bordure, height: 1, thickness: 1),
          ],
          const Gap(12),
          for (int i = 0; i < soleil.length; i++) ...[
            _DetailRow(detail: soleil[i]),
            if (i < soleil.length - 1)
              Divider(color: palette.bordure, height: 1, thickness: 1),
          ],
        ],
      );
    }

    // Sur tablette, les sept mesures se répartissent en deux colonnes
    // équilibrées plutôt que de s'étirer sur toute la largeur.
    final List<_Detail> toutes = <_Detail>[...mesures, ...soleil];
    final int milieu = (toutes.length / 2).ceil();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _colonne(context, toutes.sublist(0, milieu))),
        const Gap(28),
        Expanded(child: _colonne(context, toutes.sublist(milieu))),
      ],
    );
  }

  Widget _colonne(BuildContext context, List<_Detail> details) {
    final Palette palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < details.length; i++) ...[
          _DetailRow(detail: details[i]),
          if (i < details.length - 1)
            Divider(color: palette.bordure, height: 1, thickness: 1),
        ],
      ],
    );
  }
}

class _Detail {
  const _Detail({
    required this.icon,
    required this.label,
    required this.value,
    this.suffix,
    this.suffixWidth = 48,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String? suffix;
  final double suffixWidth;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.detail});

  final _Detail detail;

  @override
  Widget build(BuildContext context) {
    final Palette palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(detail.icon, size: 18, color: palette.accent),
          const Gap(10),
          Expanded(
            child: Text(
              detail.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.texteSecondaire, fontSize: 12),
            ),
          ),
          const Gap(8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (detail.value == null)
                const WeatherShimmer(width: 48, height: 13)
              else
                Text(
                  detail.value!,
                  style: TextStyle(
                    color: palette.texte,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              if (detail.suffix != null) ...[
                const Gap(4),
                Text(
                  detail.suffix!,
                  style: TextStyle(
                    color: palette.texteSecondaire,
                    fontSize: 10,
                  ),
                ),
              ] else if (detail.value == null && detail.suffixWidth != 48) ...[
                const Gap(4),
                WeatherShimmer(width: detail.suffixWidth, height: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
