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

  test('une date absente reste absente', () {
    expect(formatHourOrDash(null), '—');
    expect(formatCurrentDateOrDash(null), '—');
    expect(formatHourOrDash(DateTime(2026, 10, 14, 9, 5)), '09:05');
  });

  test('le fuseau de l’API est appliqué à l’heure d’observation', () {
    final DateTime observationUtc = DateTime.utc(2026, 11, 19, 8, 19);

    expect(formatDateAvecFuseau(observationUtc, 3600), 'jeudi 19 ∙ 09:19');
    expect(formatHeureAvecFuseau(observationUtc, 3600), '09:19');
  });

  test('un fuseau négatif décale aussi l’heure affichée', () {
    expect(
      formatHeureAvecFuseau(DateTime.utc(2026, 11, 19, 15, 5), -18000),
      '10:05',
    );
  });

  test('sans fuseau connu, la date est affichée telle quelle', () {
    expect(
      formatDateAvecFuseau(DateTime(2026, 11, 19, 8, 19), null),
      'jeudi 19 ∙ 08:19',
    );
    expect(formatHeureAvecFuseau(null, 3600), '—');
    expect(formatDateAvecFuseau(null, 3600), '—');
  });
}
