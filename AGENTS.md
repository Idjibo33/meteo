# meteo — AGENTS.md

## Vérifier

- Ordre de la CI (`.github/workflows/flutter.yml`) : `flutter pub get` → `flutter analyze` → `flutter test` → `flutter build web --release`. Elle s'exécute sur `main` et `develop`.
- Tests : `flutter test` → 65 tests dans 10 fichiers, dont `test/weather_state_machine_test.dart` (machine à états), `test/weather_screen_test.dart` (widget) et `test/loading_view_test.dart` (aperçu de chargement).
- Lancer l'app : `flutter run --dart-define-from-file=.env -d <id-appareil>`. Le fichier `.env` contient `OPENWEATHER_API_KEY=<clé>` et est gitignoré. Modifier `.env` impose un redémarrage complet, pas un hot reload.
- Déploiement Vercel (`vercel.json`) : `flutter build web --release --dart-define=OPENWEATHER_API_KEY=$OPENWEATHER_API_KEY`, sortie `build/web`. La variable est configurée côté Vercel, pas dans le dépôt ; `main` alimente la prod.
- La clé est lue par `String.fromEnvironment('OPENWEATHER_API_KEY')` dans `lib/model/services/weather_service.dart`. Aucune clé ni secret dans le code, les commits ou les captures.
- `flutter analyze` ignore les infos `deprecated_member_use` préexistantes sur `package:flutter/material.dart` (via `analysis_options.yaml`) : ce bruit n'est pas une régression et ne doit pas faire échouer la CI.
- `weather`, `geolocator` et `flutter_bloc` n'ont pas de contrainte dans `pubspec.yaml` : `pubspec.lock` fait foi (3.2.1 / 14.0.2 / 9.1.1). Éviter un `flutter pub upgrade` gratuit. `flutter test` et `flutter run` churnent parfois le lockfile : le restaurer avant de committer.

## Architecture (MVVM)

- `lib/model/` : services d'accès aux données (`services/weather_service.dart`, `services/geolocator_service.dart`) et raisons d'échec typées (`failures.dart`).
- `lib/view/` : `screens/weather_screen.dart` et `widgets/` — présentation seule, branchée sur le ViewModel via `BlocProvider`/`BlocBuilder`. `widgets/weather_content.dart` est l'unique écran, utilisé pour le succès comme pour les chargements : seules les valeurs sont remplacées par des `WeatherShimmer` (définis dans `widgets/loading_weather.dart`).
- `lib/viewmodel/` : `WeatherBloc` + événements + états. C'est l'implémentation BLoC du ViewModel et l'unique machine à états de l'app.
- `lib/Helpers/` : transverses (DI get_it, formatage, responsive, mapping condition → icône) ; `lib/constants.dart` : tokens de la palette noir/blanc/teal (`#26A69A` est le seul accent).
- UI : fond noir uni, pas de dégradé ni d'ombre décorative, pas d'émoji comme icône (icônes Material vectorielles), chiffres en `FontFeature.tabularFigures()`. Toute nouvelle couleur doit passer par `lib/constants.dart`.
- Imports sensibles à la casse : `package:meteo/Helpers/...` (majuscule historique), `package:meteo/model/...`, `package:meteo/view/...`, `package:meteo/viewmodel/...` (couches MVVM en minuscules).

## Wiring

- `lib/main.dart` : `configureDependencies()`, `initializeDateFormatting('fr_FR')`, puis un `BlocProvider<WeatherBloc>` qui émet `StartWeather`. Plus de `FutureBuilder` ni d'écran d'erreur local.
- `WeatherBloc` est la machine unique : `WeatherInitial → WeatherLocating → WeatherLoading → WeatherSuccess | WeatherFailure`. La position est portée par les états, pas stockée dans un champ caché ; `RefreshWeather` la réutilise, `RetryLocation` reprend depuis la géolocalisation.
- `lib/model/failures.dart` : raisons d'échec typées et `requiresRelocation`, qui choisit le bon « Réessayer ». `friendlyWeatherError`/`friendlyLocationError` ne sont que des façades pour les messages.
- `WeatherBloc` accepte `WeatherService` et `GeolocatorService` injectables (sinon get_it, résolu paresseusement pour le second) : les tests n'ont pas besoin de `configureDependencies()`.

## Tests

- Réutiliser `test/fixtures/weather_fixture.dart` : `buildWeatherFixture`, `buildTestPosition`, `FakeWeatherService` et `FakeGeolocatorService`. Pas de mockito dans le projet.
- Injecter les faux services dans `WeatherBloc` : aucun test n'appelle la vraie API OpenWeatherMap ni la géolocalisation de l'appareil.
- Les tests de widget fixent `tester.view.physicalSize` et `devicePixelRatio = 1.0` avec `addTearDown(tester.view.reset)` ; ceux qui formatent des dates appellent `initializeDateFormatting('fr_FR')` dans `setUpAll`.
- Plusieurs assertions portent sur des chaînes françaises exactes et des largeurs de 480 px : modifier le copier ou `MaxWidthContainer` casse plusieurs tests.

## Conventions

- Français pour les réponses, les libellés UI, les noms de tests et les commits (Conventional Commits atomiques).
- `main` = prod (déployée par Vercel), `develop` = dev. Les branches de travail (`feat/...`, `fix/...`, `chore/...`) partent de `develop` et y reviennent ; la promotion `develop` → `main` demande un accord explicite.
- Ne pas push, merger ou déployer sans accord explicite.
- Le brief initial (périmètre de l'audit, priorités) est dans `PROMPT_INITIAL.md`.
