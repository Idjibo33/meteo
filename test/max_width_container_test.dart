import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/Helpers/max_width_container.dart';

Future<void> pumpContainer(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: MaxWidthContainer(
        child: Container(key: const ValueKey('content'), color: Colors.red),
      ),
    ),
  );
}

void main() {
  testWidgets('pleine largeur sur petit écran', (tester) async {
    await pumpContainer(tester, const Size(360, 640));

    expect(
      tester.getSize(find.byKey(const ValueKey('content'))).width,
      360,
    );
  });

  testWidgets('largeur bornée à 480 sur grand écran', (tester) async {
    await pumpContainer(tester, const Size(1440, 900));

    expect(
      tester.getSize(find.byKey(const ValueKey('content'))).width,
      480,
    );
  });

  testWidgets('contenu centré sur grand écran', (tester) async {
    await pumpContainer(tester, const Size(1440, 900));

    expect(
      tester.getRect(find.byKey(const ValueKey('content'))).left,
      (1440 - 480) / 2,
    );
  });
}
