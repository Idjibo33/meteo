import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/Helpers/daily_forecast.dart';
import 'package:meteo/model/prevision_jour.dart';
import 'package:weather/weather.dart';

import 'fixtures/weather_fixture.dart';

void main() {
  test('regroupe les tranches en cinq jours calendaires', () {
    final List<PrevisionJour> jours = grouperPrevisionsParJour(
      buildForecastFixture(),
      reference: DateTime.utc(2026, 11, 22, 10),
      fuseau: 3600,
    );

    expect(jours, hasLength(5));
    expect(jours.first.date, DateTime(2026, 11, 22));
    expect(jours.last.date, DateTime(2026, 11, 26));
    expect(jours.first.estAujourdhui, isTrue);
    expect(jours.last.estAujourdhui, isFalse);
    // Deux tranches par jour : 17/27 °C puis 18/28 °C.
    expect(jours.first.temperatureMin, closeTo(17, 0.01));
    expect(jours.first.temperatureMax, closeTo(28, 0.01));
  });

  test('respecte le fuseau de la ville pour le jour courant', () {
    final List<PrevisionJour> jours = grouperPrevisionsParJour(
      const <Weather>[],
      reference: DateTime.utc(2026, 11, 21, 23, 30),
      fuseau: 3600,
    );
    expect(jours, isEmpty);

    final List<PrevisionJour> decale = grouperPrevisionsParJour(
      buildForecastFixture(
        departUtc: DateTime.utc(2026, 11, 21, 23, 30),
        nombreJours: 1,
      ),
      reference: DateTime.utc(2026, 11, 21, 23, 30),
      fuseau: 3600,
    );

    expect(decale.single.date, DateTime(2026, 11, 22));
    expect(decale.single.estAujourdhui, isTrue);
  });

  test('limite le nombre de jours affichés', () {
    final List<PrevisionJour> jours = grouperPrevisionsParJour(
      buildForecastFixture(nombreJours: 8),
      reference: DateTime.utc(2026, 11, 22, 10),
      fuseau: 3600,
    );

    expect(jours, hasLength(nombreJoursPrevisions));
  });
}
