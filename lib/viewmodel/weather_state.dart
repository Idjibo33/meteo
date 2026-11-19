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
  const WeatherLoading({required this.position});

  final Position position;

  @override
  List<Object?> get props => [position];
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
