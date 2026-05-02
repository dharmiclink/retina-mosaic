import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/app.dart';

void main() {
  testWidgets('capture shell renders primary call to action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NexthriaApp());

    expect(find.text('NexEye Capture Coach'), findsOneWidget);
    expect(find.text('Start Painting'), findsOneWidget);
  });
}
