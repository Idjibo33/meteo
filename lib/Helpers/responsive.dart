/// Découpage de l'écran selon la largeur disponible, jamais selon le type de
/// appareil : une fenêtre redimensionnée sur desktop doit se comporter comme
/// une tablette quand elle se rétrécit.
enum FormatEcran { compact, tablette, bureau }

const double seuilTablette = 600;
const double seuilBureau = 1000;

const double largeurCompacte = 480;
const double largeurTablette = 760;
const double largeurBureau = 1120;

FormatEcran formatSelonLargeur(double largeur) {
  if (largeur >= seuilBureau) {
    return FormatEcran.bureau;
  }
  if (largeur >= seuilTablette) {
    return FormatEcran.tablette;
  }
  return FormatEcran.compact;
}

/// Largeur maximale du contenu pour la place disponible. Le téléphone garde
/// ses 480 px historiques ; les écrans plus larges utilisent l'espace gagné.
double largeurContenuSelon(double largeur) {
  return switch (formatSelonLargeur(largeur)) {
    FormatEcran.compact => largeurCompacte,
    FormatEcran.tablette => largeurTablette,
    FormatEcran.bureau => largeurBureau,
  };
}
