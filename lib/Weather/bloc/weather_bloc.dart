import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meta/meta.dart';
import 'package:meteo/Helpers/error_messages.dart';
import 'package:meteo/Helpers/get_it.dart';
import 'package:meteo/Weather/Services/weather_service.dart';
import 'package:weather/weather.dart';

part 'weather_event.dart';
part 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  WeatherBloc({WeatherService? weatherService})
      : _weatherService = weatherService ?? getIt<WeatherService>(),
        super(WeatherInitial()) {
    on<FetchWeather>(_onFetchWeather);
    on<RefreshWeather>(_onRefreshWeather);
  }

  final WeatherService _weatherService;
  Position? _lastPosition;

  Future<void> _onFetchWeather(
    FetchWeather event,
    Emitter<WeatherState> emit,
  ) async {
    _lastPosition = event.position;
    await _loadWeather(emit);
  }

  Future<void> _onRefreshWeather(
    RefreshWeather event,
    Emitter<WeatherState> emit,
  ) async {
    if (_lastPosition == null) {
      return;
    }
    await _loadWeather(emit);
  }

  Future<void> _loadWeather(Emitter<WeatherState> emit) async {
    emit(WeatherInitial());
    try {
      final Weather weather = await _weatherService.getWeather(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
      );
      emit(WeatherSuccess(weather));
    } catch (error) {
      emit(WeatherFailure(friendlyWeatherError(error)));
    }
  }
}
