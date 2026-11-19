# Météo

**Application météo Flutter avec géolocalisation — MVVM (BLoC comme ViewModel) + get_it**

[Live demo](https://meteo-brown-psi.vercel.app/)

[![Flutter CI](https://github.com/Idjibo33/meteo/actions/workflows/flutter.yml/badge.svg?branch=main)](https://github.com/Idjibo33/meteo/actions/workflows/flutter.yml)

<img src="assets/screenshots/Screenshot_20260328_152731.png" alt="Écran principal de l'application" width="400">

## Fonctionnalités

- **Géolocalisation :** récupération de la position actuelle de l'utilisateur (`geolocator`).
- **Météo actuelle :** conditions, température et détails via l'API **OpenWeatherMap** (package `weather`).
- **Conditions illustrées :** mapping des conditions météo vers des icônes dédiées.
- **Interface responsive :** adaptation aux différentes tailles d'écran.

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
├── constants.dart                # Couleurs
├── Helpers/                      # Transverses : get_it, formatage, responsive, conditions météo
├── model/                        # Données et règles métier
│   ├── failures.dart             # Raisons d'échec typées et geste de reprise associé
│   └── services/                 # weather_service (API), geolocator_service
├── view/                         # Présentation
│   ├── screens/                  # Écran principal
│   └── widgets/                  # Fond, propriétés
└── viewmodel/                    # WeatherBloc, événements, états (machine unique)
```

La `view` n'accède jamais directement aux services : elle pilote le ViewModel via
`BlocProvider` / `BlocBuilder`, qui expose les états `WeatherLocating`, `WeatherLoading`,
`WeatherSuccess` et `WeatherFailure`.

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
