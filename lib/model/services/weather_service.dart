import 'package:weather/weather.dart';

const String openWeatherApiKey = String.fromEnvironment('OPENWEATHER_API_KEY');

class WeatherService {
  WeatherFactory wf = WeatherFactory(
    openWeatherApiKey,
    language: Language.FRENCH,
  );
  Future<Weather> getWeather(double lat, double lon) async {
    return wf.currentWeatherByLocation(lat, lon);
  }
}
