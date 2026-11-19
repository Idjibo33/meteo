part of 'weather_bloc.dart';

@immutable
sealed class WeatherState extends Equatable {
  const WeatherState();
  @override
  List<Object?> get props => [];
}

final class WeatherInitial extends WeatherState {
  const WeatherInitial();
}

final class WeatherLocating extends WeatherState {
  const WeatherLocating();
}

final class WeatherLoading extends WeatherState {
  const WeatherLoading({required this.position, this.derniereMeteo});

  final Position position;

  /// Météo déjà affichée avant un rafraîchissement : l'UI peut la garder
  /// visible pendant le nouvel appel au lieu de replacer l'écran entier.
  final Weather? derniereMeteo;

  @override
  List<Object?> get props => [position, derniereMeteo];
}

final class WeatherSuccess extends WeatherState {
  const WeatherSuccess({required this.position, required this.weather});

  final Position position;
  final Weather weather;

  @override
  List<Object?> get props => [position, weather];
}

final class WeatherFailure extends WeatherState {
  const WeatherFailure({required this.position, required this.reason});

  /// Null quand la localisation elle-même a échoué.
  final Position? position;
  final WeatherFailureReason reason;

  String get message => reason.message;
  bool get requiresRelocation => reason.requiresRelocation;

  @override
  List<Object?> get props => [position, reason];
}
