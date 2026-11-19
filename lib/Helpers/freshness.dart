/// Fraîcheur d'une observation météo, calculée à partir de sa date propre.
///
/// La date affichée par l'API est l'heure de l'observation, pas l'heure courante.
/// Ces seuils évitent de laisser croire qu'une donnée ancienne est en direct.
const Duration seuilFraicheurMeteo = Duration(minutes: 10);
const Duration seuilPeremptionMeteo = Duration(minutes: 60);

enum FraicheurMeteo { aJour, ancienne, perimee }

FraicheurMeteo evaluerFraicheur(DateTime? observation, DateTime maintenant) {
  if (observation == null) {
    return FraicheurMeteo.perimee;
  }
  final Duration age = maintenant.difference(observation);
  if (age <= Duration.zero || age < seuilFraicheurMeteo) {
    return FraicheurMeteo.aJour;
  }
  if (age < seuilPeremptionMeteo) {
    return FraicheurMeteo.ancienne;
  }
  return FraicheurMeteo.perimee;
}

/// Vrai quand l'observation est absente, trop ancienne ou en retard d'un cycle.
bool observationEstPerimee(
  DateTime? observation,
  DateTime maintenant, {
  Duration seuil = seuilFraicheurMeteo,
}) {
  if (observation == null) {
    return true;
  }
  final Duration age = maintenant.difference(observation);
  if (age <= Duration.zero) {
    return false;
  }
  return age >= seuil;
}

String formatFraicheur(DateTime? observation, DateTime maintenant) {
  return switch (evaluerFraicheur(observation, maintenant)) {
    FraicheurMeteo.aJour => 'À jour',
    FraicheurMeteo.ancienne =>
      'Observé il y a ${maintenant.difference(observation!).inMinutes} min',
    FraicheurMeteo.perimee => 'Données périmées',
  };
}
