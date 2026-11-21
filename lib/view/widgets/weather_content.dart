import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:meteo/Helpers/format_date.dart';
import 'package:meteo/Helpers/freshness.dart';
import 'package:meteo/Helpers/format_temperature.dart';
import 'package:meteo/Helpers/responsive.dart';
import 'package:meteo/Helpers/weather_condition.dart';
import 'package:meteo/constants.dart';
import 'package:meteo/model/prevision_jour.dart';
import 'package:meteo/view/widgets/daily_forecast.dart';
import 'package:meteo/view/widgets/loading_weather.dart';
import 'package:meteo/view/widgets/proprieties.dart';
import 'package:meteo/view/widgets/section_label.dart';
import 'package:meteo/viewmodel/weather_bloc.dart';
import 'package:weather/weather.dart';

/// L'unique écran météo : même structure avec ou sans données.
///
/// Pendant un chargement (initial ou rafraîchissement), les libellés, les
/// icônes et la disposition restent identiques ; seules les valeurs sont
/// remplacées par des shimmers.
class WeatherContent extends StatelessWidget {
  const WeatherContent({
    super.key,
    this.weather,
    this.miseAJour,
    this.chargement = false,
    this.etape,
    this.rapport,
  });

  final Weather? weather;
  final DateTime? miseAJour;
  final bool chargement;
  final String? etape;
  final WeatherReport? rapport;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final FormatEcran format = formatSelonLargeur(constraints.maxWidth);
        final Widget contenu = switch (format) {
          FormatEcran.compact => _contenuCompact(),
          FormatEcran.tablette => _contenuTablette(),
          FormatEcran.bureau => _contenuBureau(),
        };
        if (!chargement) {
          return contenu;
        }
        return KeyedSubtree(
          key: const ValueKey('loading_skeleton'),
          child: contenu,
        );
      },
    );
  }

  Widget _header() => _WeatherHeader(
    weather: weather,
    miseAJour: miseAJour,
    chargement: chargement,
    etape: etape,
  );

  Widget _hero({bool agrandi = false}) =>
      _WeatherHero(weather: weather, chargement: chargement, agrandi: agrandi);

  Widget _details({int colonnes = 1}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SectionLabel(label: 'Détails'),
      const Gap(8),
      Proprieties(weather: weather, chargement: chargement, colonnes: colonnes),
    ],
  );

  Widget _previsions() => DailyForecast(
    previsions: rapport?.previsions ?? const <PrevisionJour>[],
    chargement: chargement,
  );

  /// Téléphone : une seule colonne, largeur bornée à 480 px par l'écran.
  Widget _contenuCompact() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _header(),
      const Gap(24),
      _hero(),
      const Gap(24),
      _details(),
      const Gap(24),
      _previsions(),
      const Gap(24),
    ],
  );

  /// Tablette : même pile, détails répartis sur deux colonnes.
  Widget _contenuTablette() => Column(
    key: const ValueKey('mise_en_page_tablette'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _header(),
      const Gap(24),
      _hero(),
      const Gap(32),
      _details(colonnes: 2),
      const Gap(24),
      _previsions(),
      const Gap(24),
    ],
  );

  /// Desktop : le héros et les détails se partagent la largeur côte à côte.
  Widget _contenuBureau() => Column(
    key: const ValueKey('mise_en_page_bureau'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _header(),
      const Gap(32),
      Row(
        key: const ValueKey('duo_hero_details'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _hero(agrandi: true)),
          const Gap(48),
          Expanded(child: _details()),
        ],
      ),
      const Gap(24),
      _previsions(),
      const Gap(24),
    ],
  );
}

class _WeatherHeader extends StatelessWidget {
  const _WeatherHeader({
    required this.weather,
    required this.chargement,
    required this.etape,
    this.miseAJour,
  });

  final Weather? weather;
  final bool chargement;
  final String? etape;
  final DateTime? miseAJour;

  @override
  Widget build(BuildContext context) {
    final Palette palette = context.palette;
    final bool shimmer = chargement || weather == null;
    final DateTime maintenant = DateTime.now();
    final FraicheurMeteo? fraicheur = shimmer
        ? null
        : evaluerFraicheur(weather!.date, maintenant);
    final bool aJour = fraicheur == FraicheurMeteo.aJour;

    if (shimmer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            etape ?? 'Récupération de la météo…',
            style: TextStyle(color: palette.texteSecondaire, fontSize: 12),
          ),
          const Gap(10),
          const WeatherShimmer(height: 2, borderRadius: 2),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: aJour ? palette.accent : palette.fond,
                border: aJour
                    ? null
                    : Border.all(color: palette.texteSecondaire, width: 1),
                shape: BoxShape.circle,
              ),
            ),
            const Gap(8),
            Expanded(
              child: Text(
                '${formatFraicheur(weather!.date, maintenant)} ∙ '
                'Observé le ${formatDateAvecFuseau(weather!.date, weather!.toJson()?['timezone'])}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: palette.texteSecondaire, fontSize: 12),
              ),
            ),
            // Le pull-to-refresh est le seul geste visible. Cette cible
            // invisible garde une action « Actualiser » aux lecteurs d'écran.
            Semantics(
              button: true,
              label: 'Actualiser',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    context.read<WeatherBloc>().add(const RefreshWeather()),
                child: const SizedBox(width: 48, height: 48),
              ),
            ),
          ],
        ),
        // L'heure d'observation ne bouge qu'au rythme de l'API (≈10 min).
        // L'heure de mise à jour prouve que le pull a bien déclenché un appel.
        if (miseAJour != null) ...[
          const Gap(2),
          Text(
            'Actualisé à ${formatHour(miseAJour!)}',
            style: TextStyle(color: palette.texteSecondaire, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class _WeatherHero extends StatelessWidget {
  const _WeatherHero({
    required this.weather,
    required this.chargement,
    this.agrandi = false,
  });

  final Weather? weather;
  final bool chargement;
  final bool agrandi;

  @override
  Widget build(BuildContext context) {
    final Palette palette = context.palette;
    final bool shimmer = chargement || weather == null;
    final double tailleIllustration = agrandi ? 180 : 140;
    final double tailleChiffre = agrandi ? 104 : 84;

    return Column(
      children: [
        if (shimmer)
          WeatherShimmer(
            width: tailleIllustration,
            height: tailleIllustration,
            borderRadius: tailleIllustration / 2,
          )
        else
          Image.asset(
            getWeatherDescriptionImage(weather),
            width: tailleIllustration,
            height: tailleIllustration,
            color: palette.accent,
            colorBlendMode: BlendMode.srcIn,
            excludeFromSemantics: true,
          ),
        const Gap(8),
        if (shimmer)
          const WeatherShimmer(width: 110, height: 64)
        else
          Text(
            formatTemperature(weather!.temperature?.celsius),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.texte,
              fontSize: tailleChiffre,
              height: 1,
              fontWeight: FontWeight.w200,
              letterSpacing: -2,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        const Gap(8),
        SizedBox(
          height: 18,
          child: shimmer
              ? const WeatherShimmer(width: 104, height: 12)
              : Text(
                  weather!.weatherDescription ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
        const Gap(6),
        // Google Weather met le ressenti juste sous la température : on reprend
        // cette hiérarchie plutôt que de le laisser dans la liste des détails.
        SizedBox(
          height: 18,
          child: shimmer
              ? const WeatherShimmer(width: 92, height: 13)
              : Text(
                  'Ressenti ${formatTemperature(weather!.tempFeelsLike?.celsius)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.texteSecondaire,
                    fontSize: 13,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
        ),
        const Gap(10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_upward_rounded, size: 14, color: palette.accent),
            const Gap(4),
            if (shimmer)
              const WeatherShimmer(width: 40, height: 11)
            else
              Text(
                formatTemperature(weather!.tempMax?.celsius),
                style: TextStyle(
                  color: palette.texteSecondaire,
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            const Gap(20),
            Icon(Icons.arrow_downward_rounded, size: 14, color: palette.accent),
            const Gap(4),
            if (shimmer)
              const WeatherShimmer(width: 40, height: 11)
            else
              Text(
                formatTemperature(weather!.tempMin?.celsius),
                style: TextStyle(
                  color: palette.texteSecondaire,
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
