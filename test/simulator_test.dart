import 'package:flutter_test/flutter_test.dart';
import 'package:agricool_ner/models/status_level.dart';
import 'package:agricool_ner/services/rules/alert_rule_engine.dart';
import 'package:agricool_ner/state/storage_providers.dart';

void main() {
  group('Hardware Simulator & Real-Time Telemetry Tests', () {
    test('Simulating High Temperature + Open Door triggers Critical Alert', () {
      final notifier = StorageUnitsNotifier();
      final initialUnit = notifier.state.first;

      expect(initialUnit.status, StatusLevel.good);

      // Simulate door opening and temperature rise
      final simulatedReading = initialUnit.reading.copyWith(
        temperature: 11.8,
        doorOpen: true,
        humidity: 72.0,
      );

      notifier.updateSensorReading(initialUnit.id, simulatedReading);

      final updatedUnit =
          notifier.state.firstWhere((u) => u.id == initialUnit.id);

      expect(updatedUnit.reading.temperature, 11.8);
      expect(updatedUnit.reading.doorOpen, true);
      expect(updatedUnit.status, StatusLevel.warning);

      final alerts = AlertRuleEngine.evaluateUnit(updatedUnit);
      expect(alerts.any((a) => a.title.contains('High Temperature & Door Open')), true);
      expect(alerts.any((a) => a.severity == StatusLevel.critical), true);
    });

    test('Simulating Grid Outage triggers PCM fallback warning', () {
      final notifier = StorageUnitsNotifier();
      final initialUnit = notifier.state.first;

      final simulatedReading = initialUnit.reading.copyWith(
        gridPower: false,
        solarPower: 0,
        pcmReserveHours: 18.0,
      );

      notifier.updateSensorReading(initialUnit.id, simulatedReading);

      final updatedUnit =
          notifier.state.firstWhere((u) => u.id == initialUnit.id);

      expect(updatedUnit.reading.gridPower, false);
      expect(updatedUnit.reading.gridStatus, StatusLevel.warning);

      final alerts = AlertRuleEngine.evaluateUnit(updatedUnit);
      expect(alerts.any((a) => a.title.contains('Grid Power Outage')), true);
    });

    test('Simulating Low Battery triggers Warning and battery conservation guidance', () {
      final notifier = StorageUnitsNotifier();
      final initialUnit = notifier.state.first;

      final simulatedReading = initialUnit.reading.copyWith(
        battery: 12,
        gridPower: false,
        solarPower: 50,
      );

      notifier.updateSensorReading(initialUnit.id, simulatedReading);

      final updatedUnit =
          notifier.state.firstWhere((u) => u.id == initialUnit.id);

      expect(updatedUnit.reading.battery, 12);
      expect(updatedUnit.reading.batteryStatus, StatusLevel.critical);

      final alerts = AlertRuleEngine.evaluateUnit(updatedUnit);
      expect(alerts.any((a) => a.title.contains('Battery Backup Depleting')), true);
    });

    test('Simulating Offline chamber marks unit as Offline', () {
      final notifier = StorageUnitsNotifier();
      final initialUnit = notifier.state.first;

      final simulatedReading = initialUnit.reading.copyWith(
        isOnline: false,
      );

      notifier.updateSensorReading(initialUnit.id, simulatedReading);

      final updatedUnit =
          notifier.state.firstWhere((u) => u.id == initialUnit.id);

      expect(updatedUnit.reading.isOnline, false);
      expect(updatedUnit.status, StatusLevel.offline);

      final alerts = AlertRuleEngine.evaluateUnit(updatedUnit);
      expect(alerts.any((a) => a.title.contains('Storage Unit Offline')), true);
    });
  });
}
