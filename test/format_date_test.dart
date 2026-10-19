import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meteo/Helpers/format_date.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  test('formatCurrentDate affiche le jour en français', () {
    final DateTime date = DateTime(2026, 10, 14, 15, 5);

    expect(formatCurrentDate(date), 'mercredi 14 ∙ 15:05');
  });

  test('formatHour formate en heures:minutes', () {
    expect(formatHour(DateTime(2026, 10, 14, 9, 5)), '09:05');
  });
}
