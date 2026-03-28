part of 'weather_bloc.dart';

@immutable
sealed class WeatherState extends Equatable {
  const WeatherState();
  @override
  List<Object?> get props => [];
}

final class WeatherInitial extends WeatherState {}

final class WeatherFailure extends WeatherState {
  final String message;
  const WeatherFailure(this.message);
  @override
  // TODO: implement props
  List<Object?> get props => [message];
}

final class WeatherSuccess extends WeatherState {
  final Weather weather;
  const WeatherSuccess(this.weather);
  @override
  // TODO: implement props
  List<Object?> get props => [weather];
}
