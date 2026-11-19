import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/Helpers/daily_extremes.dart';
import 'package:weather/weather.dart';

import 'fixtures/weather_fixture.dart';

Weather _prevision({
  required DateTime date,
  required double minKelvin,
  required double maxKelvin,
  int fuseau = 0,
}) {
  return buildWeatherFixture(
    tempMinKelvin: minKelvin,
    tempMaxKelvin: maxKelvin,
    observationEpoch: epochSeconds(date),
    fuseau: fuseau,
  );
}

void main() {
  test('remplace des extremas identiques par ceux des prévisions du jour', () {
    final Weather actuel = buildWeatherFixture(
      tempKelvin: 310.15,
      tempMinKelvin: 310.15,
      tempMaxKelvin: 310.15,
      observationEpoch: epochSeconds(DateTime.utc(2026, 11, 19, 10)),
    );
    final Weather ajuste = appliquerExtremasDuJour(actuel, <Weather>[
      _prevision(
        date: DateTime.utc(2026, 11, 19, 12),
        minKelvin: 306.15,
        maxKelvin: 312.15,
      ),
      _prevision(
        date: DateTime.utc(2026, 11, 19, 15),
        minKelvin: 308.15,
        maxKelvin: 314.15,
      ),
    ]);

    expect(ajuste.tempMin?.celsius, closeTo(33, 0.01));
    expect(ajuste.tempMax?.celsius, closeTo(41, 0.01));
    expect(actuel.tempMin?.celsius, closeTo(37, 0.01));
    expect(actuel.tempMax?.celsius, closeTo(37, 0.01));
  });

  test('ignore les prévisions d un autre jour', () {
    final Weather actuel = buildWeatherFixture(
      observationEpoch: epochSeconds(DateTime.utc(2026, 11, 19, 10)),
    );
    final Weather ajuste = appliquerExtremasDuJour(actuel, <Weather>[
      _prevision(
        date: DateTime.utc(2026, 11, 20, 12),
        minKelvin: 290.15,
        maxKelvin: 292.15,
      ),
    ]);

    expect(ajuste.tempMin?.celsius, actuel.tempMin?.celsius);
    expect(ajuste.tempMax?.celsius, actuel.tempMax?.celsius);
  });

  test('regroupe les prévisions selon le fuseau de la station', () {
    final Weather actuel = buildWeatherFixture(
      tempKelvin: 302.15,
      observationEpoch: epochSeconds(DateTime.utc(2026, 11, 19, 23, 30)),
      fuseau: 3600,
    );
    final Weather ajuste = appliquerExtremasDuJour(actuel, <Weather>[
      _prevision(
        date: DateTime.utc(2026, 11, 19, 23),
        minKelvin: 300.15,
        maxKelvin: 305.15,
        fuseau: 3600,
      ),
      _prevision(
        date: DateTime.utc(2026, 11, 19, 22),
        minKelvin: 280.15,
        maxKelvin: 282.15,
        fuseau: 3600,
      ),
    ]);

    expect(ajuste.tempMin?.celsius, closeTo(27, 0.01));
    expect(ajuste.tempMax?.celsius, closeTo(32, 0.01));
  });

  test('garde la météo courante si aucune prévision n est exploitable', () {
    final Weather actuel = buildWeatherFixture(
      observationEpoch: epochSeconds(DateTime.utc(2026, 11, 19, 10)),
    );

    final Weather vide = appliquerExtremasDuJour(actuel, const <Weather>[]);
    expect(vide.tempMin?.celsius, actuel.tempMin?.celsius);
    expect(vide.tempMax?.celsius, actuel.tempMax?.celsius);

    final Map<String, dynamic> json = Map<String, dynamic>.from(
      actuel.toJson()!,
    );
    json.remove('dt');
    final Weather sansDate = Weather(json);
    final Weather repli = appliquerExtremasDuJour(sansDate, <Weather>[
      _prevision(
        date: DateTime.utc(2026, 11, 19, 12),
        minKelvin: 300,
        maxKelvin: 305,
      ),
    ]);
    expect(repli.tempMin?.celsius, sansDate.tempMin?.celsius);
  });
}
