import 'package:meteo/model/failures.dart';

/// Façade conservée pour les appels existants : le message vit désormais
/// dans la raison typée, et n'est plus dupliqué ici.
String friendlyWeatherError(Object error) =>
    classifyWeatherError(error).message;

String friendlyLocationError(Object error) =>
    classifyLocationError(error).message;
