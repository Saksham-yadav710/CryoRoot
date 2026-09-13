import 'dart:async';
import 'dart:math';
import '../../models/sensor_reading.dart';
import '../mock/mock_storage_data.dart';
import 'telemetry_source.dart';

/// Simulated live telemetry source producing realistic real-time micro-fluctuations.
///
/// Designed to be replaced with BLE, Wi-Fi SoftAP, MQTT, or HTTP polling
/// without altering the application state or UI layer.
class MockLiveTelemetrySource implements TelemetrySource {
  final Map<String, StreamController<SensorReading>> _controllers = {};
  final Map<String, bool> _connectionStates = {};
  final Map<String, SensorReading> _currentReadings = {};
  final Map<String, Timer> _updateTimers = {};
  final Random _random = Random();

  MockLiveTelemetrySource() {
    _initializeUnits();
  }

  void _initializeUnits() {
    final initialUnits = MockStorageData.getUnits();
    for (final unit in initialUnits) {
      _connectionStates[unit.id] = true;
      _currentReadings[unit.id] = unit.reading;
      _controllers[unit.id] = StreamController<SensorReading>.broadcast();
      _startEmitting(unit.id);
    }
  }

  void _startEmitting(String unitId) {
    _updateTimers[unitId]?.cancel();
    _updateTimers[unitId] = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!(_connectionStates[unitId] ?? false)) {
        return; // Unit is currently offline / disconnected
      }

      final current = _currentReadings[unitId];
      if (current == null) return;

      // Generate realistic micro-fluctuations
      final nextReading = _generateNextReading(unitId, current);
      _currentReadings[unitId] = nextReading;

      final controller = _controllers[unitId];
      if (controller != null && !controller.isClosed) {
        controller.add(nextReading);
      }
    });
  }

  SensorReading _generateNextReading(String unitId, SensorReading prev) {
    final now = DateTime.now();

    if (unitId == 'AC-NER-003') {
      // Unit 3: Simulates open door & elevated temperature alert state
      final tempJitter = (_random.nextDouble() * 0.2) - 0.1; // ±0.1°C
      final newTemp = (prev.temperature + tempJitter).clamp(10.0, 11.2);
      final humidityJitter = (_random.nextDouble() * 1.0) - 0.5;
      final newHumidity = (prev.humidity + humidityJitter).clamp(75.0, 82.0);

      return prev.copyWith(
        temperature: double.parse(newTemp.toStringAsFixed(1)),
        humidity: double.parse(newHumidity.toStringAsFixed(1)),
        timestamp: now,
        isOnline: true,
      );
    } else if (unitId == 'AC-NER-002') {
      // Unit 2: Outage state, running on PCM & Solar
      final tempJitter = (_random.nextDouble() * 0.1) - 0.05;
      final newTemp = (prev.temperature + tempJitter).clamp(5.0, 5.8);
      final pcmCountdown =
          max(0.0, prev.pcmReserveHours - 0.001); // Draining slowly

      return prev.copyWith(
        temperature: double.parse(newTemp.toStringAsFixed(1)),
        pcmReserveHours: double.parse(pcmCountdown.toStringAsFixed(2)),
        timestamp: now,
        isOnline: true,
      );
    } else {
      // Unit 1: Normal optimal safe operating conditions (Scenario 1)
      // Ideal 4.2°C baseline with micro-fluctuations (4.1°C - 4.3°C)
      final tempJitter = (_random.nextDouble() * 0.1) - 0.05;
      final newTemp = (prev.temperature + tempJitter).clamp(4.1, 4.3);
      final humidityJitter = (_random.nextDouble() * 0.6) - 0.3;
      final newHumidity = (prev.humidity + humidityJitter).clamp(88.0, 92.0);

      // Solar irradiance fluctuations (400W - 1850W active range)
      final solarJitter = _random.nextInt(31) - 15;
      final newSolar = (prev.solarPower + solarJitter).clamp(400, 1900);

      return prev.copyWith(
        temperature: double.parse(newTemp.toStringAsFixed(1)),
        humidity: double.parse(newHumidity.toStringAsFixed(1)),
        solarPower: newSolar,
        timestamp: now,
        isOnline: true,
      );
    }
  }

  @override
  Stream<SensorReading> getTelemetryStream(String unitId) {
    if (!_controllers.containsKey(unitId)) {
      _controllers[unitId] = StreamController<SensorReading>.broadcast();
      _connectionStates[unitId] = true;
      _startEmitting(unitId);
    }

    final controller = _controllers[unitId]!;

    // Emit the current reading immediately upon listen if available
    final current = _currentReadings[unitId];
    if (current != null && (_connectionStates[unitId] ?? false)) {
      scheduleMicrotask(() {
        if (!controller.isClosed) {
          controller.add(current);
        }
      });
    }

    return controller.stream;
  }

  @override
  Future<void> connect(String unitId) async {
    _connectionStates[unitId] = true;
    final current = _currentReadings[unitId];
    if (current != null) {
      final updated = current.copyWith(
        isOnline: true,
        timestamp: DateTime.now(),
      );
      _currentReadings[unitId] = updated;
      _controllers[unitId]?.add(updated);
    }
    _startEmitting(unitId);
  }

  @override
  Future<void> disconnect(String unitId) async {
    _connectionStates[unitId] = false;
    _updateTimers[unitId]?.cancel();
    // Do not emit null or blank readings; last known reading is preserved in _currentReadings!
  }

  @override
  bool isConnected(String unitId) {
    return _connectionStates[unitId] ?? false;
  }

  /// Inject custom reading directly (useful for testing or simulator sliders)
  void injectReading(String unitId, SensorReading reading) {
    _currentReadings[unitId] = reading;
    _connectionStates[unitId] = reading.isOnline;
    if (reading.isOnline) {
      _controllers[unitId]?.add(reading);
    }
  }

  /// Manually force a reading push (e.g. on manual pull-to-refresh)
  void forceRefresh(String unitId) {
    final current = _currentReadings[unitId];
    if (current != null && (_connectionStates[unitId] ?? false)) {
      final refreshed = current.copyWith(timestamp: DateTime.now());
      _currentReadings[unitId] = refreshed;
      _controllers[unitId]?.add(refreshed);
    }
  }

  @override
  void dispose() {
    for (final timer in _updateTimers.values) {
      timer.cancel();
    }
    _updateTimers.clear();

    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}
