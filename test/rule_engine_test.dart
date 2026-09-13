import 'package:flutter_test/flutter_test.dart';
import 'package:cryoroots/models/cold_storage_unit.dart';
import 'package:cryoroots/models/sensor_reading.dart';
import 'package:cryoroots/models/status_level.dart';
import 'package:cryoroots/services/rules/alert_rule_engine.dart';
import 'package:cryoroots/services/mock/mock_storage_data.dart';

void main() {
  group('AlertRuleEngine Diagnostics & Rules Tests', () {
    test('Evaluates High Temp + Open Door as CRITICAL with door closure action',
        () {
      final unit = ColdStorageUnit(
        id: 'TEST-001',
        name: 'Chamber 1',
        village: 'Village A',
        district: 'Sonitpur',
        capacityKg: 5000,
        currentOccupancyKg: 2000,
        primaryProduce: 'Tomato',
        recommendedAction: 'Check door',
        reading: SensorReading(
          deviceId: 'DEV-001',
          temperature: 10.5,
          humidity: 80.0,
          battery: 75,
          solarPower: 400,
          gridPower: true,
          doorOpen: true, // Open door!
          pcmReserveHours: 35.0,
          waterLevel: 80,
          isOnline: true,
          timestamp: DateTime.now(),
        ),
      );

      final alerts = AlertRuleEngine.evaluateUnit(unit);
      expect(alerts.any((a) => a.severity == StatusLevel.critical), true);

      final doorAlert = alerts.firstWhere((a) => a.title.contains('Door Open'));
      expect(doorAlert.possibleCause, contains('door has been left open'));
      expect(doorAlert.recommendedAction, contains('close the storage door'));
    });

    test('Evaluates Grid Outage as Attention/Warning with PCM backup guidance',
        () {
      final unit = ColdStorageUnit(
        id: 'TEST-002',
        name: 'Chamber 2',
        village: 'Village B',
        district: 'Kamrup',
        capacityKg: 3000,
        currentOccupancyKg: 1500,
        primaryProduce: 'Cabbage',
        recommendedAction: 'Grid outage',
        reading: SensorReading(
          deviceId: 'DEV-002',
          temperature: 4.5,
          humidity: 90.0,
          battery: 55,
          solarPower: 250,
          gridPower: false, // Power Outage
          doorOpen: false,
          pcmReserveHours: 28.0,
          waterLevel: 75,
          isOnline: true,
          timestamp: DateTime.now(),
        ),
      );

      final alerts = AlertRuleEngine.evaluateUnit(unit);
      expect(alerts.any((a) => a.title.contains('Grid Power Outage')), true);

      final outageAlert =
          alerts.firstWhere((a) => a.title.contains('Grid Power Outage'));
      expect(outageAlert.recommendedAction, contains('PCM Thermal Battery'));
    });

    test('Evaluates Low PCM Cold Reserve as CRITICAL when below 4 hours', () {
      final unit = ColdStorageUnit(
        id: 'TEST-003',
        name: 'Chamber 3',
        village: 'Village C',
        district: 'Nagaon',
        capacityKg: 4000,
        currentOccupancyKg: 1200,
        primaryProduce: 'Orange',
        recommendedAction: 'PCM low',
        reading: SensorReading(
          deviceId: 'DEV-003',
          temperature: 6.0,
          humidity: 85.0,
          battery: 40,
          solarPower: 200,
          gridPower: false,
          doorOpen: false,
          pcmReserveHours: 3.5, // Critical (<4h)
          waterLevel: 70,
          isOnline: true,
          timestamp: DateTime.now(),
        ),
      );

      final alerts = AlertRuleEngine.evaluateUnit(unit);
      expect(
          alerts.any((a) =>
              a.title.contains('PCM') && a.severity == StatusLevel.critical),
          true);
    });

    test('Evaluates all initial mock units across the farm', () {
      final units = MockStorageData.getUnits();
      final allAlerts = AlertRuleEngine.evaluateAllUnits(units);

      expect(allAlerts.length, greaterThanOrEqualTo(2));
      expect(allAlerts.any((a) => a.unitId == 'AC-NER-003'), true);
      expect(allAlerts.any((a) => a.unitId == 'AC-NER-002'), true);
    });
  });
}
