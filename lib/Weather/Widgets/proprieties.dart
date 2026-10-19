import 'package:flutter/material.dart';
import 'package:meteo/Helpers/format_date.dart';
import 'package:meteo/Helpers/format_temperature.dart';
import 'package:meteo/constants.dart';
import 'package:weather/weather.dart';

class Proprieties extends StatelessWidget {
  final Weather weather;

  const Proprieties({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _PropertyCell(
                icon: 'assets/6.png',
                label: 'Lever du soleil',
                value: formatHour(weather.sunrise ?? DateTime.now()),
              ),
            ),
            Expanded(
              child: _PropertyCell(
                icon: 'assets/12.png',
                label: 'Coucher du soleil',
                value: formatHour(weather.sunset ?? DateTime.now()),
              ),
            ),
          ],
        ),
        const Divider(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _PropertyCell(
                icon: 'assets/13.png',
                label: 'Température min',
                value: formatTemperature(weather.tempMin?.celsius),
              ),
            ),
            Expanded(
              child: _PropertyCell(
                icon: 'assets/14.png',
                label: 'Température max',
                value: formatTemperature(weather.tempMax?.celsius),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PropertyCell extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _PropertyCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(height: 35, width: 35, child: Image.asset(icon)),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: couleurBleue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
