import 'package:flutter_test/flutter_test.dart';

import 'package:act17_mad/main.dart';

void main() {
  testWidgets('Firebase Messaging app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MessagingTutorial());

    expect(find.text('Firebase Messaging'), findsOneWidget);
    expect(find.text('Firebase Cloud Messaging'), findsOneWidget);
  });
}
