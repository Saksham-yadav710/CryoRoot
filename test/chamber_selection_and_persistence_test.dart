import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryoroots/models/sensor_reading.dart';
import 'package:cryoroots/state/storage_providers.dart';
import 'package:cryoroots/features/storage/screens/detailed_storage_screen.dart';

void main() {
  group('❄️ Chamber Selection Persistence & Reactive Stability Tests', () {
    test(
        'selectedUnitIdProvider persists user selection across telemetry updates (does NOT reset to unit 1)',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 1. Initially defaults to unit 1
      expect(container.read(selectedUnitIdProvider), equals('AC-NER-001'));

      // 2. User selects Cold Storage 2 ('AC-NER-002')
      container.read(selectedUnitIdProvider.notifier).state = 'AC-NER-002';
      expect(container.read(selectedUnitIdProvider), equals('AC-NER-002'));

      // 3. Simulate multiple live telemetry events coming from the hardware
      final currentUnits = container.read(storageUnitsProvider);
      final newReading = SensorReading(
        deviceId: 'AC-DEV-002',
        temperature: 4.8,
        humidity: 89.0,
        battery: 75,
        solarPower: 1200,
        gridPower: true,
        doorOpen: false,
        pcmReserveHours: 22.0,
        waterLevel: 80,
        isOnline: true,
        timestamp: DateTime.now(),
      );

      // Trigger telemetry update on storageUnitsProvider
      container
          .read(storageUnitsProvider.notifier)
          .updateSensorReading('AC-NER-002', newReading);

      // Telemetry update on another unit
      container.read(storageUnitsProvider.notifier).updateSensorReading(
            'AC-NER-001',
            currentUnits.first.reading.copyWith(temperature: 3.9),
          );

      // CRITICAL ASSERTION: The selection MUST remain 'AC-NER-002' and NEVER revert to 'AC-NER-001'!
      expect(container.read(selectedUnitIdProvider), equals('AC-NER-002'));

      // 4. User selects Cold Storage 3 ('AC-NER-003')
      container.read(selectedUnitIdProvider.notifier).state = 'AC-NER-003';
      expect(container.read(selectedUnitIdProvider), equals('AC-NER-003'));

      // Trigger another batch of sensor readings
      container.read(storageUnitsProvider.notifier).updateSensorReading(
            'AC-NER-003',
            newReading.copyWith(temperature: 11.2),
          );

      // Selection MUST remain 'AC-NER-003'
      expect(container.read(selectedUnitIdProvider), equals('AC-NER-003'));
    });

    test(
        'activeAlertsProvider preserves acknowledged alert state across telemetry updates',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final alerts = container.read(activeAlertsProvider);
      expect(alerts, isNotEmpty);

      final firstAlert = alerts.first;
      expect(firstAlert.isAcknowledged, isFalse);

      // Acknowledge the alert
      container
          .read(activeAlertsProvider.notifier)
          .acknowledgeAlert(firstAlert.id);

      final updatedAlerts = container.read(activeAlertsProvider);
      final acknowledgedAlert =
          updatedAlerts.firstWhere((a) => a.id == firstAlert.id);
      expect(acknowledgedAlert.isAcknowledged, isTrue);

      // Simulate live telemetry tick
      final currentUnits = container.read(storageUnitsProvider);
      container.read(storageUnitsProvider.notifier).updateSensorReading(
            currentUnits.first.id,
            currentUnits.first.reading.copyWith(timestamp: DateTime.now()),
          );

      // Acknowledgment MUST persist and not be wiped by telemetry ticks
      final alertsAfterTick = container.read(activeAlertsProvider);
      final ackAfterTick =
          alertsAfterTick.firstWhere((a) => a.id == firstAlert.id);
      expect(ackAfterTick.isAcknowledged, isTrue);
    });

    testWidgets(
        'DetailedStorageScreen allows switching between Cold Storage 1, 2, and 3',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DetailedStorageScreen(unitId: 'AC-NER-001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Cold Storage 1 title and tabs are displayed
      expect(find.text('Cold Storage 1 Analytics'), findsOneWidget);
      expect(find.byKey(const Key('detailed_chamber_tab_AC-NER-001')),
          findsOneWidget);
      expect(find.byKey(const Key('detailed_chamber_tab_AC-NER-002')),
          findsOneWidget);
      expect(find.byKey(const Key('detailed_chamber_tab_AC-NER-003')),
          findsOneWidget);

      // Tap Cold Storage 2
      await tester.tap(find.byKey(const Key('detailed_chamber_tab_AC-NER-002')));
      await tester.pumpAndSettle();

      // Header now displays Cold Storage 2 Analytics
      expect(find.text('Cold Storage 2 Analytics'), findsOneWidget);

      // Tap Cold Storage 3
      await tester.tap(find.byKey(const Key('detailed_chamber_tab_AC-NER-003')));
      await tester.pumpAndSettle();

      // Header now displays Cold Storage 3 Analytics
      expect(find.text('Cold Storage 3 Analytics'), findsOneWidget);
    });
  });
}
