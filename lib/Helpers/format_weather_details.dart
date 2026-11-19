import 'package:intl/intl.dart';

final NumberFormat _nombreEntier = NumberFormat('#,##0', 'fr_FR');
final NumberFormat _nombreDecimal = NumberFormat('#,##0.0', 'fr_FR');

const String _mesureAbsente = '—';

const List<String> _pointsCardinaux = <String>[
  'Nord',
  'Nord-Est',
  'Est',
  'Sud-Est',
  'Sud',
  'Sud-Ouest',
  'Ouest',
  'Nord-Ouest',
];

/// Convertit une vitesse en m/s (unité OpenWeatherMap) en km/h.
String formatVentVitesse(double? metresParSeconde) {
  if (metresParSeconde == null) {
    return _mesureAbsente;
  }
  return '${_nombreEntier.format(metresParSeconde * 3.6)} km/h';
}

/// Arrondit un azimut en degrés au point cardinal français le plus proche.
String formatVentDirection(double? degres) {
  if (degres == null) {
    return _mesureAbsente;
  }
  final double azimuth = ((degres % 360) + 360) % 360;
  final int index = ((azimuth + 22.5) ~/ 45) % 8;
  return _pointsCardinaux[index];
}

/// Affiche une pression en hPa avec le séparateur de milliers français.
String formatPression(double? hectopascals) {
  if (hectopascals == null) {
    return _mesureAbsente;
  }
  return '${_nombreEntier.format(hectopascals)} hPa';
}

/// Affiche une hauteur de précipitation en millimètres.
String formatPluie(double? millimetres) {
  if (millimetres == null) {
    return _mesureAbsente;
  }
  return '${_nombreDecimal.format(millimetres)} mm';
}

/// Affiche un pourcentage entier.
String formatPourcentage(double? valeur) {
  if (valeur == null) {
    return _mesureAbsente;
  }
  return '${_nombreEntier.format(valeur)} %';
}
