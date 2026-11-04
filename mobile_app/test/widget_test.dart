import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';

void main() {
  testWidgets('WinPlay splash screen loads',
      (WidgetTester tester) async {
    await tester.pumpWidget(const WinPlayApp());

    expect(find.text('WINPLAY'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back!'), findsOneWidget);
  });
}