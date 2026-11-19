# Météo

**Application météo Flutter avec géolocalisation — MVVM (BLoC comme ViewModel) + get_it**

[Live demo](https://meteo-brown-psi.vercel.app/)

[![Flutter CI](https://github.com/Idjibo33/meteo/actions/workflows/flutter.yml/badge.svg?branch=main)](https://github.com/Idjibo33/meteo/actions/workflows/flutter.yml)

## Captures d'écran

**Téléphone (390 px) — vue compacte**

<img src="assets/screenshots/mobile.png" alt="Écran météo sur téléphone" width="300">

**Tablette (800 px) — détails répartis en deux colonnes**

<img src="assets/screenshots/tablette.png" alt="Écran météo sur tablette" width="560">

**Desktop (1440 px) — illustration et détails côte à côte**

<img src="assets/screenshots/desktop.png" alt="Écran météo sur desktop" width="800">

Les captures montrent le thème sombre. Le thème clair se bascule depuis l'en-tête.

## Fonctionnalités

- **Géolocalisation :** récupération de la position actuelle de l'utilisateur (`geolocator`).
- **Météo actuelle :** conditions, température et détails via l'API **OpenWeatherMap** (package `weather`).
- **Conditions illustrées :** mapping des conditions météo vers des icônes dédiées.
- **Données fraîches :** rafraîchissement toutes les 10 min quand l'app est active, et au retour
  au premier plan si l'observation est périmée. L'écran distingue l'heure de l'observation
  (« Observé le … », fournie par l'API) de l'heure du dernier appel (« Actualisé à HH:MM ») et
  affiche « À jour », l'âge de l'observation ou « Données périmées ».
- **Chargement explicite :** un aperçu de la page se construit pendant l'attente, avec une ligne
  indiquant l'étape en cours (« Recherche de votre position… », puis « Récupération de la météo… »)
  et une barre fine sans pourcentage. Les animations sont désactivées si le téléphone le demande.
- **Pull-to-refresh :** tirer la page vers le bas pour actualiser, avec la même ligne d'étape.
  Le geste réutilise la position connue, sans nouvelle géolocalisation ni appel en double ;
  l'heure « Actualisé à » change même quand l'observation de l'API reste la même.
- **Thèmes clair et sombre :** bascule depuis l'en-tête, avec un splash natif unique au démarrage.
- **Interface responsive :** le téléphone garde sa vue compacte (480 px maximum), la tablette
  répartit les détails en deux colonnes et le desktop place l'illustration à côté des détails.
  Le découpage suit la largeur disponible, donc aussi le redimensionnement d'une fenêtre.

## Stack technique

| Domaine | Technologie |
|---|---|
| Framework | Flutter / Dart |
| Gestion d'état | MVVM : BLoC (`flutter_bloc`, `bloc`) comme ViewModel |
| Injection de dépendances | `get_it` |
| Données | `weather` (OpenWeatherMap), `geolocator` |
| Utilitaires | `equatable`, `intl`, `gap` |

## Architecture

```
lib/
├── main.dart                     # Point d'entrée : DI, formatage fr_FR, BlocProvider
├── constants.dart                # Tokens de la palette et accès au thème courant
├── theme.dart                    # Thèmes clair et sombre
├── Helpers/                      # Transverses : DI get_it, formatage, responsive, conditions météo
├── model/                        # Données et règles métier
│   ├── failures.dart             # Raisons d'échec typées et geste de reprise associé
│   └── services/                 # weather_service (API), geolocator_service
├── view/                         # Présentation
│   ├── screens/                  # Écran principal
│   └── widgets/                  # Fond, propriétés, écran et shimmers de chargement
└── viewmodel/                    # WeatherBloc, événements, états (machine unique), ThemeCubit
```

La `view` n'accède jamais directement aux services : elle pilote le ViewModel via
`BlocProvider` / `BlocBuilder`, qui expose les états `WeatherLocating`, `WeatherLoading`,
`WeatherSuccess` et `WeatherFailure`.

## Design

Palette volontairement limitée à trois teintes définies dans `lib/constants.dart` :
fond noir, texte blanc (dont les variantes ne sont que des opacités) et teal `#26A69A`
comme seul accent. Le thème clair inverse le fond et le texte en gardant le même accent.
Aucun dégradé, aucune ombre décorative et aucun émoji utilisé comme icône : la hiérarchie
repose sur la typographie (température en très gros chiffres, ressenti juste dessous,
min/max et horaires dans une grille sobre) et sur l'accent teal réservé aux signaux
actionnables. Le geste « Actualiser » réutilise l'état courant sans repositionner.
Pendant le chargement, l'aperçu reste neutre (aucune valeur inventée) : seules les
valeurs sont remplacées par des shimmers, la structure restant identique.

## Installation

Prérequis : une clé API [OpenWeatherMap](https://openweathermap.org/api) (gratuite pour un usage standard).

```bash
flutter pub get

# La clé n'est pas stockée dans le dépôt : elle est fournie au build
flutter run --dart-define=OPENWEATHER_API_KEY=<votre_clé>

# Ou, pour un usage local, via un .env gitignoré :
# OPENWEATHER_API_KEY=<votre_clé>
flutter run --dart-define-from-file=.env -d <id-appareil>

# Build web / déploiement : passer le même argument
flutter build web --release --dart-define=OPENWEATHER_API_KEY=<votre_clé>
```

> Sans clé valide, l'appel API échoue et l'écran d'erreur s'affiche.

## Vérification

```bash
flutter pub get
flutter analyze
flutter test                 # 94 tests, dont la machine à états et les mises en page
flutter build web --release
```

La CI suit le même ordre sur `main` et `develop`. Les tests n'appellent jamais l'API
ni la géolocalisation de l'appareil : ils injectent des services fictifs via `WeatherBloc`.

## Branches et environnements

| Branche | Rôle |
|---|---|
| `main` | Production — déployée automatiquement par Vercel |
| `develop` | Développement — cible des branches de travail et de la CI |

Les branches `feat/...`, `fix/...` et `chore/...` partent de `develop` et y reviennent via PR.
La promotion `develop` → `main` se fait seulement après validation explicite. La CI
(`.github/workflows/flutter.yml`) couvre les deux branches.

## Limites et prochaines étapes

- Prévisions sur plusieurs jours.
- Épingler une version de Flutter dans la CI (le canal `stable` non figé peut faire apparaître des avertissements de dépréciation).

## Licence

[MIT](LICENSE)
