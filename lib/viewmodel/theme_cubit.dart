import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// État du thème. Le choix n'est pas persisté entre les lancements : aucune
/// dépendance de stockage n'est ajoutée à l'application.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.dark);

  void basculer() {
    emit(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
