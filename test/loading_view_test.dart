import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/view/widgets/loading_weather.dart';

Future<void> pumpLoading(
  WidgetTester tester, {
  bool animationsDesactivees = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: animationsDesactivees,
          ),
          child: child!,
        );
      },
      home: const Scaffold(
        body: WeatherLoadingView(label: 'Recherche de votre position…'),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('affiche un aperçu en blocs et l étape en cours', (tester) async {
    await pumpLoading(tester);

    expect(find.byKey(const ValueKey('loading_skeleton')), findsOneWidget);
    expect(find.text('Recherche de votre position…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('la barre progresse quand les animations sont autorisées', (
    tester,
  ) async {
    await pumpLoading(tester);

    final double debut = tester
        .getSize(find.byKey(const ValueKey('loading_progress')))
        .width;
    await tester.pump(const Duration(milliseconds: 900));
    final double apres = tester
        .getSize(find.byKey(const ValueKey('loading_progress')))
        .width;

    expect(apres, isNot(debut));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('la barre reste immobile si les animations sont désactivées', (
    tester,
  ) async {
    await pumpLoading(tester, animationsDesactivees: true);

    final double debut = tester
        .getSize(find.byKey(const ValueKey('loading_progress')))
        .width;
    await tester.pump(const Duration(milliseconds: 900));
    final double apres = tester
        .getSize(find.byKey(const ValueKey('loading_progress')))
        .width;

    expect(apres, debut);
    expect(find.byKey(const ValueKey('loading_skeleton')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
