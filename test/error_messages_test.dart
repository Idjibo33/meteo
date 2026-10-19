import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meteo/Helpers/error_messages.dart';

void main() {
  group('friendlyWeatherError', () {
    test('détecte une clé API absente ou invalide', () {
      expect(
        friendlyWeatherError(Exception('Error: 401 Unauthorized')),
        'Clé API météo manquante ou invalide.',
      );
      expect(
        friendlyWeatherError(Exception('Invalid API key')),
        'Clé API météo manquante ou invalide.',
      );
    });

    test('détecte une erreur réseau', () {
      expect(
        friendlyWeatherError(
          Exception('SocketException: Failed host lookup: openweathermap.org'),
        ),
        'Impossible de récupérer la météo. Vérifiez votre connexion.',
      );
      expect(
        friendlyWeatherError(TimeoutException('timed out')),
        'Impossible de récupérer la météo. Vérifiez votre connexion.',
      );
    });

    test('retourne un message générique pour les autres erreurs', () {
      expect(
        friendlyWeatherError(StateError('boom')),
        'Une erreur est survenue. Veuillez réessayer.',
      );
    });
  });

  group('friendlyLocationError', () {
    test('service de localisation désactivé', () {
      expect(
        friendlyLocationError(LocationServiceDisabledException()),
        'Service de localisation désactivé.',
      );
    });

    test('permission refusée', () {
      expect(
        friendlyLocationError(PermissionDeniedException('denied')),
        'Permission de localisation refusée.',
      );
    });

    test('délai dépassé', () {
      expect(
        friendlyLocationError(TimeoutException('timeout')),
        'Localisation trop lente. Réessayez.',
      );
    });

    test('erreur inconnue', () {
      expect(
        friendlyLocationError(StateError('boom')),
        'Impossible d\'obtenir votre position. Réessayez.',
      );
    });
  });
}
