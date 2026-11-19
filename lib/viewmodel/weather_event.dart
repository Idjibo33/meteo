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

/// Charge la météo pour une position déjà connue (injectée, ex. tests).
final class FetchWeather extends WeatherEvent {
  final Position position;
  const FetchWeather(this.position);
}

/// Relance la météo avec la position portée par l'état courant.
final class RefreshWeather extends WeatherEvent {
  const RefreshWeather();
}
