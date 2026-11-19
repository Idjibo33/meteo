import 'package:weather/weather.dart';

/// Illustrations de la condition météo, toutes dans `assets/`.
const String _orage = 'assets/1.png';
const String _bruine = 'assets/2.png';
const String _pluie = 'assets/3.png';
const String _neige = 'assets/4.png';
const String _brume = 'assets/5.png';
const String _soleil = 'assets/6.png';
const String _nuages = 'assets/7.png';
const String _couvert = 'assets/8.png';
const String _lune = 'assets/12.png';

/// Choisit l'illustration qui accompagne la température.
///
/// Le groupe OpenWeatherMap (`weatherMain`) suffit dans la plupart des cas.
/// Le code d'icône (`01d`, `01n`…) affine deux cas : la lune la nuit et le
/// ciel couvert. Le code numérique (`weatherConditionCode`) sert de repli
/// quand le libellé est absent ou inattendu.
String getWeatherDescriptionImage(Weather? weather) {
  final String main = (weather?.weatherMain ?? '').trim().toLowerCase();
  final String? icon = weather?.weatherIcon;
  final bool nuit = icon?.endsWith('n') ?? false;

  final String? illustration = switch (main) {
    'thunderstorm' => _orage,
    'drizzle' => _bruine,
    'rain' => _pluie,
    'snow' => _neige,
    'atmosphere' => _brume,
    'clear' => nuit ? _lune : _soleil,
    'clouds' => icon == '04d' || icon == '04n' ? _couvert : _nuages,
    _ => null,
  };
  if (illustration != null) {
    return illustration;
  }

  final int? code = weather?.weatherConditionCode;
  if (code == null) {
    return _couvert;
  }
  return switch (code) {
    >= 200 && < 300 => _orage,
    >= 300 && < 400 => _bruine,
    >= 500 && < 600 => _pluie,
    >= 600 && < 700 => _neige,
    >= 700 && < 800 => _brume,
    800 => nuit ? _lune : _soleil,
    _ => _couvert,
  };
}
