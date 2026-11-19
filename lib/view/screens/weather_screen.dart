import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:meteo/Helpers/max_width_container.dart';
import 'package:meteo/Helpers/responsive.dart';
import 'package:meteo/constants.dart';
import 'package:meteo/model/failures.dart';
import 'package:meteo/view/widgets/background.dart';
import 'package:meteo/view/widgets/loading_weather.dart';
import 'package:meteo/view/widgets/weather_content.dart';
import 'package:meteo/viewmodel/theme_cubit.dart';
import 'package:meteo/viewmodel/weather_bloc.dart';
import 'package:weather/weather.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.fond,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Background(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => MaxWidthContainer(
                maxWidth: largeurContenuSelon(constraints.maxWidth),
                child: BlocBuilder<WeatherBloc, WeatherState>(
                  builder: (context, state) {
                    switch (state) {
                      case WeatherInitial():
                        return _contentRafraichissable(
                          context,
                          chargement: true,
                          etape: 'Préparation de la météo…',
                        );
                      case WeatherLocating():
                        return _contentRafraichissable(
                          context,
                          chargement: true,
                          etape: 'Recherche de votre position…',
                        );
                      case WeatherLoading(:final derniereMeteo):
                        return _contentRafraichissable(
                          context,
                          weather: derniereMeteo,
                          chargement: true,
                          etape: 'Récupération de la météo…',
                        );
                      case WeatherSuccess(:final weather, :final miseAJour):
                        return _contentRafraichissable(
                          context,
                          weather: weather,
                          miseAJour: miseAJour,
                        );
                      case WeatherFailure(:final reason):
                        return Center(
                          child: _WeatherFailureView(reason: reason),
                        );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentRafraichissable(
    BuildContext context, {
    Weather? weather,
    DateTime? miseAJour,
    bool chargement = false,
    String? etape,
  }) {
    final Palette palette = context.palette;
    return RefreshIndicator(
      color: palette.accent,
      backgroundColor: palette.fond,
      onRefresh: () => _rafraichir(context),
      child: CustomScrollView(
        key: const ValueKey('weather_content'),
        // La liste rebondit souplement aux deux extrémités, y compris sous Android.
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            automaticallyImplyLeading: false,
            toolbarHeight: 64,
            backgroundColor: palette.fond,
            surfaceTintColor: palette.fond,
            shadowColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: _RegionTitle(weather: weather, chargement: chargement),
            // SliverAppBar n'a pas de `trailing` : `actions` en est l'équivalent,
            // à droite du titre, comme le trailing d'une AppBar classique.
            actions: const <Widget>[_ThemeToggle()],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: WeatherContent(
                weather: weather,
                miseAJour: miseAJour,
                chargement: chargement,
                etape: etape,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rafraichir(BuildContext context) async {
    final WeatherBloc bloc = context.read<WeatherBloc>();
    // Le bloc ignore un RefreshWeather pendant un chargement : ne pas attendre
    // un état final qui n'arrivera pas (un tick a déjà lancé l'appel).
    if (bloc.state is WeatherLoading) {
      return;
    }
    final Future<WeatherState> fin = bloc.stream.firstWhere(
      (WeatherState state) =>
          state is WeatherSuccess || state is WeatherFailure,
    );
    bloc.add(const RefreshWeather());
    await fin;
  }
}

/// Titre de l'AppBar : la région, visible en permanence grâce au sliver épinglé.
class _RegionTitle extends StatelessWidget {
  const _RegionTitle({required this.weather, required this.chargement});

  final Weather? weather;
  final bool chargement;

  @override
  Widget build(BuildContext context) {
    final Palette palette = context.palette;
    final bool shimmer = chargement || weather == null;
    return Row(
      children: [
        Icon(Icons.place_outlined, size: 18, color: palette.accent),
        const Gap(8),
        Expanded(
          child: shimmer
              ? const WeatherShimmer(width: 130, height: 16)
              : Text(
                  '${weather!.areaName} ${weather!.country}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.texte,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}

class _WeatherFailureView extends StatelessWidget {
  const _WeatherFailureView({required this.reason});

  final WeatherFailureReason reason;

  @override
  Widget build(BuildContext context) {
    final Palette palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.bordure),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            reason.requiresRelocation
                ? Icons.location_off_outlined
                : Icons.cloud_off_outlined,
            size: 40,
            color: palette.accent,
          ),
          const Gap(16),
          Text(
            reason.message,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.texte, fontSize: 15),
          ),
          const Gap(20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.fond,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => context.read<WeatherBloc>().add(
              reason.requiresRelocation
                  ? const RetryLocation()
                  : const RefreshWeather(),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

/// Bascule de thème dans le trailing de l'AppBar : soleil en mode sombre,
/// lune en mode clair, pour toujours indiquer la destination du clic.
class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final ThemeMode mode = context.watch<ThemeCubit>().state;
    return IconButton(
      tooltip: 'Changer de thème',
      color: context.palette.accent,
      icon: Icon(
        mode == ThemeMode.dark
            ? Icons.wb_sunny_outlined
            : Icons.dark_mode_outlined,
      ),
      onPressed: () => context.read<ThemeCubit>().basculer(),
    );
  }
}
