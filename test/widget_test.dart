import 'package:flutter_test/flutter_test.dart';

import 'package:echat/main.dart';

void main() {
  testWidgets('Echat app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EchatApp());

    // Verify that the app loads with the home screen
    expect(find.text('Echat'), findsOneWidget);
    
    // Verify bottom navigation tabs are present
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Mini Apps'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
