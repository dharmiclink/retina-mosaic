import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexthria_ui/nexthria_ui.dart';

void main() {
  testWidgets('guidance banner renders instruction', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GuidanceBanner(
            instruction: 'Tilt device 5° left',
            confidence: 0.92,
          ),
        ),
      ),
    );

    expect(find.text('Tilt device 5° left'), findsOneWidget);
    expect(find.text('92%'), findsOneWidget);
  });
}
