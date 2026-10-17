import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('submitting an empty form shows every validation error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    final submit = find.text('Register Profile');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Profile picture is required'), findsOneWidget);
    expect(find.text('Please provide a rating'), findsOneWidget);
    expect(find.text('Select at least 2 technologies'), findsOneWidget);
    expect(find.text('You must accept the terms to proceed'), findsOneWidget);
    expect(find.text('⚠️ Please fix the highlighted errors.'), findsOneWidget);
  });
}
