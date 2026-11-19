import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meta/meta.dart';
import 'package:meteo/Helpers/get_it.dart';
import 'package:meteo/Weather/Services/geolocator_service.dart';
import 'package:meteo/Weather/Services/weather_service.dart';
import 'package:meteo/Weather/failures.dart';
import 'package:weather/weather.dart';

part 'weather_event.dart';
part 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  WeatherBloc({
    WeatherService? weatherService,
    GeolocatorService? geolocatorService,
  }) : _weatherService = weatherService ?? getIt<WeatherService>(),
       _injectedGeolocator = geolocatorService,
       super(const WeatherInitial()) {
    on<StartWeather>(_onLocate);
    on<RetryLocation>(_onLocate);
    on<FetchWeather>(_onFetchWeather);
    on<RefreshWeather>(_onRefreshWeather);
  }

  final WeatherService _weatherService;
  final GeolocatorService? _injectedGeolocator;

  GeolocatorService get _geolocator =>
      _injectedGeolocator ?? getIt<GeolocatorService>();

  Future<void> _onLocate(WeatherEvent event, Emitter<WeatherState> emit) async {
    emit(const WeatherLocating());
    try {
      final Position position = await _geolocator.getPosition();
      await _loadWeather(emit, position);
    } catch (error) {
      emit(
        WeatherFailure(position: null, reason: classifyLocationError(error)),
      );
    }
  }

  Future<void> _onFetchWeather(
    FetchWeather event,
    Emitter<WeatherState> emit,
  ) async {
    await _loadWeather(emit, event.position);
  }

  Future<void> _onRefreshWeather(
    RefreshWeather event,
    Emitter<WeatherState> emit,
  ) async {
    final Position? position = switch (state) {
      WeatherLoading(:final position) => position,
      WeatherSuccess(:final position) => position,
      WeatherFailure(:final position) => position,
      _ => null,
    };
    if (position == null) {
      return;
    }
    await _loadWeather(emit, position);
  }

  Future<void> _loadWeather(
    Emitter<WeatherState> emit,
    Position position,
  ) async {
    emit(WeatherLoading(position: position));
    try {
      final Weather weather = await _weatherService.getWeather(
        position.latitude,
        position.longitude,
      );
      emit(WeatherSuccess(position: position, weather: weather));
    } catch (error) {
      emit(
        WeatherFailure(position: position, reason: classifyWeatherError(error)),
      );
    }
  }
}
