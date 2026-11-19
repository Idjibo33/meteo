import 'package:flutter/material.dart';
import 'package:meteo/constants.dart';

/// Toile de fond unie : aucun dégradé ni motif, l'information porte l'écran.
class Background extends StatelessWidget {
  const Background({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: context.palette.fond);
  }
}
