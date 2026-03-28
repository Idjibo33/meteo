import 'package:intl/intl.dart';

String formatCurrentDate(DateTime date) {
  String day = DateFormat.EEEE().format(date);
  String dayDate = DateFormat.d().format(date);
  String hour = DateFormat.Hm().format(date);
  return "$day $dayDate ∙ $hour";
}

String formatHour(DateTime date) {
  String time = DateFormat.Hm().format(date);
  return time;
}
