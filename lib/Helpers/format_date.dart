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
