import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:meteo/constants.dart';

bool _animationsDesactivees(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Aperçu de la page météo pendant le chargement.
///
/// Des blocs neutres apparaissent en cascade et respirent lentement : l'écran
/// montre la forme de ce qui arrive, sans inventer de valeur.
class WeatherLoadingView extends StatefulWidget {
  const WeatherLoadingView({this.label, super.key});

  final String? label;

  @override
  State<WeatherLoadingView> createState() => _WeatherLoadingViewState();
}

class _WeatherLoadingViewState extends State<WeatherLoadingView>
    with SingleTickerProviderStateMixin {
  static const Duration _duree = Duration(milliseconds: 2600);

  late final AnimationController _controller;
  late final List<Animation<double>> _apparitions;
  bool _demarre = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duree);
    _apparitions = List<Animation<double>>.generate(4, (index) {
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(
          index * 0.08,
          0.62 + index * 0.08,
          curve: Curves.easeInOut,
        ),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_demarre) {
      return;
    }
    _demarre = true;
    if (_animationsDesactivees(context)) {
      _controller.value = 1;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bloc(
    int index, {
    required double width,
    required double height,
    bool accent = false,
  }) {
    final double valeur = _apparitions[index].value;
    return Opacity(
      opacity: 0.18 + 0.82 * valeur,
      child: Transform.translate(
        offset: Offset(0, 6 * (1 - valeur)),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: accent
                ? couleurAccent.withValues(alpha: 0.30)
                : couleurSurface,
            borderRadius: BorderRadius.circular(height > 16 ? 8 : height / 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeyedSubtree(
                  key: const ValueKey('loading_skeleton'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bloc(0, width: 130, height: 12),
                      const Gap(26),
                      _bloc(1, width: 160, height: 54, accent: true),
                      const Gap(12),
                      _bloc(2, width: 104, height: 10),
                      const Gap(34),
                      Row(
                        children: [
                          _bloc(3, width: 84, height: 32),
                          const Gap(14),
                          _bloc(3, width: 84, height: 32),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(64),
                SizedBox(
                  width: double.infinity,
                  child: WeatherRefreshLine(
                    label: widget.label ?? 'Préparation de la météo…',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Ligne d'étape et barre fine, reprise pendant un rafraîchissement.
///
/// La barre avance et recule doucement : elle dit que quelque chose se passe
/// sans promettre de pourcentage ni de durée.
class WeatherRefreshLine extends StatefulWidget {
  const WeatherRefreshLine({required this.label, super.key});

  final String label;

  @override
  State<WeatherRefreshLine> createState() => _WeatherRefreshLineState();
}

class _WeatherRefreshLineState extends State<WeatherRefreshLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progression;
  bool _demarre = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _progression = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_demarre) {
      return;
    }
    _demarre = true;
    if (_animationsDesactivees(context)) {
      _controller.value = 1;
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: couleurTexteSecondaire,
                fontSize: 13,
              ),
            ),
            const Gap(10),
            Container(
              height: 2,
              decoration: const BoxDecoration(color: couleurBordure),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  key: const ValueKey('loading_progress'),
                  widthFactor: 0.08 + 0.84 * _progression.value,
                  child: Container(color: couleurAccent),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
