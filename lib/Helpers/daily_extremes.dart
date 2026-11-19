import 'dart:math' as math;

import 'package:weather/weather.dart';

/// Remplace les extremas de la météo courante par ceux des prévisions du même
/// jour local.
///
/// L'endpoint « weather » d'OpenWeatherMap renvoie parfois
/// `temp_min = temp_max = temp`. Le forecast gratuit fournit des extremas par
/// tranche de trois heures : leur minimum et leur maximum sur la journée
/// donnent une plage exploitable, sans changer le reste de l'observation.
Weather appliquerExtremasDuJour(Weather actuel, Iterable<Weather> previsions) {
  final Map<String, dynamic> json = Map<String, dynamic>.from(
    actuel.toJson() ?? <String, dynamic>{},
  );
  final Object? mainBrut = json['main'];
  if (mainBrut is! Map) {
    return actuel;
  }
  final Map<String, dynamic> main = Map<String, dynamic>.from(mainBrut);
  final DateTime? reference = _dateLocale(
    actuel.date,
    (json['timezone'] as num?)?.toInt(),
  );
  if (reference == null) {
    return actuel;
  }

  final List<double> minima = <double>[];
  final List<double> maxima = <double>[];

  for (final Weather prevision in previsions) {
    final DateTime? date = _dateLocale(
      prevision.date,
      (json['timezone'] as num?)?.toInt(),
    );
    if (date == null || !_memeJour(date, reference)) {
      continue;
    }
    final Object? mainPrevision = prevision.toJson()?['main'];
    if (mainPrevision is! Map) {
      continue;
    }
    final double? min = _nombre(mainPrevision, 'temp_min');
    final double? max = _nombre(mainPrevision, 'temp_max');
    if (min != null) {
      minima.add(min);
    }
    if (max != null) {
      maxima.add(max);
    }
  }

  if (minima.isEmpty || maxima.isEmpty) {
    return actuel;
  }
  // La température courante encadre la plage : elle évite d'afficher un min
  // supérieur (ou un max inférieur) à la valeur observée à l'instant.
  final double? temperatureActuelle = _nombre(main, 'temp');
  if (temperatureActuelle != null) {
    minima.add(temperatureActuelle);
    maxima.add(temperatureActuelle);
  }
  final double min = minima.reduce(math.min);
  final double max = maxima.reduce(math.max);
  if (min == _nombre(main, 'temp_min') && max == _nombre(main, 'temp_max')) {
    return actuel;
  }

  main['temp_min'] = min;
  main['temp_max'] = max;
  json['main'] = main;
  return Weather(json);
}

DateTime? _dateLocale(DateTime? date, int? fuseau) {
  if (date == null) {
    return null;
  }
  final DateTime utc = date.toUtc();
  return fuseau == null ? utc : utc.add(Duration(seconds: fuseau));
}

bool _memeJour(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

double? _nombre(Map<dynamic, dynamic> map, String cle) {
  final Object? valeur = map[cle];
  return valeur is num ? valeur.toDouble() : null;
}
