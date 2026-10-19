import 'dart:async';

import 'package:geolocator/geolocator.dart';

const String _cleApiMessage = 'Clé API météo manquante ou invalide.';
const String _reseauMessage =
    'Impossible de récupérer la météo. Vérifiez votre connexion.';
const String _generiqueMessage = 'Une erreur est survenue. Veuillez réessayer.';

String friendlyWeatherError(Object error) {
  if (error is TimeoutException) {
    return _reseauMessage;
  }

  final String description = error.toString().toLowerCase();
  if (description.contains('401') ||
      description.contains('invalid api key') ||
      description.contains('invalid_api_key') ||
      description.contains('unauthorized')) {
    return _cleApiMessage;
  }
  if (description.contains('socketexception') ||
      description.contains('failed host lookup') ||
      description.contains('clientexception') ||
      description.contains('timed out') ||
      description.contains('connection')) {
    return _reseauMessage;
  }
  return _generiqueMessage;
}

String friendlyLocationError(Object error) {
  if (error is LocationServiceDisabledException) {
    return 'Service de localisation désactivé.';
  }
  if (error is PermissionDeniedException) {
    return 'Permission de localisation refusée.';
  }
  if (error is TimeoutException) {
    return 'Localisation trop lente. Réessayez.';
  }
  return 'Impossible d\'obtenir votre position. Réessayez.';
}
