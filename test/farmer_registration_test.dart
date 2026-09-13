import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryoroots/services/auth/auth_session_service.dart';
import 'package:cryoroots/state/auth_providers.dart';
import 'package:cryoroots/features/auth/screens/login_screen.dart';
import 'package:cryoroots/features/auth/widgets/farmer_registration_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🌱 Farmer Client Self-Registration & Persistence Tests', () {
    late SharedPreferences prefs;
    late AuthSessionService sessionService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      sessionService = AuthSessionService(prefs);
    });

    test('registerFarmer registers a new farmer client and persists session',
        () async {
      final container = ProviderContainer(
        overrides: [
          authSessionServiceProvider.overrideWithValue(sessionService),
        ],
      );
      addTearDown(container.dispose);

      // Verify initially not authenticated
      expect(container.read(authStateProvider).isAuthenticated, isFalse);

      // Register new farmer: Tenzing Norbu
      final success =
          await container.read(authStateProvider.notifier).registerFarmer(
                name: 'Tenzing Norbu',
                phone: '9811122334',
                pin: '7788',
                ownedUnitIds: ['AC-NER-001', 'AC-NER-002'],
                village: 'Barapani, Ri-Bhoi',
              );

      expect(success, isTrue);

      // AuthState must be updated
      final authState = container.read(authStateProvider);
      expect(authState.isAuthenticated, isTrue);
      expect(authState.currentUser, isNotNull);
      expect(authState.currentUser!.name, equals('Tenzing Norbu'));
      expect(authState.currentUser!.phone, equals('9811122334'));
      expect(authState.currentUser!.ownedUnitIds,
          equals(['AC-NER-001', 'AC-NER-002']));
      expect(authState.isFarmer, isTrue);

      // Verify currentUserProvider matches
      expect(container.read(currentUserProvider).name, equals('Tenzing Norbu'));

      // Verify session was saved into SharedPreferences
      expect(await sessionService.hasActiveSession(), isTrue);
      final restored = await sessionService.getSavedSession();
      expect(restored, isNotNull);
      expect(restored!.name, equals('Tenzing Norbu'));
      expect(restored.ownedUnitIds, equals(['AC-NER-001', 'AC-NER-002']));
    });

    test('registerFarmer rejects invalid inputs and duplicate phone numbers',
        () async {
      final container = ProviderContainer(
        overrides: [
          authSessionServiceProvider.overrideWithValue(sessionService),
        ],
      );
      addTearDown(container.dispose);

      // 1. Empty name
      final emptyName =
          await container.read(authStateProvider.notifier).registerFarmer(
                name: '',
                phone: '9811122334',
                pin: '7788',
                ownedUnitIds: ['AC-NER-001'],
              );
      expect(emptyName, isFalse);
      expect(container.read(authStateProvider).errorMessage,
          contains('enter your full name'));

      // 2. Short phone
      final shortPhone =
          await container.read(authStateProvider.notifier).registerFarmer(
                name: 'Tenzing Norbu',
                phone: '123',
                pin: '7788',
                ownedUnitIds: ['AC-NER-001'],
              );
      expect(shortPhone, isFalse);
      expect(container.read(authStateProvider).errorMessage,
          contains('valid 10-digit mobile number'));

      // 3. Invalid PIN (must be 4 digits)
      final invalidPin =
          await container.read(authStateProvider.notifier).registerFarmer(
                name: 'Tenzing Norbu',
                phone: '9811122334',
                pin: '12',
                ownedUnitIds: ['AC-NER-001'],
              );
      expect(invalidPin, isFalse);
      expect(container.read(authStateProvider).errorMessage,
          contains('4-digit numeric PIN'));

      // 4. Valid registration
      final valid =
          await container.read(authStateProvider.notifier).registerFarmer(
                name: 'Tenzing Norbu',
                phone: '9811122334',
                pin: '7788',
                ownedUnitIds: ['AC-NER-001'],
              );
      expect(valid, isTrue);

      // 5. Duplicate phone registration attempt
      final duplicate =
          await container.read(authStateProvider.notifier).registerFarmer(
                name: 'Another Farmer',
                phone: '9811122334',
                pin: '9999',
                ownedUnitIds: ['AC-NER-003'],
              );
      expect(duplicate, isFalse);
      expect(container.read(authStateProvider).errorMessage,
          contains('already registered'));
    });

    test(
        'Registered farmer can log out and log back in using registered phone & custom PIN',
        () async {
      final container = ProviderContainer(
        overrides: [
          authSessionServiceProvider.overrideWithValue(sessionService),
        ],
      );
      addTearDown(container.dispose);

      // Register farmer
      await container.read(authStateProvider.notifier).registerFarmer(
            name: 'Babul Gogoi',
            phone: '9855566778',
            pin: '3344',
            ownedUnitIds: ['AC-NER-003'],
          );

      // Log out
      await container.read(authStateProvider.notifier).logout();
      expect(container.read(authStateProvider).isAuthenticated, isFalse);
      expect(await sessionService.hasActiveSession(), isFalse);

      // Try wrong PIN
      final wrongPin =
          await container.read(authStateProvider.notifier).loginFarmer(
                identifier: '9855566778',
                pinOrPassword: '0000',
              );
      expect(wrongPin, isFalse);

      // Log in with correct custom PIN
      final correctLogin =
          await container.read(authStateProvider.notifier).loginFarmer(
                identifier: '9855566778',
                pinOrPassword: '3344',
              );
      expect(correctLogin, isTrue);
      expect(container.read(authStateProvider).currentUser!.name,
          equals('Babul Gogoi'));
      expect(container.read(authStateProvider).currentUser!.ownedUnitIds,
          equals(['AC-NER-003']));
    });

    testWidgets(
        'FarmerRegistrationDialog renders all fields and autofill works',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authSessionServiceProvider.overrideWithValue(sessionService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: FarmerRegistrationDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify form elements
      expect(find.text('New Farmer Registration'), findsOneWidget);
      expect(find.byKey(const Key('register_name_field')), findsOneWidget);
      expect(find.byKey(const Key('register_phone_field')), findsOneWidget);
      expect(find.byKey(const Key('register_pin_field')), findsOneWidget);
      expect(find.byKey(const Key('register_confirm_pin_field')), findsOneWidget);
      expect(find.byKey(const Key('submit_farmer_registration_btn')),
          findsOneWidget);

      // Tap Demo Autofill chip
      await tester.tap(find.text('Demo Fill: Tenzing Norbu'));
      await tester.pumpAndSettle();

      // Verify autofilled values
      expect(find.text('Tenzing Norbu'), findsOneWidget);
      expect(find.text('98111 22334'), findsOneWidget);
    });

    testWidgets('LoginScreen shows REGISTER button that opens registration dialog',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authSessionServiceProvider.overrideWithValue(sessionService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify "New Farmer Client?" section is visible
      expect(find.text('New Farmer Client?'), findsOneWidget);
      expect(find.byKey(const Key('open_farmer_registration_btn')),
          findsOneWidget);

      // Ensure REGISTER button is visible and tap it
      await tester.ensureVisible(find.byKey(const Key('open_farmer_registration_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open_farmer_registration_btn')));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.text('New Farmer Registration'), findsOneWidget);
    });
  });
}
