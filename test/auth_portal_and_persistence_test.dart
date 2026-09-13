import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agricool_ner/models/app_user.dart';
import 'package:agricool_ner/services/auth/auth_session_service.dart';
import 'package:agricool_ner/state/auth_providers.dart';
import 'package:agricool_ner/state/technician_auth_provider.dart';
import 'package:agricool_ner/features/auth/screens/login_screen.dart';

void main() {
  group('🔐 AuthSessionService & Persistent Storage Tests', () {
    test('Saves, retrieves, and clears AppUser session in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      const service = AuthSessionService();

      expect(await service.hasActiveSession(), isFalse);
      expect(await service.getSavedSession(), isNull);

      // Save Farmer A session
      await service.saveSession(AppUser.farmerA, rememberMe: true);

      expect(await service.hasActiveSession(), isTrue);
      final restored = await service.getSavedSession();
      expect(restored, isNotNull);
      expect(restored!.id, equals('farmer-a'));
      expect(restored.isFarmer, isTrue);

      // Clear session (Logout)
      await service.clearSession();
      expect(await service.hasActiveSession(), isFalse);
      expect(await service.getSavedSession(), isNull);
    });

    test('Persists and restores technician session', () async {
      SharedPreferences.setMockInitialValues({});
      const service = AuthSessionService();

      await service.saveSession(AppUser.technician, rememberMe: true);
      expect(await service.hasActiveSession(), isTrue);
      final restored = await service.getSavedSession();
      expect(restored, isNotNull);
      expect(restored!.id, equals('tech-01'));
      expect(restored.isTechnician, isTrue);
    });
  });

  group('🌾 Auto-Login & Session State Tests ("Once login, then login until logout")', () {
    test('Fresh install without session starts in unauthenticated state', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(authStateProvider).isAuthenticated, isFalse);
      // Let any microtasks settle
      await container.read(authStateProvider.notifier).initSession();

      final updatedState = container.read(authStateProvider);
      expect(updatedState.isAuthenticated, isFalse);
      expect(updatedState.currentUser, isNull);
    });

    test('Booting with saved session automatically logs in farmer without prompting', () async {
      // Simulate farmer having previously logged in
      SharedPreferences.setMockInitialValues({
        'cryoroot_logged_in_user_id': 'farmer-a',
        'cryoroot_logged_in_role': 'farmer',
        'cryoroot_logged_in_remember_me': true,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(authStateProvider.notifier).initSession();

      final authState = container.read(authStateProvider);
      expect(authState.isAuthenticated, isTrue);
      expect(authState.currentUser, isNotNull);
      expect(authState.currentUser!.id, equals('farmer-a'));
      expect(authState.currentUser!.name, contains('Ramesh'));

      // currentUserProvider should also be synced
      final currentPersona = container.read(currentUserProvider);
      expect(currentPersona.id, equals('farmer-a'));
    });

    test('Farmer login with valid credentials persists session to storage', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final success = await container.read(authStateProvider.notifier).loginFarmer(
            identifier: '98765 11001',
            pinOrPassword: '1234',
            rememberMe: true,
          );

      expect(success, isTrue);
      final authState = container.read(authStateProvider);
      expect(authState.isAuthenticated, isTrue);
      expect(authState.currentUser!.id, equals('farmer-a'));

      // Verify persistent storage now has the session
      final sessionService = container.read(authSessionServiceProvider);
      expect(await sessionService.hasActiveSession(), isTrue);
    });

    test('Farmer login with invalid PIN fails and does not save session', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final success = await container.read(authStateProvider.notifier).loginFarmer(
            identifier: '98765 11001',
            pinOrPassword: 'wrong-pin',
          );

      expect(success, isFalse);
      final authState = container.read(authStateProvider);
      expect(authState.isAuthenticated, isFalse);
      expect(authState.errorMessage, isNotNull);

      // Verify nothing saved in storage
      final sessionService = container.read(authSessionServiceProvider);
      expect(await sessionService.hasActiveSession(), isFalse);
    });

    test('Technician login validates credentials and syncs technicianAuthProvider', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final success = await container.read(authStateProvider.notifier).loginTechnician(
            userId: 'tech-01',
            password: 'tech123',
            rememberMe: true,
          );

      expect(success, isTrue);
      final authState = container.read(authStateProvider);
      expect(authState.isAuthenticated, isTrue);
      expect(authState.currentUser!.isTechnician, isTrue);

      // Verify technicianAuthProvider is also unlocked
      final techState = container.read(technicianAuthProvider);
      expect(techState.isAuthenticated, isTrue);
    });

    test('Explicit logout purges persistent storage and clears session state', () async {
      SharedPreferences.setMockInitialValues({
        'cryoroot_logged_in_user_id': 'farmer-a',
        'cryoroot_logged_in_role': 'farmer',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(authStateProvider.notifier).initSession();
      expect(container.read(authStateProvider).isAuthenticated, isTrue);

      // Farmer explicitly logs out
      await container.read(authStateProvider.notifier).logout();

      final authState = container.read(authStateProvider);
      expect(authState.isAuthenticated, isFalse);
      expect(authState.currentUser, isNull);

      final sessionService = container.read(authSessionServiceProvider);
      expect(await sessionService.hasActiveSession(), isFalse);
    });
  });

  group('🖥️ LoginScreen Portal Widget Tests', () {
    testWidgets('Renders LoginScreen with Farmer & Technician Portal tabs', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify branding & tabs
      expect(find.text('Cryo'), findsOneWidget);
      expect(find.text('Root'), findsOneWidget);
      expect(find.text('Farmer Portal'), findsOneWidget);
      expect(find.text('Technician Portal'), findsOneWidget);

      // Verify Farmer form is visible by default
      expect(find.text('Mobile Number / Farmer ID'), findsOneWidget);
      expect(find.text('4-Digit Security PIN'), findsOneWidget);
      expect(find.text('LOG IN AS FARMER'), findsOneWidget);
      expect(find.textContaining('Auto-Login Active'), findsOneWidget);

      // Verify demo chips
      expect(find.text('Farmer Ramesh (A)'), findsOneWidget);
      expect(find.text('Farmer Suresh (B)'), findsOneWidget);
    });

    testWidgets('Demo chips autofill Farmer credentials and allow login', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Farmer Suresh (B) demo chip
      await tester.ensureVisible(find.text('Farmer Suresh (B)'));
      await tester.tap(find.text('Farmer Suresh (B)'));
      await tester.pumpAndSettle();

      // Tap Login Button
      await tester.ensureVisible(find.text('LOG IN AS FARMER'));
      await tester.tap(find.text('LOG IN AS FARMER'));
      await tester.pumpAndSettle();

      // Verify session was saved for Farmer B
      const service = AuthSessionService();
      final savedUser = await service.getSavedSession();
      expect(savedUser, isNotNull);
      expect(savedUser!.id, equals('farmer-b'));
    });

    testWidgets('Technician tab switches form and displays technician controls', (tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Technician Portal tab
      await tester.ensureVisible(find.text('Technician Portal'));
      await tester.tap(find.text('Technician Portal'));
      await tester.pumpAndSettle();

      // Verify technician form fields
      expect(find.text('Technician Service ID / Email'), findsOneWidget);
      expect(find.text('Service Password'), findsOneWidget);
      expect(find.text('VERIFY & ENTER AS TECHNICIAN'), findsOneWidget);
      expect(find.textContaining('Tech Bikash'), findsOneWidget);
    });
  });
}
