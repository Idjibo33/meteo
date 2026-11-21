import 'package:meteo/Helpers/daily_extremes.dart';
import 'package:meteo/Helpers/daily_forecast.dart';
import 'package:meteo/model/prevision_jour.dart';
import 'package:weather/weather.dart';

const String openWeatherApiKey = String.fromEnvironment('OPENWEATHER_API_KEY');

class WeatherService {
  WeatherService({WeatherFactory? factory})
    : wf =
          factory ??
          WeatherFactory(openWeatherApiKey, language: Language.FRENCH);

  final WeatherFactory wf;

  /// Météo courante seule : conserve le comportement historique des appelants.
  Future<Weather> getWeather(double lat, double lon) async =>
      (await getReport(lat, lon)).actuel;

  /// Repli quand la position n'est pas disponible (permission refusée sur le
  /// web, service désactivé, plateforme sans géolocalisation comme Linux).
  /// Utilise la même clé OpenWeatherMap, sans nouvelle dépendance réseau.
  Future<Weather> getWeatherByCity(String ville) async =>
      (await getReportByCity(ville)).actuel;

  /// Observation courante et prévisions des jours à venir.
  Future<WeatherReport> getReport(double lat, double lon) async {
    final Weather actuel = await wf.currentWeatherByLocation(lat, lon);
    final List<Weather> previsions = await _recupererPrevisions(
      () => wf.fiveDayForecastByLocation(lat, lon),
    );
    return _construireRapport(actuel, previsions);
  }

  Future<WeatherReport> getReportByCity(String ville) async {
    final Weather actuel = await wf.currentWeatherByCityName(ville);
    final List<Weather> previsions = await _recupererPrevisions(
      () => wf.fiveDayForecastByCityName(ville),
    );
    return _construireRapport(actuel, previsions);
  }

  /// Le forecast est un enrichissement : une panne ne doit pas priver l'écran
  /// de la météo courante.
  Future<List<Weather>> _recupererPrevisions(
    Future<List<Weather>> Function() source,
  ) async {
    try {
      return await source();
    } catch (_) {
      return const <Weather>[];
    }
  }

  WeatherReport _construireRapport(Weather actuel, List<Weather> previsions) {
    final Weather avecExtremas = appliquerExtremasDuJour(actuel, previsions);
    final int? fuseau = (actuel.toJson()?['timezone'] as num?)?.toInt();
    final List<PrevisionJour> jours = grouperPrevisionsParJour(
      previsions,
      reference: actuel.date ?? DateTime.now(),
      fuseau: fuseau,
    );
    return WeatherReport(actuel: avecExtremas, previsions: jours);
  }
}
