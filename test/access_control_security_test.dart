import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryoroots/models/app_user.dart';
import 'package:cryoroots/models/cold_storage_unit.dart';
import 'package:cryoroots/models/sensor_reading.dart';
import 'package:cryoroots/services/security/storage_security_engine.dart';
import 'package:cryoroots/state/auth_providers.dart';
import 'package:cryoroots/state/storage_providers.dart';
import 'package:cryoroots/features/storage/widgets/chamber_setpoint_control_card.dart';
import 'package:cryoroots/features/storage/widgets/user_role_switcher_bar.dart';

void main() {
  group('🔐 Cold Storage Ownership & Access Control Security Tests', () {
    late ColdStorageUnit unit1;
    late ColdStorageUnit unit3;

    setUp(() {
      final now = DateTime.now();
      final reading = SensorReading(
        deviceId: 'CR-TEST-01',
        temperature: 4.0,
        humidity: 90.0,
        battery: 85,
        solarPower: 1200,
        gridPower: true,
        doorOpen: false,
        pcmReserveHours: 20.0,
        waterLevel: 90,
        isOnline: true,
        timestamp: now,
      );

      unit1 = ColdStorageUnit(
        id: 'AC-NER-001',
        name: 'Unit 1 - Solar Chamber Alpha',
        village: 'Kalyanpur',
        district: 'Barabanki',
        capacityKg: 5000,
        currentOccupancyKg: 3800,
        primaryProduce: 'Potato (Kufri Jyoti)',
        reading: reading,
        recommendedAction: 'Maintain setpoints',
        targetTemperature: 4.0,
        targetHumidity: 90.0,
        ownerFarmerId: 'farmer-a',
        ownerFarmerName: 'Ramesh Patel (Farmer A)',
        isTechnicianAccessGranted: false,
      );

      unit3 = ColdStorageUnit(
        id: 'AC-NER-003',
        name: 'Unit 3 - Solar Chamber Gamma',
        village: 'Masauli',
        district: 'Barabanki',
        capacityKg: 5000,
        currentOccupancyKg: 4200,
        primaryProduce: 'Tomato (Himsona)',
        reading: reading,
        recommendedAction: 'Check cooling',
        targetTemperature: 10.0,
        targetHumidity: 88.0,
        ownerFarmerId: 'farmer-b',
        ownerFarmerName: 'Suresh Kumar (Farmer B)',
        isTechnicianAccessGranted: false,
      );
    });

    test('StorageSecurityEngine: Ownership identification is exact', () {
      expect(StorageSecurityEngine.isOwner(unit1, AppUser.farmerA), isTrue);
      expect(StorageSecurityEngine.isOwner(unit1, AppUser.farmerB), isFalse);
      expect(StorageSecurityEngine.isOwner(unit1, AppUser.technician), isFalse);

      expect(StorageSecurityEngine.isOwner(unit3, AppUser.farmerA), isFalse);
      expect(StorageSecurityEngine.isOwner(unit3, AppUser.farmerB), isTrue);
    });

    test('StorageSecurityEngine: Farmer A can control Unit 1; Farmer B cannot control Unit 1', () {
      // Farmer A owns Unit 1 -> Authorized
      expect(StorageSecurityEngine.canControlSetpoints(unit1, AppUser.farmerA), isTrue);

      // Farmer B does NOT own Unit 1 -> Strictly forbidden
      expect(StorageSecurityEngine.canControlSetpoints(unit1, AppUser.farmerB), isFalse);

      // Farmer B owns Unit 3 -> Authorized on Unit 3
      expect(StorageSecurityEngine.canControlSetpoints(unit3, AppUser.farmerB), isTrue);

      // Farmer A does NOT own Unit 3 -> Strictly forbidden on Unit 3
      expect(StorageSecurityEngine.canControlSetpoints(unit3, AppUser.farmerA), isFalse);
    });

    test('StorageSecurityEngine: Technician access strictly depends on owner permission grant', () {
      // Default: technician permission is false -> Technician cannot control
      expect(unit1.isTechnicianAccessGranted, isFalse);
      expect(StorageSecurityEngine.canControlSetpoints(unit1, AppUser.technician), isFalse);

      // When owner grants technician access -> Technician can control
      final unitWithTechAccess = unit1.copyWith(
        isTechnicianAccessGranted: true,
        technicianAccessGrantedAt: DateTime.now(),
      );
      expect(StorageSecurityEngine.canControlSetpoints(unitWithTechAccess, AppUser.technician), isTrue);

      // Even when technician access is granted, other farmers (Farmer B) still CANNOT control Unit 1
      expect(StorageSecurityEngine.canControlSetpoints(unitWithTechAccess, AppUser.farmerB), isFalse);
    });

    test('StorageSecurityEngine: Only the owner farmer can grant or revoke technician permission', () {
      // Farmer A (owner) can toggle technician access
      expect(StorageSecurityEngine.canToggleTechnicianAccess(unit1, AppUser.farmerA), isTrue);

      // Farmer B (non-owner) CANNOT toggle technician access on Unit 1
      expect(StorageSecurityEngine.canToggleTechnicianAccess(unit1, AppUser.farmerB), isFalse);

      // Technician CANNOT self-grant or toggle permission
      expect(StorageSecurityEngine.canToggleTechnicianAccess(unit1, AppUser.technician), isFalse);
    });

    test('StorageSecurityEngine: Status message correctly reflects permission state', () {
      final msgOwner = StorageSecurityEngine.getAccessStatusMessage(unit1, AppUser.farmerA);
      expect(msgOwner, contains('registered owner'));

      final msgNonOwner = StorageSecurityEngine.getAccessStatusMessage(unit1, AppUser.farmerB);
      expect(msgNonOwner, contains('Access Restricted'));
      expect(msgNonOwner, contains('Ramesh Patel (Farmer A)'));

      final msgTechLocked = StorageSecurityEngine.getAccessStatusMessage(unit1, AppUser.technician);
      expect(msgTechLocked, contains('Technician Control Locked'));

      final unitWithTechAccess = unit1.copyWith(isTechnicianAccessGranted: true);
      final msgTechAllowed = StorageSecurityEngine.getAccessStatusMessage(unitWithTechAccess, AppUser.technician);
      expect(msgTechAllowed, contains('Authorized Technician Mode'));
    });

    test('State Provider: updateUnitSetpoints RBAC protection rejects unauthorized updates', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(storageUnitsProvider.notifier);

      // 1. Farmer B attempts to alter Farmer A's unit (AC-NER-001) -> MUST FAIL
      final unauthorizedSuccess = notifier.updateUnitSetpoints(
        'AC-NER-001',
        caller: AppUser.farmerB,
        targetTemperature: 2.0,
        targetHumidity: 85.0,
      );
      expect(unauthorizedSuccess, isFalse, reason: 'Farmer B must not be permitted to update Farmer A cold storage');

      final unitsAfterFail = container.read(storageUnitsProvider);
      final unit1AfterFail = unitsAfterFail.firstWhere((u) => u.id == 'AC-NER-001');
      expect(unit1AfterFail.targetTemperature, equals(4.0), reason: 'Temperature must remain unchanged');

      // 2. Technician attempts to alter AC-NER-001 without permission -> MUST FAIL
      final techFail = notifier.updateUnitSetpoints(
        'AC-NER-001',
        caller: AppUser.technician,
        targetTemperature: 1.0,
      );
      expect(techFail, isFalse);

      // 3. Farmer A (owner) alters AC-NER-001 -> MUST SUCCEED
      final ownerSuccess = notifier.updateUnitSetpoints(
        'AC-NER-001',
        caller: AppUser.farmerA,
        targetTemperature: 3.5,
        targetHumidity: 92.0,
        tempHysteresis: 0.8,
      );
      expect(ownerSuccess, isTrue);

      final unitsAfterOwner = container.read(storageUnitsProvider);
      final unit1AfterOwner = unitsAfterOwner.firstWhere((u) => u.id == 'AC-NER-001');
      expect(unit1AfterOwner.targetTemperature, equals(3.5));
      expect(unit1AfterOwner.targetHumidity, equals(92.0));
      expect(unit1AfterOwner.tempHysteresis, equals(0.8));
    });

    test('State Provider: toggleTechnicianAccess enforces owner-only permission changes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(storageUnitsProvider.notifier);

      // 1. Technician tries to self-authorize on AC-NER-001 -> REJECTED
      final techSelfAuth = notifier.toggleTechnicianAccess(
        'AC-NER-001',
        caller: AppUser.technician,
        grantAccess: true,
      );
      expect(techSelfAuth, isFalse);
      expect(container.read(storageUnitsProvider).firstWhere((u) => u.id == 'AC-NER-001').isTechnicianAccessGranted, isFalse);

      // 2. Farmer B tries to authorize technician on Farmer A's AC-NER-001 -> REJECTED
      final farmerBAuth = notifier.toggleTechnicianAccess(
        'AC-NER-001',
        caller: AppUser.farmerB,
        grantAccess: true,
      );
      expect(farmerBAuth, isFalse);
      expect(container.read(storageUnitsProvider).firstWhere((u) => u.id == 'AC-NER-001').isTechnicianAccessGranted, isFalse);

      // 3. Farmer A (owner) authorizes technician on AC-NER-001 -> SUCCESS
      final ownerAuth = notifier.toggleTechnicianAccess(
        'AC-NER-001',
        caller: AppUser.farmerA,
        grantAccess: true,
      );
      expect(ownerAuth, isTrue);
      expect(container.read(storageUnitsProvider).firstWhere((u) => u.id == 'AC-NER-001').isTechnicianAccessGranted, isTrue);

      // 4. Now technician can successfully calibrate setpoints on AC-NER-001!
      final techSuccess = notifier.updateUnitSetpoints(
        'AC-NER-001',
        caller: AppUser.technician,
        targetTemperature: 2.8,
        targetHumidity: 88.0,
      );
      expect(techSuccess, isTrue);
      expect(container.read(storageUnitsProvider).firstWhere((u) => u.id == 'AC-NER-001').targetTemperature, equals(2.8));

      // 5. Farmer A revokes technician access -> Technician is locked out again
      final ownerRevoke = notifier.toggleTechnicianAccess(
        'AC-NER-001',
        caller: AppUser.farmerA,
        grantAccess: false,
      );
      expect(ownerRevoke, isTrue);
      expect(container.read(storageUnitsProvider).firstWhere((u) => u.id == 'AC-NER-001').isTechnicianAccessGranted, isFalse);

      final techRevokedAttempt = notifier.updateUnitSetpoints(
        'AC-NER-001',
        caller: AppUser.technician,
        targetTemperature: 5.0,
      );
      expect(techRevokedAttempt, isFalse);
      expect(container.read(storageUnitsProvider).firstWhere((u) => u.id == 'AC-NER-001').targetTemperature, equals(2.8));
    });

    testWidgets('UI Test: ChamberSetpointControlCard displays security lock for Farmer B', (tester) async {
      final container = ProviderContainer(
        overrides: [
          // Set active user to Farmer B
          currentUserProvider.overrideWith((ref) => CurrentUserNotifier()..switchToFarmerB()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ChamberSetpointControlCard(unit: unit1),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that ACCESS RESTRICTED banner appears
      expect(find.text('ACCESS RESTRICTED (READ-ONLY)'), findsOneWidget);
      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.textContaining('Ramesh Patel (Farmer A)'), findsWidgets);

      // Verify technician permission switch is NOT visible to Farmer B
      expect(find.text('Technician Servicing Permission'), findsNothing);

      // Verify Save button shows Locked for non-owners
      expect(find.text('Locked (Owner Access Only)'), findsOneWidget);
    });

    testWidgets('UI Test: ChamberSetpointControlCard displays full controls and toggle for Farmer A', (tester) async {
      final container = ProviderContainer(
        overrides: [
          // Set active user to Farmer A (owner of unit1)
          currentUserProvider.overrideWith((ref) => CurrentUserNotifier()..switchToFarmerA()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ChamberSetpointControlCard(unit: unit1),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AUTHORIZED pill appears
      expect(find.text('AUTHORIZED'), findsOneWidget);
      expect(find.textContaining('Owner: Ramesh Patel (Farmer A)'), findsOneWidget);

      // Verify Technician Servicing Permission toggle switch is present
      expect(find.text('Technician Servicing Permission'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      // Verify Save button shows synchronized state when unchanged
      expect(find.text('Setpoints Synchronized'), findsOneWidget);
    });

    testWidgets('UI Test: UserRoleSwitcherBar switches active persona and reflects updates', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: UserRoleSwitcherBar(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default user is Farmer A
      expect(find.text('Ramesh Patel (Farmer A)'), findsOneWidget);

      // Switch to Farmer B
      await tester.tap(find.textContaining('Farmer B (Suresh)'));
      await tester.pumpAndSettle();

      expect(container.read(currentUserProvider).id, equals('farmer-b'));
      expect(find.text('Suresh Kumar (Farmer B)'), findsOneWidget);

      // Switch to Field Tech
      await tester.tap(find.textContaining('Field Tech (Bikash)'));
      await tester.pumpAndSettle();

      expect(container.read(currentUserProvider).id, equals('tech-01'));
      expect(find.text('Bikash Sharma (Field Technician)'), findsOneWidget);
    });
  });
}
