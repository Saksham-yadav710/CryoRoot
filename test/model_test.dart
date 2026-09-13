import 'package:flutter_test/flutter_test.dart';
import 'package:agricool_ner/models/sensor_reading.dart';
import 'package:agricool_ner/models/status_level.dart';
import 'package:agricool_ner/services/mock/mock_storage_data.dart';

void main() {
  group('SensorReading Status & Explanation Tests', () {
    test('Normal temperature evaluates to GOOD', () {
      final reading = SensorReading(
        deviceId: 'TEST-001',
        temperature: 4.2,
        humidity: 90.0,
        battery: 78,
        solarPower: 420,
        gridPower: true,
        doorOpen: false,
        pcmReserveHours: 41.5,
        waterLevel: 85,
        isOnline: true,
        timestamp: DateTime.now(),
      );

      expect(reading.temperatureStatus, StatusLevel.good);
      expect(reading.temperatureExplanation, 'Within recommended range');
      expect(reading.batteryStatus, StatusLevel.good);
      expect(reading.pcmStatus, StatusLevel.good);
      expect(reading.formattedPcmHours, '41h 30m');
      expect(reading.overallStatus, StatusLevel.good);
    });

    test('Critical temperature evaluates to CRITICAL', () {
      final reading = SensorReading(
        deviceId: 'TEST-002',
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

      expect(reading.temperatureStatus, StatusLevel.warning);
      expect(reading.doorOpen, true);
      expect(reading.overallStatus, StatusLevel.warning);
    });

    test('Grid power outage shows WARNING status and correct explanation', () {
      final reading = SensorReading(
        deviceId: 'TEST-003',
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

      expect(reading.gridStatus, StatusLevel.warning);
      expect(reading.gridExplanation, contains('Power outage'));
    });
  });

  group('MockStorageData Tests', () {
    test('Loads 3 initial cold-storage units with valid data', () {
      final units = MockStorageData.getUnits();
      expect(units.length, 3);
      expect(units[0].id, 'AC-NER-001');
      expect(units[0].name, 'Cold Storage 1');
      expect(units[0].reading.temperature, 4.2);
    });
  });
}
