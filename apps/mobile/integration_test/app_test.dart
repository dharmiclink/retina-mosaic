import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/app/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('placeholder capture flow renders', (WidgetTester tester) async {
    await tester.pumpWidget(const NexthriaApp());
    await tester.pumpAndSettle();

    expect(find.text('Start Painting'), findsOneWidget);
    expect(find.text('Export Bundle'), findsOneWidget);
  });
}
