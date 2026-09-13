import '../../models/sensor_reading.dart';

/// Abstract hardware-independent contract for telemetry ingestion.
///
/// Can be backed by:
/// - [MockLiveTelemetrySource] (Simulated live stream for demo/testing)
/// - [BleTelemetrySource] (Direct Bluetooth Low Energy hardware stream)
/// - [WifiSoftApTelemetrySource] (Local ESP32 HTTP/WebSocket server)
/// - [MqttTelemetrySource] (Cloud/Broker IoT MQTT telemetry)
abstract class TelemetrySource {
  /// Continuous real-time stream of sensor readings for a specific storage unit.
  Stream<SensorReading> getTelemetryStream(String unitId);

  /// Establish or activate telemetry connection for a storage unit.
  Future<void> connect(String unitId);

  /// Disconnect or suspend telemetry for a storage unit (e.g. simulate offline).
  Future<void> disconnect(String unitId);

  /// Query whether the telemetry source is currently connected for a unit.
  bool isConnected(String unitId);

  /// Dispose any active streams, timers, or hardware handles.
  void dispose();
}
