import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/model/services/favorites_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('ajoute, déduplique et conserve les villes favorites', () async {
    final FavoritesStore store = SharedPreferencesFavoritesStore();

    expect(await store.lire(), isEmpty);
    await store.ajouter('  Paris  ');
    await store.ajouter('paris');
    await store.ajouter('Niamey');

    expect(await store.lire(), <String>['Paris', 'Niamey']);

    await store.retirer('PARIS');
    expect(await store.lire(), <String>['Niamey']);
  });

  test('les favoris survivent à une nouvelle instance du magasin', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final FavoritesStore premiere = SharedPreferencesFavoritesStore();
    await premiere.ajouter('Lyon');

    final FavoritesStore seconde = SharedPreferencesFavoritesStore();

    expect(await seconde.lire(), <String>['Lyon']);
  });

  test('le magasin en mémoire ignore les saisies vides', () async {
    final FavoritesStore store = InMemoryFavoritesStore();

    await store.ajouter('   ');
    await store.ajouter('Dakar');
    await store.ajouter('Dakar');

    expect(await store.lire(), <String>['Dakar']);
  });
}
