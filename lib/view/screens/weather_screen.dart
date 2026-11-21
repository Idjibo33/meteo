import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:meteo/Helpers/max_width_container.dart';
import 'package:meteo/Helpers/responsive.dart';
import 'package:meteo/constants.dart';
import 'package:meteo/model/failures.dart';
import 'package:meteo/model/prevision_jour.dart';
import 'package:meteo/model/services/favorites_store.dart';
import 'package:meteo/view/widgets/background.dart';
import 'package:meteo/view/widgets/loading_weather.dart';
import 'package:meteo/view/widgets/section_label.dart';
import 'package:meteo/view/widgets/weather_content.dart';
import 'package:meteo/viewmodel/theme_cubit.dart';
import 'package:meteo/viewmodel/weather_bloc.dart';
import 'package:weather/weather.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key, this.favoritesStore});

  /// Injecté par l'application ; les tests peuvent fournir un magasin en
  /// mémoire pour vérifier la persistance sans toucher au stockage natif.
  final FavoritesStore? favoritesStore;

  static final FavoritesStore _storeReserve = InMemoryFavoritesStore();
  FavoritesStore get _store => favoritesStore ?? _storeReserve;

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
                      case WeatherLoading(:final derniereMeteo, :final rapport):
                        return _contentRafraichissable(
                          context,
                          weather: derniereMeteo,
                          rapport: rapport,
                          chargement: true,
                          etape: 'Récupération de la météo…',
                        );
                      case WeatherSuccess(
                        :final weather,
                        :final miseAJour,
                        :final rapport,
                      ):
                        return _contentRafraichissable(
                          context,
                          weather: weather,
                          rapport: rapport,
                          miseAJour: miseAJour,
                        );
                      case WeatherFailure(:final reason, :final ville):
                        return Center(
                          child: SingleChildScrollView(
                            child: _WeatherFailureView(
                              reason: reason,
                              ville: ville,
                            ),
                          ),
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
    WeatherReport? rapport,
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
            actions: <Widget>[
              _RechercheVilleButton(favoritesStore: _store),
              const _ThemeToggle(),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: WeatherContent(
                weather: weather,
                rapport: rapport,
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

class _WeatherFailureView extends StatefulWidget {
  const _WeatherFailureView({required this.reason, this.ville});

  final WeatherFailureReason reason;

  /// Renseigné quand l'échec vient d'une recherche par ville.
  final String? ville;

  @override
  State<_WeatherFailureView> createState() => _WeatherFailureViewState();
}

class _WeatherFailureViewState extends State<_WeatherFailureView> {
  final TextEditingController _villeController = TextEditingController();

  @override
  void dispose() {
    _villeController.dispose();
    super.dispose();
  }

  /// Une position refusée n'est pas réparable par un simple « Réessayer » :
  /// on propose toujours la saisie d'une ville dans ce cas.
  bool get _afficherRecherche =>
      widget.reason.requiresRelocation || widget.ville != null;

  void _rechercher(BuildContext context) {
    final String ville = _villeController.text.trim();
    if (ville.isNotEmpty) {
      context.read<WeatherBloc>().add(SearchCity(ville));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Palette palette = context.palette;
    final OutlineInputBorder bordure = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: palette.bordure),
    );
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
            widget.reason.requiresRelocation
                ? Icons.location_off_outlined
                : Icons.cloud_off_outlined,
            size: 40,
            color: palette.accent,
          ),
          const Gap(16),
          Text(
            widget.reason.message,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.texte, fontSize: 15),
          ),
          const Gap(20),
          if (_afficherRecherche) ...[
            TextField(
              key: const ValueKey('recherche_ville'),
              controller: _villeController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _rechercher(context),
              decoration: InputDecoration(
                labelText: 'Ville (ex. Paris)',
                prefixIcon: Icon(Icons.search, color: palette.accent),
                border: bordure,
                enabledBorder: bordure,
                focusedBorder: bordure.copyWith(
                  borderSide: BorderSide(color: palette.accent),
                ),
              ),
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.fond,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _rechercher(context),
                child: const Text('Voir la météo'),
              ),
            ),
            if (widget.reason.requiresRelocation) ...[
              const Gap(4),
              TextButton(
                onPressed: () =>
                    context.read<WeatherBloc>().add(const RetryLocation()),
                child: const Text('Réessayer la localisation'),
              ),
            ],
          ] else
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.fond,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () =>
                  context.read<WeatherBloc>().add(const RefreshWeather()),
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

/// Ouvre la recherche de ville et la gestion des favoris depuis l'en-tête.
class _RechercheVilleButton extends StatelessWidget {
  const _RechercheVilleButton({required this.favoritesStore});

  final FavoritesStore favoritesStore;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Rechercher une ville',
      color: context.palette.accent,
      icon: const Icon(Icons.search),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (BuildContext context) =>
            _RechercheVilleDialog(favoritesStore: favoritesStore),
      ),
    );
  }
}

class _RechercheVilleDialog extends StatefulWidget {
  const _RechercheVilleDialog({required this.favoritesStore});

  final FavoritesStore favoritesStore;

  @override
  State<_RechercheVilleDialog> createState() => _RechercheVilleDialogState();
}

class _RechercheVilleDialogState extends State<_RechercheVilleDialog> {
  final TextEditingController _controller = TextEditingController();
  List<String> _favoris = const <String>[];

  @override
  void initState() {
    super.initState();
    _chargerFavoris();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _chargerFavoris() async {
    final List<String> favoris = await widget.favoritesStore.lire();
    if (!mounted) {
      return;
    }
    setState(() => _favoris = favoris);
  }

  /// La ville affichée est le lieu courant du bloc, qu'il vienne du GPS ou
  /// d'une recherche précédente.
  String _villeCourante() {
    final WeatherState etat = context.read<WeatherBloc>().state;
    return switch (etat) {
      WeatherSuccess(:final ville, :final weather) =>
        (ville ?? weather.areaName ?? '').trim(),
      WeatherFailure(:final ville) => (ville ?? '').trim(),
      _ => '',
    };
  }

  bool _estFavori(String ville) => _favoris.any(
    (String favori) => favori.toLowerCase() == ville.toLowerCase(),
  );

  void _ouvrirVille(String ville) {
    final String nom = ville.trim();
    if (nom.isEmpty) {
      return;
    }
    context.read<WeatherBloc>().add(SearchCity(nom));
    Navigator.of(context).pop();
  }

  Future<void> _basculeFavori() async {
    final String ville = _villeCourante();
    if (ville.isEmpty) {
      return;
    }
    if (_estFavori(ville)) {
      await widget.favoritesStore.retirer(ville);
    } else {
      await widget.favoritesStore.ajouter(ville);
    }
    await _chargerFavoris();
  }

  @override
  Widget build(BuildContext context) {
    final Palette palette = context.palette;
    final String villeCourante = _villeCourante();
    final OutlineInputBorder bordure = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: palette.bordure),
    );

    return AlertDialog(
      backgroundColor: palette.fond,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.bordure),
      ),
      title: Row(
        children: [
          Icon(Icons.search, color: palette.accent, size: 20),
          const Gap(8),
          Text(
            'Rechercher une ville',
            style: TextStyle(color: palette.texte, fontSize: 18),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const ValueKey('recherche_ville_header'),
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: _ouvrirVille,
                decoration: InputDecoration(
                  labelText: 'Ville (ex. Paris)',
                  prefixIcon: Icon(Icons.place_outlined, color: palette.accent),
                  border: bordure,
                  enabledBorder: bordure,
                  focusedBorder: bordure.copyWith(
                    borderSide: BorderSide(color: palette.accent),
                  ),
                ),
              ),
              const Gap(16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const Gap(8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.fond,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _ouvrirVille(_controller.text),
                    child: const Text('Rechercher'),
                  ),
                ],
              ),
              const Gap(20),
              const SectionLabel(label: 'Favoris'),
              const Gap(8),
              if (_favoris.isEmpty)
                Text(
                  'Aucun favori pour le moment.',
                  style: TextStyle(
                    color: palette.texteSecondaire,
                    fontSize: 13,
                  ),
                )
              else
                ..._favoris.map(
                  (String ville) => ListTile(
                    key: ValueKey('favori_$ville'),
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.star_outline,
                      color: palette.accent,
                      size: 20,
                    ),
                    title: Text(
                      ville,
                      style: TextStyle(color: palette.texte, fontSize: 14),
                    ),
                    onTap: () => _ouvrirVille(ville),
                    trailing: IconButton(
                      key: ValueKey('retirer_$ville'),
                      tooltip: 'Retirer $ville des favoris',
                      color: palette.texteSecondaire,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () async {
                        await widget.favoritesStore.retirer(ville);
                        await _chargerFavoris();
                      },
                    ),
                  ),
                ),
              if (villeCourante.isNotEmpty) ...[
                const Gap(12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ville actuelle : $villeCourante',
                        style: TextStyle(
                          color: palette.texteSecondaire,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('bascule_favori'),
                      tooltip: _estFavori(villeCourante)
                          ? 'Retirer des favoris'
                          : 'Ajouter aux favoris',
                      color: palette.accent,
                      icon: Icon(
                        _estFavori(villeCourante)
                            ? Icons.star
                            : Icons.star_border,
                      ),
                      onPressed: _basculeFavori,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
