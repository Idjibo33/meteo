import 'package:meteo/model/prevision_jour.dart';
import 'package:weather/weather.dart';

/// Nombre de journées affichées par l'écran (l'API en fournit cinq).
const int nombreJoursPrevisions = 5;

DateTime _dateLocale(DateTime? date, int? fuseau) {
  final DateTime utc = (date ?? DateTime.now()).toUtc();
  return fuseau == null ? utc : utc.add(Duration(seconds: fuseau));
}

DateTime _jour(DateTime date) => DateTime(date.year, date.month, date.day);

({double min, double max})? _extremas(Weather prevision) {
  final double? min =
      prevision.tempMin?.celsius ?? prevision.temperature?.celsius;
  final double? max =
      prevision.tempMax?.celsius ?? prevision.temperature?.celsius;
  if (min == null || max == null) {
    return null;
  }
  return (min: min, max: max);
}

/// Éloignement de la tranche horaire par rapport à midi : la plus proche sert
/// d'illustration de la journée (une icône de nuit au petit matin serait
/// trompeuse).
double _distanceMidi(Weather prevision, int? fuseau) {
  final DateTime locale = _dateLocale(prevision.date, fuseau);
  final double heure = locale.hour + locale.minute / 60;
  return (heure - 12).abs();
}

/// Regroupe les prévisions tranche par tranche en journées calendaires.
///
/// Toutes les dates sont ramenées au fuseau de la ville observée : sans cela,
/// une tranche de 23 h UTC peut être rattachée au mauvais jour local.
List<PrevisionJour> grouperPrevisionsParJour(
  Iterable<Weather> previsions, {
  required DateTime reference,
  int? fuseau,
  int limite = nombreJoursPrevisions,
}) {
  final DateTime jourReference = _jour(_dateLocale(reference, fuseau));
  final Map<DateTime, List<Weather>> groupes = <DateTime, List<Weather>>{};

  for (final Weather prevision in previsions) {
    if (prevision.date == null || _extremas(prevision) == null) {
      continue;
    }
    final DateTime jour = _jour(_dateLocale(prevision.date, fuseau));
    if (jour.isBefore(jourReference)) {
      continue;
    }
    groupes.putIfAbsent(jour, () => <Weather>[]).add(prevision);
  }

  final List<DateTime> jours = groupes.keys.toList()..sort();
  final List<PrevisionJour> resultat = <PrevisionJour>[];
  for (final DateTime jour in jours.take(limite)) {
    final List<Weather> tranches = groupes[jour]!;
    double min = double.infinity;
    double max = double.negativeInfinity;
    for (final Weather tranche in tranches) {
      final ({double min, double max}) extremas = _extremas(tranche)!;
      if (extremas.min < min) {
        min = extremas.min;
      }
      if (extremas.max > max) {
        max = extremas.max;
      }
    }
    final Weather representant = tranches.reduce(
      (Weather a, Weather b) =>
          _distanceMidi(a, fuseau) <= _distanceMidi(b, fuseau) ? a : b,
    );
    resultat.add(
      PrevisionJour(
        date: jour,
        temperatureMin: min,
        temperatureMax: max,
        representant: representant,
        estAujourdhui: jour == jourReference,
      ),
    );
  }
  return resultat;
}
