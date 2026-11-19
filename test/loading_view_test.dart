import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/theme.dart';
import 'package:meteo/view/widgets/loading_weather.dart';
import 'package:meteo/view/widgets/weather_content.dart';

Future<void> pumpShimmer(
  WidgetTester tester, {
  bool animationsDesactivees = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: themeSombre,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: animationsDesactivees),
          child: child!,
        );
      },
      home: const Scaffold(body: WeatherShimmer(width: 100, height: 14)),
    ),
  );
  await tester.pump();
}

AlignmentGeometry _alignementDuBalayage(WidgetTester tester) {
  return tester
      .widget<Align>(
        find.descendant(
          of: find.byType(WeatherShimmer),
          matching: find.byType(Align),
        ),
      )
      .alignment;
}

void main() {
  testWidgets(
    'le shimmer balaye la valeur quand les animations sont autorisées',
    (tester) async {
      await pumpShimmer(tester);

      final AlignmentGeometry debut = _alignementDuBalayage(tester);
      await tester.pump(const Duration(milliseconds: 500));
      final AlignmentGeometry apres = _alignementDuBalayage(tester);

      expect(apres, isNot(debut));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('le shimmer reste fixe si les animations sont désactivées', (
    tester,
  ) async {
    await pumpShimmer(tester, animationsDesactivees: true);

    final AlignmentGeometry debut = _alignementDuBalayage(tester);
    await tester.pump(const Duration(milliseconds: 500));
    final AlignmentGeometry apres = _alignementDuBalayage(tester);

    expect(apres, debut);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('le chargement garde l écran des résultats avec des shimmers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: themeSombre,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: WeatherContent(
              chargement: true,
              etape: 'Préparation de la météo…',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('loading_skeleton')), findsOneWidget);
    expect(find.text('Préparation de la météo…'), findsOneWidget);
    expect(find.text('DÉTAILS'), findsOneWidget);
    expect(find.text('Vent'), findsOneWidget);
    expect(find.text('Coucher du soleil'), findsOneWidget);
    expect(find.byType(WeatherShimmer), findsWidgets);
    expect(find.text('18 °C'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
