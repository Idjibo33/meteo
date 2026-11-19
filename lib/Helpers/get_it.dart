import 'package:get_it/get_it.dart';
import 'package:meteo/model/services/geolocator_service.dart';
import 'package:meteo/model/services/weather_service.dart';

final getIt = GetIt.instance;
void configureDependencies() {
  getIt.registerSingleton<WeatherService>(WeatherService());
  getIt.registerSingleton<GeolocatorService>(GeolocatorService());
}
