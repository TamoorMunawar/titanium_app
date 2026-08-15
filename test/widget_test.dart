import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:titaniumapp/controllers/auth_controller.dart';
import 'package:titaniumapp/core/storage/token_storage.dart';
import 'package:titaniumapp/main.dart';

/// Avoids touching the real flutter_secure_storage platform channel, which
/// isn't mocked in the widget-test harness.
class _FakeTokenStorage extends TokenStorage {
  @override
  Future<String?> readToken() async => null;

  @override
  Future<Map<String, dynamic>?> readUser() async => null;

  @override
  Future<void> saveSession(String token, Map<String, dynamic> userJson) async {}

  @override
  Future<void> clearSession() async {}
}

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(_FakeTokenStorage()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.text('Titanium Cars'), findsOneWidget);

    // Let the splash screen's minimum-display timer and session check
    // resolve before the test ends.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
