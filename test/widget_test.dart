import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryoroots/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'cryoroot_logged_in_user_id': 'farmer-a',
      'cryoroot_logged_in_role': 'farmer',
      'cryoroot_logged_in_remember_me': true,
    });
  });

  testWidgets('CryoRoot Complete Flow: Home, Detailed, Produce, Market, Alerts',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CryoRootApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Home Screen Branding and Key Telemetry
    expect(find.text('CryoRoots'), findsWidgets);
    expect(find.text('NER'), findsOneWidget);
    expect(find.text('TEMPERATURE'), findsOneWidget);
    expect(find.text('HUMIDITY'), findsOneWidget);
    expect(find.text('BATTERY'), findsOneWidget);
    expect(find.text('SOLAR POWER'), findsOneWidget);
    expect(find.text('PCM BACKUP'), findsOneWidget);

    // 2. Navigate to Detailed Storage Screen
    await tester.ensureVisible(find.text('DETAILED DATA'));
    await tester.tap(find.text('DETAILED DATA'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Cold Storage 1 Analytics'), findsOneWidget);
    expect(find.text('24-HOUR ANALYTICS & TRENDS'), findsOneWidget);

    // 3. Return to Home
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // 4. Navigate to Produce Inventory Tab
    await tester.tap(find.text('Produce'));
    await tester.pumpAndSettle();
    expect(find.text('TOTAL PRODUCE STORED'), findsOneWidget);
    expect(find.text('INTAKE PRODUCE'), findsOneWidget);

    // 5. Navigate to Market Intelligence Tab
    await tester.tap(find.text('Market'));
    await tester.pumpAndSettle();
    expect(find.text('Market Intelligence & Advisory'), findsOneWidget);
    expect(find.text('STORED PRODUCE DECISION ADVISORIES'), findsOneWidget);
    expect(
        find.text('REGIONAL WHOLESALE MANDI PRICES (TODAY)'), findsOneWidget);

    // 6. Navigate to Alerts Tab
    await tester.tap(find.text('Alerts'));
    await tester.pumpAndSettle();
    expect(find.text('Storage Alerts & Actions'), findsOneWidget);
    expect(find.text('ACTIVE FARM ALERTS'), findsOneWidget);
    expect(find.text('WHAT SHOULD I DO?'), findsWidgets);
  });
}
