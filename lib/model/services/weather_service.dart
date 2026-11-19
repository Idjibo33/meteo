import 'package:meteo/Helpers/daily_extremes.dart';
import 'package:weather/weather.dart';

const String openWeatherApiKey = String.fromEnvironment('OPENWEATHER_API_KEY');

class WeatherService {
  WeatherService({WeatherFactory? factory})
    : wf =
          factory ??
          WeatherFactory(openWeatherApiKey, language: Language.FRENCH);

  final WeatherFactory wf;

  Future<Weather> getWeather(double lat, double lon) async {
    final Weather actuel = await wf.currentWeatherByLocation(lat, lon);
    final List<Weather> previsions;
    try {
      previsions = await wf.fiveDayForecastByLocation(lat, lon);
    } catch (_) {
      // Le forecast est un enrichissement : une panne ne doit pas priver
      // l'écran de la météo courante.
      return actuel;
    }
    return appliquerExtremasDuJour(actuel, previsions);
  }
}
