part of 'weather_bloc.dart';

@immutable
sealed class WeatherEvent {
  const WeatherEvent();
}

final class FetchWeather extends WeatherEvent {
  final Position position;
  const FetchWeather(this.position);
}

final class RefreshWeather extends WeatherEvent {
  const RefreshWeather();
}
