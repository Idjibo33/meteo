import 'package:shared_preferences/shared_preferences.dart';

/// Persistance des villes favorites, derrière une interface pour les tests.
abstract class FavoritesStore {
  Future<List<String>> lire();
  Future<void> ajouter(String ville);
  Future<void> retirer(String ville);
}

String _nettoyer(String ville) => ville.trim();

List<String> _sansDoublon(Iterable<String> villes) {
  final Set<String> vus = <String>{};
  final List<String> resultat = <String>[];
  for (final String ville in villes) {
    final String nom = _nettoyer(ville);
    if (nom.isEmpty || !vus.add(nom.toLowerCase())) {
      continue;
    }
    resultat.add(nom);
  }
  return resultat;
}

/// Magasin en mémoire : repli quand le stockage natif n'est pas disponible.
class InMemoryFavoritesStore implements FavoritesStore {
  InMemoryFavoritesStore([Iterable<String>? initial])
    : _villes = _sansDoublon(initial ?? const <String>[]);

  final List<String> _villes;

  @override
  Future<List<String>> lire() async => List<String>.unmodifiable(_villes);

  @override
  Future<void> ajouter(String ville) async {
    final List<String> propres = _sansDoublon(<String>[..._villes, ville]);
    _villes
      ..clear()
      ..addAll(propres);
  }

  @override
  Future<void> retirer(String ville) async {
    final String nom = _nettoyer(ville).toLowerCase();
    _villes.removeWhere((String v) => v.toLowerCase() == nom);
  }
}

/// Stockage local persistant, disponible sur mobile, desktop et web.
class SharedPreferencesFavoritesStore implements FavoritesStore {
  SharedPreferencesFavoritesStore({SharedPreferences? preferences})
    : _preferences = preferences;

  static const String cleVillesFavorites = 'meteo.villes_favorites';

  final SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs {
    final SharedPreferences? prefs = _preferences;
    return prefs != null
        ? Future<SharedPreferences>.value(prefs)
        : SharedPreferences.getInstance();
  }

  @override
  Future<List<String>> lire() async {
    final List<String> brut =
        (await _prefs).getStringList(cleVillesFavorites) ?? const <String>[];
    return _sansDoublon(brut);
  }

  @override
  Future<void> ajouter(String ville) async {
    final SharedPreferences prefs = await _prefs;
    final List<String> brut =
        prefs.getStringList(cleVillesFavorites) ?? const <String>[];
    await prefs.setStringList(
      cleVillesFavorites,
      _sansDoublon(<String>[...brut, ville]),
    );
  }

  @override
  Future<void> retirer(String ville) async {
    final SharedPreferences prefs = await _prefs;
    final String nom = _nettoyer(ville).toLowerCase();
    final List<String> restants = (await lire())
        .where((String v) => v.toLowerCase() != nom)
        .toList();
    await prefs.setStringList(cleVillesFavorites, restants);
  }
}
