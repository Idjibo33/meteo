import 'package:flutter/material.dart';
import 'package:meteo/constants.dart';

/// Les deux thèmes de l'application. La palette sémantique est portée par une
/// extension `Palette` : les widgets n'ont jamais besoin de savoir quel thème
/// est actif, ils lisent seulement `context.palette`.
ThemeData _themeDe({required Brightness brightness, required Palette palette}) {
  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: palette.accent,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'SpaceGrotesk',
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.fond,
    canvasColor: palette.fond,
    splashFactory: NoSplash.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.fond,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: palette.accent),
      titleTextStyle: TextStyle(
        color: palette.texte,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    iconTheme: IconThemeData(color: palette.accent),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: palette.texte),
      bodySmall: TextStyle(color: palette.texteSecondaire),
      titleLarge: TextStyle(color: palette.texte),
      labelLarge: TextStyle(color: palette.texte),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.fond,
      ),
    ),
    dividerTheme: DividerThemeData(color: palette.bordure, thickness: 1),
    extensions: <ThemeExtension<dynamic>>[palette],
  );
}

final ThemeData themeSombre = _themeDe(
  brightness: Brightness.dark,
  palette: paletteSombre,
);

final ThemeData themeClair = _themeDe(
  brightness: Brightness.light,
  palette: paletteClaire,
);
