import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/Helpers/format_temperature.dart';

void main() {
  test('arrondit la valeur et ajoute l\'unité', () {
    expect(formatTemperature(18.4), '18 °C');
    expect(formatTemperature(19.6), '20 °C');
    expect(formatTemperature(-3.2), '-3 °C');
  });

  test('retourne un tiret quand la valeur est absente', () {
    expect(formatTemperature(null), '—');
  });
}
