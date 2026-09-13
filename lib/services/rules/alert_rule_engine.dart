import '../../models/cold_storage_unit.dart';
import '../../models/alert_item.dart';
import '../../models/status_level.dart';

class AlertRuleEngine {
  /// Evaluates a cold-storage unit against multi-sensor diagnostic rules
  /// and returns a list of active alerts.
  static List<AlertItem> evaluateUnit(ColdStorageUnit unit) {
    final alerts = <AlertItem>[];
    final reading = unit.reading;
    final now = DateTime.now();

    // Rule 1: Temperature High + Door Open (Critical)
    if (reading.temperature > 8.0 && reading.doorOpen) {
      alerts.add(
        AlertItem(
          id: 'ALT-${unit.id}-TEMP-DOOR',
          unitId: unit.id,
          unitName: unit.name,
          title: 'High Temperature & Door Open',
          severity: StatusLevel.critical,
          currentValue:
              '${reading.temperature.toStringAsFixed(1)}°C (Door OPEN)',
          expectedValue: '2.0°C - 8.0°C (Door CLOSED)',
          duration: '12 mins',
          possibleCause:
              'Storage chamber door has been left open, allowing hot outside air to rush in.',
          recommendedAction:
              'Check and securely close the storage door immediately to stop warm air ingress.',
          timestamp: now.subtract(const Duration(minutes: 12)),
        ),
      );
    }
    // Rule 2: Temperature High + Door Closed (Critical Compressor / Thermal Overload)
    else if (reading.temperature > 8.0 && !reading.doorOpen) {
      alerts.add(
        AlertItem(
          id: 'ALT-${unit.id}-TEMP-HIGH',
          unitId: unit.id,
          unitName: unit.name,
          title: 'Chamber Temperature Too High',
          severity: StatusLevel.critical,
          currentValue: '${reading.temperature.toStringAsFixed(1)}°C',
          expectedValue: '2.0°C - 8.0°C',
          duration: '25 mins',
          possibleCause:
              'Compressor overload, refrigerant pressure drop, or severe solar heat load on chamber exterior.',
          recommendedAction:
              'Inspect evaporator fan circulation, clean condenser coils, and check power supply to compressor.',
          timestamp: now.subtract(const Duration(minutes: 25)),
        ),
      );
    }

    // Rule 3: Chilling Injury Risk (Critical Low Temperature)
    if (reading.temperature < 0.5 && reading.isOnline) {
      alerts.add(
        AlertItem(
          id: 'ALT-${unit.id}-TEMP-FREEZE',
          unitId: unit.id,
          unitName: unit.name,
          title: 'Chilling / Freeze Injury Risk',
          severity: StatusLevel.critical,
          currentValue: '${reading.temperature.toStringAsFixed(1)}°C',
          expectedValue: 'Min 2.0°C',
          duration: '8 mins',
          possibleCause:
              'Thermostat miscalibration or compressor running continuously without cut-off.',
          recommendedAction:
              'Raise temperature setpoint immediately to prevent frost damage to sensitive produce.',
          timestamp: now.subtract(const Duration(minutes: 8)),
        ),
      );
    }

    // Rule 4: Grid Power Outage (Warning/Attention)
    if (!reading.gridPower && reading.isOnline) {
      alerts.add(
        AlertItem(
          id: 'ALT-${unit.id}-GRID-OUTAGE',
          unitId: unit.id,
          unitName: unit.name,
          title: 'Grid Power Outage (Backup Active)',
          severity: StatusLevel.attention,
          currentValue: 'Grid: OFF (0V AC)',
          expectedValue: 'Grid: ON (230V AC)',
          duration: '1 hr 15 mins',
          possibleCause: 'Local electrical grid disruption in ${unit.village}.',
          recommendedAction:
              'PCM Thermal Battery is maintaining cooling (${reading.formattedPcmHours} remaining). Avoid unnecessary door openings.',
          timestamp: now.subtract(const Duration(hours: 1, minutes: 15)),
        ),
      );
    }

    // Rule 5: Low Battery Backup (Warning/Critical)
    if (reading.battery < 20 && reading.isOnline) {
      final isCrit = reading.battery < 10;
      alerts.add(
        AlertItem(
          id: 'ALT-${unit.id}-BATTERY-LOW',
          unitId: unit.id,
          unitName: unit.name,
          title: isCrit ? 'Critical Battery Low' : 'Battery Backup Depleting',
          severity: isCrit ? StatusLevel.critical : StatusLevel.warning,
          currentValue: '${reading.battery}%',
          expectedValue: 'Min 40%',
          duration: '35 mins',
          possibleCause:
              'Prolonged cloudy weather reducing solar generation during grid outage.',
          recommendedAction:
              'Disconnect non-essential auxiliary lights and check solar panel surface for dust/debris.',
          timestamp: now.subtract(const Duration(minutes: 35)),
        ),
      );
    }

    // Rule 6: PCM Cold Reserve Depleting (Warning/Critical)
    if (reading.pcmReserveHours < 12.0 && reading.isOnline) {
      final isCrit = reading.pcmReserveHours < 4.0;
      alerts.add(
        AlertItem(
          id: 'ALT-${unit.id}-PCM-LOW',
          unitId: unit.id,
          unitName: unit.name,
          title: isCrit
              ? 'PCM Cold Backup Critically Depleted'
              : 'PCM Thermal Reserve Depleting',
          severity: isCrit ? StatusLevel.critical : StatusLevel.warning,
          currentValue: reading.formattedPcmHours,
          expectedValue: 'Min 24h 00m',
          duration: '45 mins',
          possibleCause:
              'Extended power outage without sufficient compressor recharging cycles.',
          recommendedAction:
              'Restore grid/generator power or prepare produce for expedited market dispatch.',
          timestamp: now.subtract(const Duration(minutes: 45)),
        ),
      );
    }

    // Rule 7: Low Humidifier Water Level (Attention)
    if (reading.waterLevel < 25 && reading.isOnline) {
      alerts.add(
        AlertItem(
          id: 'ALT-${unit.id}-WATER-LOW',
          unitId: unit.id,
          unitName: unit.name,
          title: 'Humidifier Water Tank Low',
          severity: StatusLevel.attention,
          currentValue: '${reading.waterLevel}%',
          expectedValue: 'Min 50%',
          duration: '2 hours',
          possibleCause:
              'Natural water consumption by chamber ultrasonic humidification system.',
          recommendedAction:
              'Refill humidifier reservoir with clean filtered/RO water to prevent produce weight loss.',
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
      );
    }

    // Rule 8: Offline Telemetry / GSM Loss (Critical/Offline)
    if (!reading.isOnline) {
      alerts.add(
        AlertItem(
          id: 'ALT-${unit.id}-OFFLINE',
          unitId: unit.id,
          unitName: unit.name,
          title: 'Storage Unit Offline',
          severity: StatusLevel.offline,
          currentValue: 'No Signal',
          expectedValue: '4G LTE Connected',
          duration: '3 hours',
          possibleCause:
              'GSM SIM network failure, loose antenna connector, or power interruption to ESP32 gateway.',
          recommendedAction:
              'Verify physical power to controller and check gateway SIM card status.',
          timestamp: now.subtract(const Duration(hours: 3)),
        ),
      );
    }

    return alerts;
  }

  /// Evaluates all storage units across the entire farm
  static List<AlertItem> evaluateAllUnits(List<ColdStorageUnit> units) {
    final allAlerts = <AlertItem>[];
    for (final unit in units) {
      allAlerts.addAll(evaluateUnit(unit));
    }
    return allAlerts;
  }
}
