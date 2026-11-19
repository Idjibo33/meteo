import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/Helpers/freshness.dart';

void main() {
  final DateTime maintenant = DateTime(2026, 11, 19, 12);

  test('une observation de moins de 10 minutes est à jour', () {
    expect(
      formatFraicheur(
        maintenant.subtract(const Duration(minutes: 5)),
        maintenant,
      ),
      'À jour',
    );
  });

  test('une observation entre 10 et 60 minutes affiche son âge', () {
    expect(
      formatFraicheur(
        maintenant.subtract(const Duration(minutes: 25)),
        maintenant,
      ),
      'Observé il y a 25 min',
    );
  });

  test('une observation de plus de 60 minutes est périmée', () {
    expect(
      formatFraicheur(
        maintenant.subtract(const Duration(minutes: 90)),
        maintenant,
      ),
      'Données périmées',
    );
  });

  test('une observation absente est périmée', () {
    expect(formatFraicheur(null, maintenant), 'Données périmées');
  });

  test('une date dans le futur reste à jour malgré l’horloge du téléphone', () {
    expect(
      formatFraicheur(
        maintenant.add(const Duration(minutes: 3)),
        maintenant,
      ),
      'À jour',
    );
  });

  test('les seuils sont des bornes explicites', () {
    expect(
      formatFraicheur(
        maintenant.subtract(const Duration(minutes: 10)),
        maintenant,
      ),
      'Observé il y a 10 min',
    );
    expect(
      formatFraicheur(
        maintenant.subtract(const Duration(minutes: 60)),
        maintenant,
      ),
      'Données périmées',
    );
  });

  test('le seuil de fraîcheur décide du rafraîchissement au retour', () {
    expect(
      observationEstPerimee(
        maintenant.subtract(const Duration(minutes: 2)),
        maintenant,
        seuil: const Duration(minutes: 10),
      ),
      isFalse,
    );
    expect(
      observationEstPerimee(
        maintenant.subtract(const Duration(minutes: 12)),
        maintenant,
        seuil: const Duration(minutes: 10),
      ),
      isTrue,
    );
    expect(
      observationEstPerimee(null, maintenant, seuil: const Duration(minutes: 10)),
      isTrue,
    );
  });
}
