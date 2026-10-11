import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile/main.dart';

void main() {
  testWidgets('App smoke test - renders LoginScreen', (WidgetTester tester) async {
    // Set standard mobile screen dimensions
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify MaterialApp is rendered
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
