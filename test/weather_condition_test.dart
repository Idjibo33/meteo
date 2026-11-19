import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/Helpers/weather_condition.dart';
import 'package:weather/weather.dart';

import 'fixtures/weather_fixture.dart';

Weather _sansLibelle({required int code, required String icon}) {
  final Map<String, dynamic> json = buildWeatherFixture().toJson()!;
  json['weather'] = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': code,
      'main': null,
      'description': null,
      'icon': icon,
    },
  ];
  return Weather(json);
}

void main() {
  test('chaque groupe météo pointe vers une illustration présente', () {
    final Map<String, String> attendus = <String, String>{
      'Thunderstorm': 'assets/1.png',
      'Drizzle': 'assets/2.png',
      'Rain': 'assets/3.png',
      'Snow': 'assets/4.png',
      'Atmosphere': 'assets/5.png',
      'Clear': 'assets/6.png',
      'Clouds': 'assets/7.png',
    };

    attendus.forEach((String condition, String illustration) {
      expect(
        getWeatherDescriptionImage(buildWeatherFixture(weatherMain: condition)),
        illustration,
        reason: condition,
      );
      expect(File(illustration).existsSync(), isTrue, reason: illustration);
    });
  });

  test('un ciel dégagé utilise la lune la nuit et le soleil le jour', () {
    expect(
      getWeatherDescriptionImage(
        buildWeatherFixture(weatherMain: 'Clear', weatherIcon: '01d'),
      ),
      'assets/6.png',
    );
    expect(
      getWeatherDescriptionImage(
        buildWeatherFixture(weatherMain: 'Clear', weatherIcon: '01n'),
      ),
      'assets/12.png',
    );
    expect(File('assets/12.png').existsSync(), isTrue);
  });

  test('un ciel couvert se distingue des nuages épars', () {
    expect(
      getWeatherDescriptionImage(
        buildWeatherFixture(weatherMain: 'Clouds', weatherIcon: '03d'),
      ),
      'assets/7.png',
    );
    expect(
      getWeatherDescriptionImage(
        buildWeatherFixture(weatherMain: 'Clouds', weatherIcon: '04d'),
      ),
      'assets/8.png',
    );
  });

  test('le libellé est accepté en minuscules', () {
    expect(
      getWeatherDescriptionImage(buildWeatherFixture(weatherMain: 'clear')),
      'assets/6.png',
    );
  });

  test('le code numérique sert de repli quand le libellé manque', () {
    expect(
      getWeatherDescriptionImage(_sansLibelle(code: 601, icon: '13d')),
      'assets/4.png',
    );
    expect(
      getWeatherDescriptionImage(_sansLibelle(code: 800, icon: '01n')),
      'assets/12.png',
    );
  });

  test('une météo absente ou inconnue reste sur une illustration valide', () {
    expect(getWeatherDescriptionImage(null), 'assets/8.png');
    expect(
      getWeatherDescriptionImage(
        buildWeatherFixture(weatherMain: 'Inconnu', weatherConditionCode: -1),
      ),
      'assets/8.png',
    );
    expect(File('assets/8.png').existsSync(), isTrue);
  });
}
