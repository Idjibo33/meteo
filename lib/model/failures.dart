import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

/// Raison typée d'un échec, et donc du geste de reprise attendu.
sealed class WeatherFailureReason extends Equatable {
  const WeatherFailureReason(this.message);

  final String message;

  /// Vrai quand l'échec vient de la localisation : il faut relancer
  /// la géolocalisation, pas seulement l'appel météo.
  bool get requiresRelocation => switch (this) {
    LocationDisabledFailure() ||
    LocationPermissionFailure() ||
    LocationTimeoutFailure() ||
    LocationUnknownFailure() => true,
    ApiKeyFailure() || NetworkFailure() || WeatherUnknownFailure() => false,
  };

  @override
  List<Object?> get props => [message];
}

final class ApiKeyFailure extends WeatherFailureReason {
  const ApiKeyFailure() : super('Clé API météo manquante ou invalide.');
}

final class NetworkFailure extends WeatherFailureReason {
  const NetworkFailure()
    : super('Impossible de récupérer la météo. Vérifiez votre connexion.');
}

final class WeatherUnknownFailure extends WeatherFailureReason {
  const WeatherUnknownFailure()
    : super('Une erreur est survenue. Veuillez réessayer.');
}

final class LocationDisabledFailure extends WeatherFailureReason {
  const LocationDisabledFailure() : super('Service de localisation désactivé.');
}

final class LocationPermissionFailure extends WeatherFailureReason {
  const LocationPermissionFailure()
    : super('Permission de localisation refusée.');
}

final class LocationTimeoutFailure extends WeatherFailureReason {
  const LocationTimeoutFailure() : super('Localisation trop lente. Réessayez.');
}

final class LocationUnknownFailure extends WeatherFailureReason {
  const LocationUnknownFailure()
    : super('Impossible d\'obtenir votre position. Réessayez.');
}

WeatherFailureReason classifyWeatherError(Object error) {
  if (error is TimeoutException) {
    return const NetworkFailure();
  }

  final String description = error.toString().toLowerCase();
  if (description.contains('401') ||
      description.contains('invalid api key') ||
      description.contains('invalid_api_key') ||
      description.contains('unauthorized')) {
    return const ApiKeyFailure();
  }
  if (description.contains('socketexception') ||
      description.contains('failed host lookup') ||
      description.contains('clientexception') ||
      description.contains('timed out') ||
      description.contains('connection')) {
    return const NetworkFailure();
  }
  return const WeatherUnknownFailure();
}

WeatherFailureReason classifyLocationError(Object error) {
  if (error is LocationServiceDisabledException) {
    return const LocationDisabledFailure();
  }
  if (error is PermissionDeniedException) {
    return const LocationPermissionFailure();
  }
  if (error is TimeoutException) {
    return const LocationTimeoutFailure();
  }
  return const LocationUnknownFailure();
}
