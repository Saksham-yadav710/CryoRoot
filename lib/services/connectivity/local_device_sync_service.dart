import 'dart:async';
import 'dart:math';
import '../../models/local_device_info.dart';
import '../../models/sensor_reading.dart';

class LocalDeviceSyncService {
  /// Scans for nearby cold storage chambers broadcasting BLE packets or Local SoftAP Wi-Fi
  Future<List<LocalDeviceInfo>> scanForNearbyChambers() async {
    // Simulates instant offline radio discovery of nearby CryoRoots microcontrollers
    await Future.delayed(const Duration(milliseconds: 600));

    return [
      LocalDeviceInfo(
        unitId: 'AC-NER-001',
        unitName: 'CryoRoots Chamber 1',
        village: 'Sonapur, Kamrup Metro (Assam)',
        connectionType: LocalConnectionType.bluetoothBle,
        address: 'CR:8B:29:44:A1:01',
        signalRssi: -54,
        state: LocalDeviceState.connected,
        lastSyncedAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      LocalDeviceInfo(
        unitId: 'AC-NER-002',
        unitName: 'CryoRoots Chamber 2',
        village: 'Barapani, Ri-Bhoi (Meghalaya)',
        connectionType: LocalConnectionType.localWifiSoftAp,
        address: '192.168.4.1',
        signalRssi: -62,
        state: LocalDeviceState.disconnected,
        lastSyncedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      LocalDeviceInfo(
        unitId: 'AC-NER-003',
        unitName: 'CryoRoots Chamber 3',
        village: 'Sonitpur Orchard Unit (Assam)',
        connectionType: LocalConnectionType.bluetoothBle,
        address: 'CR:8B:29:44:A1:03',
        signalRssi: -78,
        state: LocalDeviceState.disconnected,
        lastSyncedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];
  }

  /// Pulls the latest raw JSON sensor payload from the hardware over Bluetooth or Local Wi-Fi
  Future<SensorReading> pullSensorTelemetryOffline({
    required LocalDeviceInfo device,
    required SensorReading currentReading,
  }) async {
    // Simulates zero-internet direct radio handshake (BLE GATT transfer or HTTP GET 192.168.4.1/telemetry)
    await Future.delayed(const Duration(milliseconds: 800));

    final random = Random();
    // Ingest simulated fresh hardware readings from chamber sensors
    final tempJitter = (random.nextDouble() * 0.4) - 0.2;
    final humidJitter = (random.nextDouble() * 1.5) - 0.7;

    final newTemp = (currentReading.temperature + tempJitter).clamp(-2.0, 35.0);
    final newHumidity =
        (currentReading.humidity + humidJitter).clamp(40.0, 99.0);

    return currentReading.copyWith(
      temperature: double.parse(newTemp.toStringAsFixed(1)),
      humidity: double.parse(newHumidity.toStringAsFixed(1)),
      timestamp: DateTime.now(),
      isOnline: true,
    );
  }
}
