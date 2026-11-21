import 'package:weather/weather.dart';

/// Une journée de prévisions, regroupée dans le fuseau de la ville observée.
class PrevisionJour {
  const PrevisionJour({
    required this.date,
    required this.temperatureMin,
    required this.temperatureMax,
    required this.representant,
    this.estAujourdhui = false,
  });

  /// Minuit local de la journée, utilisé pour le libellé.
  final DateTime date;

  final double temperatureMin;
  final double temperatureMax;

  /// Tranche de trois heures la plus proche de midi : son icône et sa
  /// description représentent la journée.
  final Weather representant;

  final bool estAujourdhui;
}

/// Observation courante enrichie des prévisions déjà exploitées par le service.
class WeatherReport {
  const WeatherReport({
    required this.actuel,
    this.previsions = const <PrevisionJour>[],
  });

  final Weather actuel;
  final List<PrevisionJour> previsions;
}
