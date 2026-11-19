import 'package:flutter/material.dart';
import 'package:meteo/constants.dart';

/// Barre de chargement teal qui balaie doucement une surface neutre.
///
/// Utilisée à la place des valeurs, jamais à la place des libellés : la page
/// chargée et la page en chargement ont exactement la même structure.
class WeatherShimmer extends StatefulWidget {
  const WeatherShimmer({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 4,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<WeatherShimmer> createState() => _WeatherShimmerState();
}

class _WeatherShimmerState extends State<WeatherShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progression;
  bool _demarre = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _progression = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_demarre) {
      return;
    }
    _demarre = true;
    final bool desactive =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (desactive) {
      _controller.value = 0.5;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Palette palette = context.palette;
    final Widget barre = AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            color: palette.surface,
            child: Align(
              alignment: Alignment.lerp(
                Alignment.centerLeft,
                Alignment.centerRight,
                _progression.value,
              )!,
              widthFactor: 0.4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      palette.bordure,
                      palette.accent.withValues(alpha: 0.28),
                      palette.bordure,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (widget.width == null) {
      return SizedBox(
        width: double.infinity,
        height: widget.height,
        child: barre,
      );
    }
    return SizedBox(width: widget.width, height: widget.height, child: barre);
  }
}
