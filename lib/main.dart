import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meteo/Helpers/get_it.dart';
import 'package:meteo/model/services/favorites_store.dart';
import 'package:meteo/theme.dart';
import 'package:meteo/view/screens/weather_screen.dart';
import 'package:meteo/view/widgets/lifecycle_observer.dart';
import 'package:meteo/viewmodel/theme_cubit.dart';
import 'package:meteo/viewmodel/weather_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  await initializeDateFormatting('fr_FR');

  // Tant que runApp() n'est pas appelé, Flutter ne dessine rien : le splash
  // natif reste affiché. On attend donc la première météo avant de démarrer.
  final WeatherBloc weatherBloc = WeatherBloc()..add(const StartWeather());
  await _attendreMeteo(weatherBloc);
  runApp(MainApp(weatherBloc: weatherBloc));
}

/// Attend un état final (ou un délai de sécurité), avec une durée minimale
/// d'affichage pour éviter un clignotement quand l'API répond instantanément.
Future<void> _attendreMeteo(WeatherBloc bloc) async {
  final Future<void> attenteMinimale = Future<void>.delayed(
    const Duration(milliseconds: 600),
  );
  final bool dejaPret =
      bloc.state is WeatherSuccess || bloc.state is WeatherFailure;
  final Future<void> meteo = dejaPret
      ? Future<void>.value()
      : bloc.stream
            .firstWhere(
              (WeatherState state) =>
                  state is WeatherSuccess || state is WeatherFailure,
            )
            .timeout(const Duration(seconds: 10), onTimeout: () => bloc.state)
            .then((_) {});
  await Future.wait<void>(<Future<void>>[attenteMinimale, meteo]);
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.weatherBloc});

  final WeatherBloc weatherBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WeatherBloc>.value(
      value: weatherBloc,
      child: BlocProvider<ThemeCubit>(
        create: (_) => ThemeCubit(),
        child: WeatherLifecycleObserver(
          child: BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (BuildContext context, ThemeMode mode) {
              return MaterialApp(
                theme: themeClair,
                darkTheme: themeSombre,
                themeMode: mode,
                debugShowCheckedModeBanner: false,
                home: WeatherScreen(
                  // Les tests de widget pompent MainApp sans DI : dans ce cas
                  // l'écran retombe sur son magasin en mémoire.
                  favoritesStore: getIt.isRegistered<FavoritesStore>()
                      ? getIt<FavoritesStore>()
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
