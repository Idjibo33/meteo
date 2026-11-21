# meteo — AGENTS.md

## Vérifier

- Ordre de la CI (`.github/workflows/flutter.yml`) : `flutter pub get` → `flutter analyze` → `flutter test` → `flutter build web --release`. Elle s'exécute sur `main` et `develop`. Sur push, le job `deploy-pages` publie le web sur GitHub Pages (racine pour `main`, `/dev/` pour `develop`) et les jobs `release-meta`, `build-release` (Android, iOS, Linux, Windows) et `release` publient une GitHub Release sans ZIP web : stable sur `main`, pré-release sur `develop`.
- Tests : `flutter test` → 101 tests, dont `test/weather_state_machine_test.dart` (machine à états et repli ville), `test/weather_screen_test.dart` (widget), `test/weather_service_test.dart` (recherche par ville) et `test/loading_view_test.dart` (aperçu de chargement).
- Versions : `version:` du `pubspec.yaml` est la source unique. Le CI en dérive le tag `vX.Y.Z+N` sur `main` et `vX.Y.Z+N-dev.<run>` sur `develop`. L'iOS est compilé sur un runner macOS GitHub en `--no-codesign` : l'IPA est une archive non installable.
- Android : la release utilise `--split-per-abi` (un APK par ABI). `android/app/build.gradle.kts` lit `android/key.properties` pour signer en release ; sans ce fichier, les builds locaux retombent sur la signature debug. La CI décode le keystore depuis les secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD` et `ANDROID_KEY_ALIAS`. `android/key.properties` et les `*.jks` sont gitignorés : ne jamais les committer. Ces APK sont pour l'installation directe ; Play Store demanderait un AAB signé séparément.
- Lancer l'app : `flutter run --dart-define-from-file=.env -d <id-appareil>`. Le fichier `.env` contient `OPENWEATHER_API_KEY=<clé>` et est gitignoré. Modifier `.env` impose un redémarrage complet, pas un hot reload.
- Déploiement web : GitHub Pages, type de source `workflow`. Prod sur `https://idjibo33.github.io/meteo/` (`main`, base href `/meteo/`), test sur `https://idjibo33.github.io/meteo/dev/` (`develop`, base href `/meteo/dev/`). Le job `deploy-pages` compile les deux dans un même artefact pour préserver les deux URL à chaque push. L'artefact Pages porte un nom unique par tentative (`pages-<run>-<attempt>`) et `deploy-pages` cible ce même nom : une relance ne réutilise pas un artefact plus ancien. Le workflow accepte `workflow_dispatch` sur `main`/`develop` pour forcer un redéploiement sans créer de release. Secret GitHub `OPENWEATHER_API_KEY`. Vercel a été déconnecté via `vercel git disconnect` : plus de `vercel.json`, plus de checks Vercel sur les PR. Plus de ZIP web dans les releases.
- La clé est lue par `String.fromEnvironment('OPENWEATHER_API_KEY')` dans `lib/model/services/weather_service.dart`. Aucune clé ni secret dans le code, les commits ou les captures.
- `flutter analyze` ignore les infos `deprecated_member_use` préexistantes sur `package:flutter/material.dart` (via `analysis_options.yaml`) : ce bruit n'est pas une régression et ne doit pas faire échouer la CI.
- `weather`, `geolocator` et `flutter_bloc` n'ont pas de contrainte dans `pubspec.yaml` : `pubspec.lock` fait foi (3.2.1 / 14.0.2 / 9.1.1). Éviter un `flutter pub upgrade` gratuit. `flutter test` et `flutter run` churnent parfois le lockfile : le restaurer avant de committer.

## Architecture (MVVM)

- `lib/model/` : services d'accès aux données (`services/weather_service.dart`, `services/geolocator_service.dart`) et raisons d'échec typées (`failures.dart`).
- `lib/view/` : `screens/weather_screen.dart` et `widgets/` — présentation seule, branchée sur le ViewModel via `BlocProvider`/`BlocBuilder`. `widgets/weather_content.dart` est l'unique écran, utilisé pour le succès comme pour les chargements : seules les valeurs sont remplacées par des `WeatherShimmer` (définis dans `widgets/loading_weather.dart`).
- `lib/viewmodel/` : `WeatherBloc` + événements + états. C'est l'implémentation BLoC du ViewModel et l'unique machine à états de l'app.
- `lib/Helpers/` : transverses (DI get_it, formatage, responsive, mapping condition → icône) ; `lib/constants.dart` : tokens de la palette noir/blanc/teal (`#26A69A` est le seul accent).
- UI : fond noir uni, pas de dégradé ni d'ombre décorative, pas d'émoji comme icône (icônes Material vectorielles), chiffres en `FontFeature.tabularFigures()`. Toute nouvelle couleur doit passer par `lib/constants.dart`.
- Identité : `assets/brand/logo.svg` est la source vectorielle ; `python3 tool/generate_brand_assets.py` régénère les icônes Android/iOS/web/Windows/Linux, le splash web (`web/brand/mark-512.png`) et le favicon. Police Space Grotesk embarquée dans `assets/fonts/` (licence OFL) et déclarée dans `lib/theme.dart`.
- Imports sensibles à la casse : `package:meteo/Helpers/...` (majuscule historique), `package:meteo/model/...`, `package:meteo/view/...`, `package:meteo/viewmodel/...` (couches MVVM en minuscules).

## Wiring

- `lib/main.dart` : `configureDependencies()`, `initializeDateFormatting('fr_FR')`, puis un `BlocProvider<WeatherBloc>` qui émet `StartWeather`. Plus de `FutureBuilder` ni d'écran d'erreur local.
- `WeatherBloc` est la machine unique : `WeatherInitial → WeatherLocating → WeatherLoading → WeatherSuccess | WeatherFailure`. Le lieu (position GPS **ou** ville saisie) est porté par les états, pas stockée dans un champ caché ; `RefreshWeather` réutilise le lieu courant, `RetryLocation` reprend depuis la géolocalisation, `SearchCity` est le repli sans position.
- Repli sans position : `WeatherService.getWeatherByCity` utilise `currentWeatherByCityName`/`fiveDayForecastByCityName` avec la même clé OpenWeatherMap. Android/iOS ne demandent que la localisation au premier plan ; Linux n'a aucun plugin de géolocator, Windows en a un. Un refus web ouvre directement le champ « Ville ».
- `lib/model/failures.dart` : raisons d'échec typées (dont `VilleIntrouvableFailure`) et `requiresRelocation`, qui choisit le bon bouton. `friendlyWeatherError`/`friendlyLocationError` ne sont que des façades pour les messages.
- `WeatherBloc` accepte `WeatherService` et `GeolocatorService` injectables (sinon get_it, résolu paresseusement pour le second) : les tests n'ont pas besoin de `configureDependencies()`.

## Tests

- Réutiliser `test/fixtures/weather_fixture.dart` : `buildWeatherFixture`, `buildTestPosition`, `FakeWeatherService` et `FakeGeolocatorService`. Pas de mockito dans le projet.
- Injecter les faux services dans `WeatherBloc` : aucun test n'appelle la vraie API OpenWeatherMap ni la géolocalisation de l'appareil.
- Les tests de widget fixent `tester.view.physicalSize` et `devicePixelRatio = 1.0` avec `addTearDown(tester.view.reset)` ; ceux qui formatent des dates appellent `initializeDateFormatting('fr_FR')` dans `setUpAll`.
- Plusieurs assertions portent sur des chaînes françaises exactes et des largeurs de 480 px : modifier le copier ou `MaxWidthContainer` casse plusieurs tests.

## Conventions

- Français pour les réponses, les libellés UI, les noms de tests et les commits (Conventional Commits atomiques).
- `main` = prod (déployée sur GitHub Pages), `develop` = dev. Les branches de travail (`feat/...`, `fix/...`, `chore/...`) partent de `develop` et y reviennent ; la promotion `develop` → `main` demande un accord explicite.
- Ne pas push, merger ou déployer sans accord explicite.
- Le brief initial (périmètre de l'audit, priorités) est dans `PROMPT_INITIAL.md`.
