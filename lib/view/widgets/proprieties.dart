import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:meteo/Helpers/format_date.dart';
import 'package:meteo/Helpers/format_temperature.dart';
import 'package:meteo/constants.dart';
import 'package:weather/weather.dart';

class Proprieties extends StatelessWidget {
  const Proprieties({super.key, required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DetailRow(
          first: _DetailCell(
            icon: Icons.wb_sunny_outlined,
            label: 'Lever du soleil',
            value: formatHeureAvecFuseau(
              weather.sunrise,
              weather.toJson()?['timezone'],
            ),
          ),
          second: _DetailCell(
            icon: Icons.nights_stay_outlined,
            label: 'Coucher du soleil',
            value: formatHeureAvecFuseau(
              weather.sunset,
              weather.toJson()?['timezone'],
            ),
          ),
        ),
        const Divider(color: couleurBordure, height: 1, thickness: 1),
        _DetailRow(
          first: _DetailCell(
            icon: Icons.arrow_downward_rounded,
            label: 'Température min',
            value: formatTemperature(weather.tempMin?.celsius),
          ),
          second: _DetailCell(
            icon: Icons.arrow_upward_rounded,
            label: 'Température max',
            value: formatTemperature(weather.tempMax?.celsius),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: first),
        Container(width: 1, height: 44, color: couleurBordure),
        Expanded(child: second),
      ],
    );
  }
}

class _DetailCell extends StatelessWidget {
  const _DetailCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: couleurAccent),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: couleurTexteSecondaire,
                    fontSize: 12,
                  ),
                ),
                const Gap(4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: couleurTexte,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
