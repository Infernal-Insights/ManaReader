import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mana_reader/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation smoke test', () {
    testWidgets('bottom nav tabs are tappable', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: ManaReaderApp()));
      await tester.pumpAndSettle();

      // Home tab should be visible by default
      expect(find.byIcon(Icons.home), findsWidgets);

      // Navigate to Library tab
      await tester.tap(find.byIcon(Icons.collections_bookmark_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Library'), findsOneWidget);

      // Navigate to Sources tab
      await tester.tap(find.byIcon(Icons.cloud_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Sources'), findsOneWidget);

      // Navigate to Settings tab
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
