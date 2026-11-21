part of 'weather_bloc.dart';

@immutable
sealed class WeatherState extends Equatable {
  const WeatherState();
  @override
  List<Object?> get props => [];
}

final class WeatherInitial extends WeatherState {
  const WeatherInitial();
}

final class WeatherLocating extends WeatherState {
  const WeatherLocating();
}

/// Les états portent le lieu demandé : position GPS ou ville saisie à la main.
/// Exactement l'un des deux est renseigné, ce qui permet au rafraîchissement
/// de réutiliser le bon mode sans champ caché dans le bloc.
final class WeatherLoading extends WeatherState {
  const WeatherLoading({this.position, this.ville, this.derniereMeteo})
    : assert((position == null) != (ville == null));

  final Position? position;
  final String? ville;

  /// Météo déjà affichée avant un rafraîchissement : l'UI peut la garder
  /// visible pendant le nouvel appel au lieu de replacer l'écran entier.
  final Weather? derniereMeteo;

  @override
  List<Object?> get props => [position, ville, derniereMeteo];
}

final class WeatherSuccess extends WeatherState {
  const WeatherSuccess({
    this.position,
    this.ville,
    required this.weather,
    this.miseAJour,
  }) : assert((position == null) != (ville == null));

  final Position? position;
  final String? ville;
  final Weather weather;

  /// Heure locale du dernier appel réussi, distincte de l'heure d'observation
  /// renvoyée par l'API. Elle rend le pull-to-refresh visiblement effectif
  /// même quand l'observation n'a pas encore changé.
  final DateTime? miseAJour;

  @override
  List<Object?> get props => [position, ville, weather, miseAJour];
}

final class WeatherFailure extends WeatherState {
  const WeatherFailure({this.position, this.ville, required this.reason})
    : assert(position == null || ville == null);

  /// Position géolocalisée, absente quand la localisation a échoué.
  final Position? position;

  /// Ville recherchée, renseignée quand la position n'est pas disponible.
  final String? ville;
  final WeatherFailureReason reason;

  String get message => reason.message;
  bool get requiresRelocation => reason.requiresRelocation;

  @override
  List<Object?> get props => [position, ville, reason];
}
