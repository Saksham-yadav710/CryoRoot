import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryoroots/models/cold_storage_unit.dart';
import 'package:cryoroots/models/sensor_reading.dart';
import 'package:cryoroots/models/status_level.dart';
import 'package:cryoroots/models/storage_analytics.dart';
import 'package:cryoroots/state/storage_providers.dart';
import 'package:cryoroots/features/dashboard/widgets/telemetry_card.dart';
import 'package:cryoroots/features/storage/widgets/chamber_setpoint_control_card.dart';
import 'package:cryoroots/features/storage/widgets/farmer_sensor_health_card.dart';
import 'package:cryoroots/features/storage/widgets/technician_hardware_card.dart';

void main() {
  group('🛠️ Hardware Diagnostics & Sensor Fault Detection Tests', () {
    test('Individual timestamps and relative text format correctly', () {
      final now = DateTime.now();
      final reading = SensorReading(
        deviceId: 'TEST-01',
        temperature: 4.0,
        humidity: 90.0,
        battery: 80,
        solarPower: 1200,
        gridPower: true,
        doorOpen: false,
        pcmReserveHours: 20.0,
        waterLevel: 90,
        isOnline: true,
        timestamp: now,
        temperatureTimestamp: now.subtract(const Duration(seconds: 2)),
        humidityTimestamp: now.subtract(const Duration(seconds: 45)),
        batteryTimestamp: now.subtract(const Duration(minutes: 5)),
        solarTimestamp: now.subtract(const Duration(hours: 2)),
      );

      expect(reading.tempUpdatedText, equals('Just now'));
      expect(reading.humidityUpdatedText, equals('45s ago'));
      expect(reading.batteryUpdatedText, equals('5m ago'));
      expect(reading.solarUpdatedText, equals('2h ago'));
    });

    test('Individual sensor fault flags activate ONLY when fault is present', () {
      // 1. Completely healthy reading
      final healthy = SensorReading(
        deviceId: 'TEST-01',
        temperature: 4.0,
        humidity: 90.0,
        battery: 80,
        solarPower: 1200,
        gridPower: true,
        doorOpen: false,
        pcmReserveHours: 20.0,
        waterLevel: 90,
        isOnline: true,
        timestamp: DateTime.now(),
      );

      expect(healthy.hasTemperatureFault, isFalse);
      expect(healthy.hasHumidityFault, isFalse);
      expect(healthy.hasBatteryFault, isFalse);
      expect(healthy.hasSolarFault, isFalse);
      expect(healthy.temperatureStatus, equals(StatusLevel.good));

      // 2. Reading with Temperature sensor fault ONLY
      final tempFault = healthy.copyWith(
        temperatureFaultReason: 'PT1000 probe wire disconnected',
      );

      expect(tempFault.hasTemperatureFault, isTrue);
      expect(tempFault.hasHumidityFault, isFalse);
      expect(tempFault.temperatureStatus, equals(StatusLevel.critical));
      expect(tempFault.temperatureExplanation,
          contains('PT1000 probe wire disconnected'));

      // 3. Reading with Humidity sensor fault ONLY
      final humidityFault = healthy.copyWith(
        humidityFaultReason: 'SHT35 I2C communication timeout',
      );

      expect(humidityFault.hasTemperatureFault, isFalse);
      expect(humidityFault.hasHumidityFault, isTrue);
      expect(humidityFault.humidityStatus, equals(StatusLevel.critical));
      expect(humidityFault.humidityExplanation,
          contains('SHT35 I2C communication timeout'));
    });

    test('ColdStorageUnit setpoints are configurable and preserve defaults', () {
      final unit = ColdStorageUnit(
        id: 'UNIT-01',
        name: 'Unit Alpha',
        village: 'Kalyanpur',
        district: 'Barabanki',
        capacityKg: 5000,
        currentOccupancyKg: 3200,
        primaryProduce: 'Tomato',
        recommendedAction: 'All conditions safe',
        reading: SensorReading(
          deviceId: 'DEV-01',
          temperature: 4.5,
          humidity: 90.0,
          battery: 80,
          solarPower: 1000,
          gridPower: true,
          doorOpen: false,
          pcmReserveHours: 15.0,
          waterLevel: 90,
          isOnline: true,
          timestamp: DateTime.now(),
        ),
      );

      // Verify default setpoints
      expect(unit.targetTemperature, equals(4.0));
      expect(unit.targetHumidity, equals(90.0));
      expect(unit.tempHysteresis, equals(0.5));
      expect(unit.isDefrostActive, isFalse);

      // Modify setpoints via copyWith
      final updated = unit.copyWith(
        targetTemperature: 8.0,
        targetHumidity: 95.0,
        tempHysteresis: 1.0,
        isDefrostActive: true,
      );

      expect(updated.targetTemperature, equals(8.0));
      expect(updated.targetHumidity, equals(95.0));
      expect(updated.tempHysteresis, equals(1.0));
      expect(updated.isDefrostActive, isTrue);
    });

    test('StorageUnitsNotifier setpoint updates and fault mutations work', () {
      final notifier = StorageUnitsNotifier();
      final unitId = notifier.state.first.id;

      // 1. Update setpoints
      notifier.updateUnitSetpoints(
        unitId,
        targetTemperature: 6.5,
        targetHumidity: 88.0,
        tempHysteresis: 0.8,
        isDefrostActive: true,
      );

      final modified = notifier.state.firstWhere((u) => u.id == unitId);
      expect(modified.targetTemperature, equals(6.5));
      expect(modified.targetHumidity, equals(88.0));
      expect(modified.tempHysteresis, equals(0.8));
      expect(modified.isDefrostActive, isTrue);

      // 2. Set temperature fault
      notifier.setSensorFault(
        unitId,
        tempFault: true,
        tempReason: 'Broken thermocouple probe',
      );

      final withFault = notifier.state.firstWhere((u) => u.id == unitId);
      expect(withFault.reading.hasTemperatureFault, isTrue);
      expect(withFault.reading.temperatureFaultReason,
          equals('Broken thermocouple probe'));

      // 3. Clear temperature fault
      notifier.setSensorFault(unitId, tempFault: false);
      final cleared = notifier.state.firstWhere((u) => u.id == unitId);
      expect(cleared.reading.hasTemperatureFault, isFalse);
    });
  });

  group('🖥️ UI Widget Diagnostics & Controls Tests', () {
    testWidgets('TelemetryCard displays FAULT badge ONLY when fault is present',
        (tester) async {
      // 1. Healthy Card
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TelemetryCard(
              title: 'Temperature',
              value: '4.2°C',
              status: StatusLevel.good,
              statusText: 'OPTIMAL',
              explanation: 'Ideal temperature zone',
              icon: Icons.thermostat_rounded,
              updatedTimeText: '2s ago',
              hasFault: false,
            ),
          ),
        ),
      );

      expect(find.text('FAULT'), findsNothing);
      expect(find.text('2s ago'), findsOneWidget);
      expect(find.text('OPTIMAL'), findsOneWidget);

      // 2. Fault Card
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TelemetryCard(
              title: 'Temperature',
              value: '4.2°C',
              status: StatusLevel.critical,
              statusText: 'FAULT',
              explanation: 'Ideal temperature zone',
              icon: Icons.thermostat_rounded,
              updatedTimeText: 'Just now',
              hasFault: true,
              faultMessage: 'Hardware probe disconnected',
            ),
          ),
        ),
      );

      expect(find.text('FAULT'), findsWidgets);
      expect(find.text('Hardware probe disconnected'), findsOneWidget);
    });

    testWidgets('FarmerSensorHealthCard shows Working Well vs Fault advice',
        (tester) async {
      final unit = ColdStorageUnit(
        id: 'UNIT-TEST',
        name: 'Chamber 1',
        village: 'Kalyanpur',
        district: 'Barabanki',
        capacityKg: 5000,
        currentOccupancyKg: 3200,
        primaryProduce: 'Tomato',
        recommendedAction: 'All conditions safe',
        reading: SensorReading(
          deviceId: 'DEV-01',
          temperature: 4.2,
          humidity: 90.0,
          battery: 80,
          solarPower: 1200,
          gridPower: true,
          doorOpen: false,
          pcmReserveHours: 20.0,
          waterLevel: 90,
          isOnline: true,
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FarmerSensorHealthCard(unit: unit),
            ),
          ),
        ),
      );

      expect(find.text('STORAGE SENSORS HEALTH'), findsOneWidget);
      expect(find.text('ALL WORKING WELL'), findsOneWidget);
      expect(find.text('WORKING WELL'), findsNWidgets(6));

      // With fault
      final faultyUnit = unit.copyWith(
        reading: unit.reading.copyWith(
          temperatureFaultReason: 'Probe plug disconnected at socket T1',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FarmerSensorHealthCard(unit: faultyUnit),
            ),
          ),
        ),
      );

      expect(find.text('FAULT DETECTED'), findsOneWidget);
      expect(find.text('FAULT'), findsOneWidget);
      expect(find.text('Probe plug disconnected at socket T1'), findsOneWidget);
      expect(find.text('Need Field Technician Assistance?'), findsOneWidget);
    });

    testWidgets('TechnicianHardwareCard renders technical specifications',
        (tester) async {
      final unit = ColdStorageUnit(
        id: 'UNIT-TEST',
        name: 'Chamber 1',
        village: 'Kalyanpur',
        district: 'Barabanki',
        capacityKg: 5000,
        currentOccupancyKg: 3200,
        primaryProduce: 'Tomato',
        recommendedAction: 'All conditions safe',
        reading: SensorReading(
          deviceId: 'DEV-01',
          temperature: 4.2,
          humidity: 90.0,
          battery: 80,
          solarPower: 1200,
          gridPower: true,
          doorOpen: false,
          pcmReserveHours: 20.0,
          waterLevel: 90,
          isOnline: true,
          timestamp: DateTime.now(),
        ),
      );

      const health = DeviceHealthStatus(
        controllerStatus: StatusLevel.good,
        controllerFirmware: 'v2.4.1-rc3',
        compressorStatus: StatusLevel.good,
        compressorHoursRun: 1420,
        tempSensorStatus: StatusLevel.good,
        humiditySensorStatus: StatusLevel.good,
        solarInverterStatus: StatusLevel.good,
        networkSignalRssi: -65,
        connectivityType: '4G LTE-M / NB-IoT',
        tempSensorModel: 'PT1000 Class A Platinum RTD (3-Wire)',
        tempBusInterface: 'ADS1115 ADC / 4-20mA Current Loop',
        tempRawVoltage: 1.652,
        tempResistanceOhms: 10380.0,
        tempCalibrationOffset: 0.12,
        humiditySensorModel: 'Sensirion SHT35-DIS Digital Sensor',
        humidityBusInterface: 'I2C Bus (Fast Mode 400kHz)',
        humidityI2cAddress: 0x44,
        compressorModel: 'Danfoss Secop BD350GH Variable Inverter',
        compressorFrequencyHz: 58.4,
        suctionPressurePsi: 28.5,
        dischargePressurePsi: 142.0,
        refrigerantType: 'R134a / 450g Charge',
        requiredServiceParts: [
          'SHT35 PTFE Filter Cap (Sensirion SF2)',
          'PT1000 M12 4-Pin IP68 Cable',
          '1/4" Flare Filter Drier Core',
        ],
        lastCalibrationDate: '2026-08-10',
        busErrorCount: 0,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TechnicianHardwareCard(unit: unit, health: health),
              ),
            ),
          ),
        ),
      );

      expect(find.text('HARDWARE & FIELD SERVICING SPEC'), findsOneWidget);
      expect(find.text('PT1000 Class A Platinum RTD (3-Wire)'), findsOneWidget);
      expect(find.text('Sensirion SHT35-DIS Digital Sensor'), findsOneWidget);
      expect(find.text('Danfoss Secop BD350GH Variable Inverter'), findsOneWidget);
      expect(find.text('1/4" Flare Filter Drier Core'), findsOneWidget);
      expect(find.text('Run Bus Test'), findsOneWidget);
      expect(find.text('Export Report'), findsOneWidget);
    });

    testWidgets('ChamberSetpointControlCard allows crop presets and adjustments',
        (tester) async {
      final unit = ColdStorageUnit(
        id: 'UNIT-TEST',
        name: 'Chamber 1',
        village: 'Kalyanpur',
        district: 'Barabanki',
        capacityKg: 5000,
        currentOccupancyKg: 3200,
        primaryProduce: 'Tomato',
        recommendedAction: 'All conditions safe',
        reading: SensorReading(
          deviceId: 'DEV-01',
          temperature: 4.2,
          humidity: 90.0,
          battery: 80,
          solarPower: 1200,
          gridPower: true,
          doorOpen: false,
          pcmReserveHours: 20.0,
          waterLevel: 90,
          isOnline: true,
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ChamberSetpointControlCard(
                  unit: unit,
                  isTechnicianMode: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('CHAMBER CONTROLS & SETPOINTS'), findsOneWidget);
      expect(find.text('Target Temperature'), findsOneWidget);
      expect(find.text('Target Humidity (RH)'), findsOneWidget);
      expect(find.text('🍅 Tomato'), findsOneWidget);
      expect(find.text('🥔 Potato'), findsOneWidget);
      expect(find.text('TECHNICIAN CALIBRATION OVERRIDES'), findsOneWidget);

      // Tap Potato preset
      await tester.tap(find.text('🥔 Potato'));
      await tester.pump();

      expect(find.text('8.0°C'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
      expect(find.text('UNSAVED'), findsOneWidget);
    });
  });
}
