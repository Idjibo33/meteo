import 'package:meteo/Helpers/format_weather_details.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatage des détails météo', () {
    test('la vitesse du vent passe des m/s aux km/h en français', () {
      expect(formatVentVitesse(5.28), '19 km/h');
      expect(formatVentVitesse(0.5), '2 km/h');
    });

    test('la direction du vent est un point cardinal français', () {
      expect(formatVentDirection(0), 'Nord');
      expect(formatVentDirection(90), 'Est');
      expect(formatVentDirection(180), 'Sud');
      expect(formatVentDirection(315), 'Nord-Ouest');
      expect(formatVentDirection(-45), 'Nord-Ouest');
    });

    test('la pression garde son séparateur de milliers et son unité', () {
      expect(formatPression(1012).replaceAll(RegExp(r'\s'), ''), '1012hPa');
    });

    test('la pluie et les pourcentages utilisent une virgule décimale', () {
      expect(formatPluie(0), '0,0 mm');
      expect(formatPluie(1.25), '1,3 mm');
      expect(formatPourcentage(12), '12 %');
    });

    test('une mesure absente affiche un tiret', () {
      expect(formatVentVitesse(null), '—');
      expect(formatVentDirection(null), '—');
      expect(formatPression(null), '—');
      expect(formatPluie(null), '—');
      expect(formatPourcentage(null), '—');
    });
  });
}
