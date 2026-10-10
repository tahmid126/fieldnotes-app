import 'package:flutter_test/flutter_test.dart';
import 'package:fieldnotes_app/main.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FieldNotesApp());
    expect(find.byType(FieldNotesApp), findsOneWidget);
  });
}
