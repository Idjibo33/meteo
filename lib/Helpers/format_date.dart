import 'package:intl/intl.dart';

const String _localeFrancais = 'fr_FR';

String formatCurrentDate(DateTime date) {
  final String day = DateFormat.EEEE(_localeFrancais).format(date);
  final String dayDate = DateFormat.d(_localeFrancais).format(date);
  final String hour = DateFormat.Hm(_localeFrancais).format(date);
  return '$day $dayDate ∙ $hour';
}

String formatHour(DateTime date) {
  return DateFormat.Hm(_localeFrancais).format(date);
}

/// Une date absente s'affiche comme absente, jamais comme l'heure courante.
String formatHourOrDash(DateTime? date) =>
    date == null ? '—' : formatHour(date);

String formatCurrentDateOrDash(DateTime? date) =>
    date == null ? '—' : formatCurrentDate(date);

/// Décalage en secondes renvoyé par OpenWeather dans le champ `timezone`.
Duration? _decalageFuseau(Object? fuseau) {
  if (fuseau is int) {
    return Duration(seconds: fuseau);
  }
  if (fuseau is num) {
    return Duration(seconds: fuseau.round());
  }
  return null;
}

String _formaterAvecFuseau(
  DateTime? date,
  Object? fuseau,
  String Function(DateTime) formateur,
) {
  if (date == null) {
    return '—';
  }
  final Duration? decalage = _decalageFuseau(fuseau);
  if (decalage == null) {
    return formateur(date);
  }
  // Le paquet weather convertit `dt` en heure locale du téléphone : on repasse
  // par UTC avant d'appliquer le fuseau de la ville observée.
  return formateur(date.toUtc().add(decalage));
}

/// Date d'observation affichée dans le fuseau de la ville, pas du téléphone.
String formatDateAvecFuseau(DateTime? date, Object? fuseau) =>
    _formaterAvecFuseau(date, fuseau, formatCurrentDate);

/// Heure (lever/coucher) affichée dans le fuseau de la ville observée.
String formatHeureAvecFuseau(DateTime? date, Object? fuseau) =>
    _formaterAvecFuseau(date, fuseau, formatHour);
