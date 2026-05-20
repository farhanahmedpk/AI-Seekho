import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cold_guard/main.dart';

void main() {
  testWidgets('ColdGuard app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ColdGuardApp()));
    await tester.pumpAndSettle();
    expect(find.text('ColdGuard'), findsWidgets);
  });
}
