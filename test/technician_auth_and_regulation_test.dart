import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agricool_ner/models/cold_storage_unit.dart';
import 'package:agricool_ner/models/sensor_reading.dart';
import 'package:agricool_ner/models/status_level.dart';
import 'package:agricool_ner/models/storage_analytics.dart';
import 'package:agricool_ner/state/auth_providers.dart';
import 'package:agricool_ner/state/storage_providers.dart';
import 'package:agricool_ner/state/technician_auth_provider.dart';
import 'package:agricool_ner/features/storage/widgets/technician_hardware_card.dart';
import 'package:agricool_ner/features/storage/widgets/technician_login_dialog.dart';
import 'package:agricool_ner/features/storage/screens/detailed_storage_screen.dart';

void main() {
  group('🔧 Technician Panel Authentication & Climate Regulation Tests', () {
    late ColdStorageUnit unit1;
    late DeviceHealthStatus health;

    setUp(() {
      final now = DateTime.now();
      final reading = SensorReading(
        deviceId: 'AC-DEV-001',
        temperature: 4.2,
        humidity: 90.0,
        battery: 80,
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
        primaryProduce: 'Tomato',
        reading: reading,
        recommendedAction: 'Optimal condition',
        targetTemperature: 4.0,
        targetHumidity: 90.0,
        tempHysteresis: 0.5,
        isDefrostActive: false,
        ownerFarmerId: 'farmer-a',
        ownerFarmerName: 'Ramesh Patel (Farmer A)',
        isTechnicianAccessGranted: false,
      );

      health = const DeviceHealthStatus(
        controllerStatus: StatusLevel.good,
        controllerFirmware: 'v2.4.1-rc2',
        compressorStatus: StatusLevel.good,
        compressorHoursRun: 1240,
        tempSensorStatus: StatusLevel.good,
        humiditySensorStatus: StatusLevel.good,
        solarInverterStatus: StatusLevel.good,
        connectivityType: '4G LTE-M / NB-IoT',
        networkSignalRssi: -72,
        busErrorCount: 0,
        lastCalibrationDate: '12-Aug-2026',
        tempSensorModel: 'PT1000 Class A Platinum RTD',
        tempBusInterface: 'ADS1115 ADC (4-20mA Current Loop)',
        tempRawVoltage: 1.652,
        tempResistanceOhms: 10380,
        tempCalibrationOffset: 0.12,
        humiditySensorModel: 'Sensirion SHT35-DIS Precision Digital',
        humidityBusInterface: 'I2C Fast-Mode (400 kHz)',
        humidityI2cAddress: 0x44,
        compressorModel: 'Danfoss Secop BD350GH Variable Inverter',
        compressorFrequencyHz: 58.4,
        refrigerantType: 'R134a (Eco-Charge)',
        suctionPressurePsi: 28.5,
        dischargePressurePsi: 142.0,
        requiredServiceParts: [
          'PT1000 Temperature Probe Assembly (Part #CR-PRB-100)',
          'SHT35 Humidity Sensor Element w/ PTFE Filter (Part #CR-SHT-35)',
        ],
      );
    });

    test('TechnicianAuthNotifier: Rejects invalid credentials and accepts valid credentials', () async {
      final container = ProviderContainer();
      try {
        final authNotifier = container.read(technicianAuthProvider.notifier);

        // 1. Initial state must be unauthenticated
        expect(container.read(technicianAuthProvider).isAuthenticated, isFalse);

        // 2. Invalid User ID & Password attempt
        final failedAttempt = authNotifier.login('wrong-user', 'bad-pass');
        expect(failedAttempt, isFalse);
        expect(container.read(technicianAuthProvider).isAuthenticated, isFalse);
        expect(container.read(technicianAuthProvider).errorMessage, contains('Invalid Technician ID'));

        // 3. Valid credentials attempt
        final successfulAttempt = authNotifier.login('tech-01', 'tech123');
        expect(successfulAttempt, isTrue);
        expect(container.read(technicianAuthProvider).isAuthenticated, isTrue);
        expect(container.read(technicianAuthProvider).errorMessage, isNull);

        await Future<void>.delayed(Duration.zero);
        expect(container.read(currentUserProvider).id, equals('tech-01'));

        // 4. Logout locks the panel and clears authentication
        authNotifier.logout();
        expect(container.read(technicianAuthProvider).isAuthenticated, isFalse);
        expect(container.read(technicianAuthProvider).user, isNull);

        await Future<void>.delayed(Duration.zero);
        expect(container.read(currentUserProvider).id, equals('farmer-a'));
      } finally {
        container.dispose();
      }
    });

    testWidgets('UI Test: TechnicianLoginDialog validates inputs and handles demo autofill', (tester) async {
      final container = ProviderContainer();
      try {
        bool authenticatedCallbackFired = false;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: TechnicianLoginDialog(
                  onAuthenticated: () {
                    authenticatedCallbackFired = true;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Dialog header and inputs exist
        expect(find.text('Technician Verification'), findsOneWidget);
        expect(find.text('TECHNICIAN USER ID'), findsOneWidget);
        expect(find.text('SECURITY PASSWORD'), findsOneWidget);

        // Tap "Demo Creds" auto-fill chip
        await tester.tap(find.textContaining('Demo Creds: tech-01 / tech123'));
        await tester.pumpAndSettle();

        // Tap "Unlock Panel" button
        await tester.tap(find.text('Unlock Panel'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(authenticatedCallbackFired, isTrue);
        expect(container.read(technicianAuthProvider).isAuthenticated, isTrue);
      } finally {
        container.dispose();
      }
    });

    testWidgets('UI Test: TechnicianHardwareCard allows technician to regulate temperature and humidity', (tester) async {
      final container = ProviderContainer(
        overrides: [
          // Pre-populate with MockStorageData without starting background streams
          storageUnitsProvider.overrideWith((ref) => StorageUnitsNotifier()),
        ],
      );

      try {
        // Authenticate as technician
        container.read(technicianAuthProvider.notifier).login('tech-01', 'tech123');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: TechnicianHardwareCard(
                    unit: unit1,
                    health: health,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify technician regulation headers
        expect(find.text('TECHNICIAN CLIMATE REGULATION'), findsOneWidget);
        expect(find.text('Target Temperature'), findsOneWidget);
        expect(find.text('Target Humidity'), findsOneWidget);

        // Tap quick temperature preset: 2.5°C Chill
        await tester.tap(find.text('2.5°C Chill'));
        await tester.pumpAndSettle();

        // Tap quick humidity preset: 95% High RH
        await tester.tap(find.text('95% High RH'));
        await tester.pumpAndSettle();

        // Verify pending sync indicator appears
        expect(find.text('PENDING SYNC'), findsOneWidget);
        expect(find.text('Apply Hardware Regulation Setpoints'), findsOneWidget);

        // Tap "Apply Hardware Regulation Setpoints"
        await tester.tap(find.text('Apply Hardware Regulation Setpoints'));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // Verify setpoints in state were updated
        final updatedUnit = container.read(storageUnitsProvider).firstWhere((u) => u.id == 'AC-NER-001');
        expect(updatedUnit.targetTemperature, equals(2.5));
        expect(updatedUnit.targetHumidity, equals(95.0));

        // Verify success confirmation
        expect(find.text('Regulation Setpoints Synchronized'), findsOneWidget);
      } finally {
        container.dispose();
      }
    });

    testWidgets('UI Test: DetailedStorageScreen gates Tech Mode behind authentication dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          storageUnitsProvider.overrideWith((ref) => StorageUnitsNotifier()),
        ],
      );

      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: DetailedStorageScreen(unitId: 'AC-NER-001'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially in Farmer View
        expect(find.text('Farmer View'), findsOneWidget);
        expect(find.text('Tech Mode'), findsOneWidget);

        // Tap "Tech Mode" -> Should trigger Technician Verification dialog
        await tester.tap(find.text('Tech Mode'));
        await tester.pumpAndSettle();

        // Verify dialog is shown
        expect(find.text('Technician Verification'), findsOneWidget);
        expect(find.text('Authorized Personnel Only'), findsOneWidget);

        // Autofill demo credentials and submit
        await tester.tap(find.textContaining('Demo Creds: tech-01 / tech123'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Unlock Panel'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        // Now Tech Mode should be active and TechnicianHardwareCard visible
        expect(find.text('TECHNICIAN CLIMATE REGULATION'), findsOneWidget);
        expect(find.text('HARDWARE & FIELD SERVICING SPEC'), findsOneWidget);
      } finally {
        container.dispose();
      }
    });
  });
}
