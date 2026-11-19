import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meteo/viewmodel/weather_bloc.dart';

/// Relaie les changements de cycle de vie au BLoC, sans logique métier ici.
class WeatherLifecycleObserver extends StatefulWidget {
  const WeatherLifecycleObserver({required this.child, super.key});

  final Widget child;

  @override
  State<WeatherLifecycleObserver> createState() =>
      _WeatherLifecycleObserverState();
}

class _WeatherLifecycleObserverState extends State<WeatherLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final WeatherBloc bloc = context.read<WeatherBloc>();
    switch (state) {
      case AppLifecycleState.resumed:
        bloc.add(const AppResumed());
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        bloc.add(const AppPaused());
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
