part of 'weather_bloc.dart';

@immutable
sealed class WeatherEvent {
  const WeatherEvent();
}

/// Démarre le parcours complet : localisation puis météo.
final class StartWeather extends WeatherEvent {
  const StartWeather();
}

/// Reprend au niveau de la localisation après un échec de position.
final class RetryLocation extends WeatherEvent {
  const RetryLocation();
}

/// Repli sans géolocalisation : charge la météo d'une ville saisie par
/// l'utilisateur (permission refusée, service désactivé, plateforme sans GPS).
final class SearchCity extends WeatherEvent {
  const SearchCity(this.ville);

  final String ville;
}

/// Charge la météo pour une position déjà connue (injectée, ex. tests).
final class FetchWeather extends WeatherEvent {
  final Position position;
  const FetchWeather(this.position);
}

/// Relance la météo avec la position portée par l'état courant.
final class RefreshWeather extends WeatherEvent {
  const RefreshWeather();
}

/// L'application revient au premier plan : on vérifie la fraîcheur des données.
final class AppResumed extends WeatherEvent {
  const AppResumed();
}

/// L'application passe en arrière-plan : on suspend le rafraîchissement périodique.
final class AppPaused extends WeatherEvent {
  const AppPaused();
}
