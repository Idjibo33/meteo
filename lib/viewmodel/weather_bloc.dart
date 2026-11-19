import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meta/meta.dart';
import 'package:meteo/Helpers/freshness.dart';
import 'package:meteo/Helpers/get_it.dart';
import 'package:meteo/model/failures.dart';
import 'package:meteo/model/services/geolocator_service.dart';
import 'package:meteo/model/services/weather_service.dart';
import 'package:weather/weather.dart';

part 'weather_event.dart';
part 'weather_state.dart';

/// Source des ticks de rafraîchissement. Injectable pour des tests déterministes.
typedef RefreshTicks = Stream<void> Function(Duration interval);

Stream<void> _refreshTicksPeriodiques(Duration interval) =>
    Stream<void>.periodic(interval);

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  WeatherBloc({
    WeatherService? weatherService,
    GeolocatorService? geolocatorService,
    Duration refreshInterval = seuilFraicheurMeteo,
    RefreshTicks? refreshTicks,
    DateTime Function()? now,
  }) : _weatherService = weatherService ?? getIt<WeatherService>(),
       _injectedGeolocator = geolocatorService,
       _refreshInterval = refreshInterval,
       _refreshTicks = refreshTicks ?? _refreshTicksPeriodiques,
       _now = now ?? DateTime.now,
       super(const WeatherInitial()) {
    on<StartWeather>(_onLocate);
    on<RetryLocation>(_onLocate);
    on<FetchWeather>(_onFetchWeather);
    on<RefreshWeather>(_onRefreshWeather);
    on<AppResumed>(_onAppResumed);
    on<AppPaused>(_onAppPaused);
  }

  final WeatherService _weatherService;
  final GeolocatorService? _injectedGeolocator;
  final Duration _refreshInterval;
  final RefreshTicks _refreshTicks;
  final DateTime Function() _now;

  StreamSubscription<void>? _refreshSubscription;
  bool _enArrierePlan = false;

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
      WeatherSuccess(:final position) => position,
      WeatherFailure(:final position) => position,
      _ => null,
    };
    if (position == null) {
      return;
    }
    await _loadWeather(emit, position);
  }

  Future<void> _onAppResumed(
    AppResumed event,
    Emitter<WeatherState> emit,
  ) async {
    _enArrierePlan = false;
    _startRefreshTicks();
    if (state is WeatherLoading) {
      return;
    }
    final Position? position = switch (state) {
      WeatherSuccess(:final position) => position,
      WeatherFailure(:final position) => position,
      _ => null,
    };
    if (position == null) {
      return;
    }
    final DateTime? observation = switch (state) {
      WeatherSuccess(:final weather) => weather.date,
      _ => null,
    };
    if (observation != null &&
        !observationEstPerimee(observation, _now(), seuil: _refreshInterval)) {
      return;
    }
    await _loadWeather(emit, position);
  }

  Future<void> _onAppPaused(AppPaused event, Emitter<WeatherState> emit) async {
    _enArrierePlan = true;
    await _stopRefreshTicks();
  }

  Future<void> _loadWeather(
    Emitter<WeatherState> emit,
    Position position,
  ) async {
    final Weather? derniereMeteo = switch (state) {
      WeatherSuccess(:final weather) => weather,
      _ => null,
    };
    emit(WeatherLoading(position: position, derniereMeteo: derniereMeteo));
    try {
      final Weather weather = await _weatherService.getWeather(
        position.latitude,
        position.longitude,
      );
      emit(
        WeatherSuccess(position: position, weather: weather, miseAJour: _now()),
      );
    } catch (error) {
      emit(
        WeatherFailure(position: position, reason: classifyWeatherError(error)),
      );
    }
    _startRefreshTicks();
  }

  void _startRefreshTicks() {
    if (_enArrierePlan || _refreshSubscription != null) {
      return;
    }
    _refreshSubscription = _refreshTicks(_refreshInterval).listen((_) {
      if (!isClosed) {
        add(const RefreshWeather());
      }
    });
  }

  Future<void> _stopRefreshTicks() async {
    // On détache d'abord : une reprise survenant pendant l'annulation doit
    // pouvoir installer un nouvel abonnement sans être écrasée ensuite.
    final StreamSubscription<void>? subscription = _refreshSubscription;
    _refreshSubscription = null;
    await subscription?.cancel();
  }

  @override
  Future<void> close() async {
    await _stopRefreshTicks();
    return super.close();
  }
}
