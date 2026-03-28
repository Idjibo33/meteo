import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:meta/meta.dart';
import 'package:meteo/Helpers/get_it.dart';
import 'package:meteo/Weather/Services/weather_service.dart';
import 'package:weather/weather.dart';

part 'weather_event.dart';
part 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  WeatherBloc() : super(WeatherInitial()) {
    on<FetchWeather>((event, emit) async {
      try {
        emit(WeatherInitial());
        final Weather weather = await getIt<WeatherService>().getWeather(
          event.position.latitude,
          event.position.longitude,
        );
        emit(WeatherSuccess(weather));
      } catch (e) {
        emit(WeatherFailure(e.toString()));
      }
    });
  }
}
