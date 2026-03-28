import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:meteo/constants.dart';

class Background extends StatelessWidget {
  const Background({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: AlignmentGeometry.topLeft,
          child: Container(height: 500, width: 200, color: couleurBleue),
        ),
        Align(
          alignment: AlignmentGeometry.topRight,
          child: Container(height: 500, width: 200, color: couleurBleue),
        ),

        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          child: Container(color: Colors.transparent),
        ),
      ],
    );
  }
}
