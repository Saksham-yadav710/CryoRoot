import 'package:flutter_test/flutter_test.dart';
import 'package:cryoroots/models/sensor_reading.dart';
import 'package:cryoroots/models/unit_connection_state.dart';
import 'package:cryoroots/models/status_level.dart';
import 'package:cryoroots/services/telemetry/mock_live_telemetry_source.dart';
import 'package:cryoroots/services/telemetry/telemetry_repository.dart';

void main() {
  group('🛰️ Live Telemetry & Connection Architecture Tests', () {
    late MockLiveTelemetrySource source;
    late TelemetryRepository repository;

    setUp(() {
      source = MockLiveTelemetrySource();
      repository = TelemetryRepository(source: source);
    });

    tearDown(() {
      repository.dispose();
    });

    test('TelemetrySource emits live streaming readings with realistic jitter',
        () async {
      final stream = source.getTelemetryStream('AC-NER-001');

      final firstReading = await stream.first;
      expect(firstReading.deviceId, equals('AC-DEV-001'));
      expect(firstReading.temperature, inInclusiveRange(3.8, 4.6));
      expect(firstReading.isOnline, isTrue);
    });

    test('TelemetryRepository preserves last known reading upon disconnection',
        () async {
      final initialReading = SensorReading(
        deviceId: 'AC-DEV-001',
        temperature: 4.2,
        humidity: 90.0,
        battery: 84,
        solarPower: 1850,
        gridPower: true,
        doorOpen: false,
        pcmReserveHours: 14.5,
        waterLevel: 85,
        isOnline: true,
        timestamp: DateTime.now(),
      );

      repository.registerUnit('AC-NER-001', initialReading: initialReading);

      // Verify initial state is LIVE
      expect(repository.getConnectionState('AC-NER-001'),
          equals(UnitConnectionState.live));
      expect(repository.getLastKnownReading('AC-NER-001')?.temperature,
          equals(4.2));

      // Simulate disconnection (Scenario 3 - Offline)
      await repository.simulateDisconnect('AC-NER-001');

      // Connection should be OFFLINE, but last known reading must NEVER be wiped or zeroed!
      expect(repository.getConnectionState('AC-NER-001'),
          equals(UnitConnectionState.offline));
      final lastKnown = repository.getLastKnownReading('AC-NER-001');
      expect(lastKnown, isNotNull);
      expect(lastKnown!.temperature, equals(4.2));
      expect(lastKnown.battery, equals(84));
      expect(lastKnown.pcmReserveHours, equals(14.5));
    });

    test('TelemetryRepository handles reconnection seamlessly (Scenario 4)',
        () async {
      final initialReading = SensorReading(
        deviceId: 'AC-DEV-002',
        temperature: 5.4,
        humidity: 88.0,
        battery: 52,
        solarPower: 310,
        gridPower: false,
        doorOpen: false,
        pcmReserveHours: 28.2,
        waterLevel: 78,
        isOnline: true,
        timestamp: DateTime.now(),
      );

      repository.registerUnit('AC-NER-002', initialReading: initialReading);
      await repository.simulateDisconnect('AC-NER-002');
      expect(repository.getConnectionState('AC-NER-002'),
          equals(UnitConnectionState.offline));

      // Reconnect
      await repository.simulateReconnect('AC-NER-002');

      // Should transition through SYNCING/LIVE and resume streaming
      final conn = repository.getConnectionState('AC-NER-002');
      expect(
          conn == UnitConnectionState.live ||
              conn == UnitConnectionState.syncing,
          isTrue);
    });

    test(
        'Unit isolation: One unit offline does NOT drag other units offline (Scenario 5)',
        () async {
      final reading1 = SensorReading(
        deviceId: 'AC-DEV-001',
        temperature: 4.2,
        humidity: 90.0,
        battery: 84,
        solarPower: 1850,
        gridPower: true,
        doorOpen: false,
        pcmReserveHours: 14.5,
        waterLevel: 85,
        isOnline: true,
        timestamp: DateTime.now(),
      );

      final reading2 = SensorReading(
        deviceId: 'AC-DEV-003',
        temperature: 10.5,
        humidity: 78.0,
        battery: 68,
        solarPower: 440,
        gridPower: true,
        doorOpen: true,
        pcmReserveHours: 16.5,
        waterLevel: 62,
        isOnline: true,
        timestamp: DateTime.now(),
      );

      repository.registerUnit('AC-NER-001', initialReading: reading1);
      repository.registerUnit('AC-NER-003', initialReading: reading2);

      // Disconnect only unit 3
      await repository.simulateDisconnect('AC-NER-003');

      // Unit 1 MUST remain LIVE while Unit 3 is OFFLINE
      expect(repository.getConnectionState('AC-NER-001'),
          equals(UnitConnectionState.live));
      expect(repository.getConnectionState('AC-NER-003'),
          equals(UnitConnectionState.offline));
    });

    test(
        'SensorReading displays graceful "--" fallback when a sensor is invalid (Requirement 14)',
        () {
      final incompleteReading = SensorReading(
        deviceId: 'AC-DEV-001',
        temperature: 4.2,
        humidity: 88.0,
        battery: 84,
        solarPower: 1850,
        gridPower: true,
        doorOpen: false,
        pcmReserveHours: 14.5,
        waterLevel: 85,
        isOnline: true,
        timestamp: DateTime.now(),
        isHumidityValid: false, // Humidity sensor failure
      );

      // Temperature is good
      expect(incompleteReading.displayTemperature, equals('4.2°C'));
      expect(incompleteReading.temperatureStatus, equals(StatusLevel.good));

      // Humidity shows fallback '--' with UNAVAILABLE status
      expect(incompleteReading.displayHumidity, equals('--'));
      expect(incompleteReading.humidityStatus, equals(StatusLevel.offline));
      expect(incompleteReading.humidityExplanation,
          equals('Humidity sensor unavailable'));
    });

    test(
        'UnitConnectionState human-friendly relative time formatter works accurately',
        () {
      final now = DateTime.now();

      expect(UnitConnectionState.formatRelativeTime(now), equals('just now'));
      expect(
          UnitConnectionState.formatRelativeTime(
              now.subtract(const Duration(seconds: 5))),
          equals('just now'));
      expect(
          UnitConnectionState.formatRelativeTime(
              now.subtract(const Duration(seconds: 25))),
          equals('25s ago'));
      expect(
          UnitConnectionState.formatRelativeTime(
              now.subtract(const Duration(minutes: 4))),
          equals('4m ago'));
      expect(
          UnitConnectionState.formatRelativeTime(
              now.subtract(const Duration(hours: 2))),
          equals('2h ago'));
    });
  });
}
