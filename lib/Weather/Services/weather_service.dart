import 'package:weather/weather.dart';

class WeatherService {
  WeatherFactory wf = WeatherFactory(
    "0e5bb115322fc801430bc523a037a92c",
    language: Language.FRENCH,
  );
  Future<Weather> getWeather(double lat, double lon) async {
    return wf.currentWeatherByLocation(lat, lon);
  }
}
