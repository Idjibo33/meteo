import 'package:flutter/material.dart';

/// Palette volontairement limitée à trois teintes : noir, blanc et teal.
/// Les variantes de blanc ne sont que des opacités, pas de nouvelles couleurs.
const Color couleurFond = Color(0xFF000000);
const Color couleurTexte = Color(0xFFFFFFFF);
const Color couleurTexteSecondaire = Color(0x99FFFFFF);
const Color couleurSurface = Color(0x14FFFFFF);
const Color couleurBordure = Color(0x29FFFFFF);

/// Seul accent chromatique de l'application, identique dans les deux thèmes.
const Color couleurAccent = Color(0xFF26A69A);

/// Variantes claires : mêmes rôles, contrastes inversés, accent inchangé.
const Color couleurFondClair = Color(0xFFFFFFFF);
const Color couleurTexteClair = Color(0xFF111111);
const Color couleurTexteSecondaireClair = Color(0x99111111);
const Color couleurSurfaceClair = Color(0x0D111111);
const Color couleurBordureClair = Color(0x1F111111);

/// Couleurs sémantiques exposées par le thème courant.
///
/// Les widgets lisent `context.palette` plutôt que les constantes : c'est ce
/// qui permet au thème clair de repeindre l'écran sans toucher au code UI.
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.fond,
    required this.texte,
    required this.texteSecondaire,
    required this.surface,
    required this.bordure,
    required this.accent,
  });

  final Color fond;
  final Color texte;
  final Color texteSecondaire;
  final Color surface;
  final Color bordure;
  final Color accent;

  @override
  Palette copyWith({
    Color? fond,
    Color? texte,
    Color? texteSecondaire,
    Color? surface,
    Color? bordure,
    Color? accent,
  }) {
    return Palette(
      fond: fond ?? this.fond,
      texte: texte ?? this.texte,
      texteSecondaire: texteSecondaire ?? this.texteSecondaire,
      surface: surface ?? this.surface,
      bordure: bordure ?? this.bordure,
      accent: accent ?? this.accent,
    );
  }

  @override
  Palette lerp(covariant Palette? other, double t) {
    if (other == null) {
      return this;
    }
    return Palette(
      fond: Color.lerp(fond, other.fond, t)!,
      texte: Color.lerp(texte, other.texte, t)!,
      texteSecondaire: Color.lerp(texteSecondaire, other.texteSecondaire, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      bordure: Color.lerp(bordure, other.bordure, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

extension PaletteContext on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>()!;
}

const Palette paletteSombre = Palette(
  fond: couleurFond,
  texte: couleurTexte,
  texteSecondaire: couleurTexteSecondaire,
  surface: couleurSurface,
  bordure: couleurBordure,
  accent: couleurAccent,
);

const Palette paletteClaire = Palette(
  fond: couleurFondClair,
  texte: couleurTexteClair,
  texteSecondaire: couleurTexteSecondaireClair,
  surface: couleurSurfaceClair,
  bordure: couleurBordureClair,
  accent: couleurAccent,
);
