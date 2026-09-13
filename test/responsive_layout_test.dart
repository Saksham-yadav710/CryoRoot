import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryoroots/core/widgets/responsive_layout.dart';
import 'package:cryoroots/features/dashboard/widgets/telemetry_grid.dart';
import 'package:cryoroots/features/dashboard/widgets/telemetry_card.dart';
import 'package:cryoroots/models/sensor_reading.dart';
import 'package:cryoroots/features/navigation/main_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ResponsiveBreakpoints Tests', () {
    testWidgets('identifies mobile viewport (< 600px)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool isMobile;
      late bool isTablet;
      late bool isDesktop;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isMobile = ResponsiveBreakpoints.isMobile(context);
              isTablet = ResponsiveBreakpoints.isTablet(context);
              isDesktop = ResponsiveBreakpoints.isDesktop(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isMobile, isTrue);
      expect(isTablet, isFalse);
      expect(isDesktop, isFalse);
    });

    testWidgets('identifies tablet viewport (600px - 899px)', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool isMobile;
      late bool isTablet;
      late bool isDesktop;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isMobile = ResponsiveBreakpoints.isMobile(context);
              isTablet = ResponsiveBreakpoints.isTablet(context);
              isDesktop = ResponsiveBreakpoints.isDesktop(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isMobile, isFalse);
      expect(isTablet, isTrue);
      expect(isDesktop, isFalse);
    });

    testWidgets('identifies desktop web viewport (>= 900px)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool isMobile;
      late bool isTablet;
      late bool isDesktop;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isMobile = ResponsiveBreakpoints.isMobile(context);
              isTablet = ResponsiveBreakpoints.isTablet(context);
              isDesktop = ResponsiveBreakpoints.isDesktop(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isMobile, isFalse);
      expect(isTablet, isFalse);
      expect(isDesktop, isTrue);
    });
  });

  group('ResponsiveCenter Widget Tests', () {
    testWidgets('enforces max-width constraint on 1920px screen',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveCenter(
              maxWidth: 1200,
              child: SizedBox(
                key: Key('test-child'),
                width: double.infinity,
                height: 200,
              ),
            ),
          ),
        ),
      );

      final childBox =
          tester.renderObject(find.byKey(const Key('test-child'))) as RenderBox;
      // On 1920px with padding 24 on each side, width is 1200 - 48 = 1152
      expect(childBox.size.width, lessThanOrEqualTo(1200));
      expect(childBox.size.width, greaterThan(1000));
    });
  });

  group('TelemetryGrid Responsive Behavior Tests', () {
    final mockReading = SensorReading(
      deviceId: 'AC-DEV-001',
      temperature: 4.2,
      humidity: 91.0,
      battery: 94,
      solarPower: 840,
      pcmReserveHours: 18.5,
      gridPower: true,
      doorOpen: false,
      waterLevel: 88,
      isOnline: true,
      timestamp: DateTime.now(),
    );

    testWidgets('renders 4 columns on desktop web (width >= 800)',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TelemetryGrid(reading: mockReading),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final gridViewFinder = find.byType(GridView);
      expect(gridViewFinder, findsOneWidget);

      final gridView = tester.widget<GridView>(gridViewFinder);
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      // On desktop width >= 800, crossAxisCount must be 4
      expect(delegate.crossAxisCount, 4);

      // Verify all 4 primary cards exist
      expect(find.widgetWithText(TelemetryCard, 'TEMPERATURE'), findsOneWidget);
      expect(find.widgetWithText(TelemetryCard, 'HUMIDITY'), findsOneWidget);
      expect(find.widgetWithText(TelemetryCard, 'BATTERY'), findsOneWidget);
      expect(find.widgetWithText(TelemetryCard, 'SOLAR POWER'), findsOneWidget);
    });

    testWidgets('renders 2 columns on mobile (width < 600)', (tester) async {
      tester.view.physicalSize = const Size(380, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TelemetryGrid(reading: mockReading),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final gridViewFinder = find.byType(GridView);
      expect(gridViewFinder, findsOneWidget);

      final gridView = tester.widget<GridView>(gridViewFinder);
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      // On mobile width < 600, crossAxisCount must be 2
      expect(delegate.crossAxisCount, 2);
    });
  });

  group('MainScaffold Responsive Navigation Tests', () {
    GoRouter createTestRouter() {
      return GoRouter(
        initialLocation: '/',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return MainScaffold(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) =>
                        const SizedBox(key: Key('home-tab-view')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/produce',
                    builder: (context, state) => const SizedBox(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/market',
                    builder: (context, state) => const SizedBox(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/alerts',
                    builder: (context, state) => const SizedBox(),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    testWidgets('renders NavigationRail on desktop web (width >= 900)',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: createTestRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('renders NavigationBar on mobile (< 900)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: createTestRouter(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });
  });
}
