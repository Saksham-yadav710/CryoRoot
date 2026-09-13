import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryoroots/models/local_device_info.dart';
import 'package:cryoroots/state/local_device_provider.dart';
import 'package:cryoroots/state/storage_providers.dart';

void main() {
  group('Offline Bluetooth & Local Wi-Fi Direct Sync Tests', () {
    test('Scans for nearby cold storage chambers broadcasting BLE or Wi-Fi AP',
        () async {
      final container = ProviderContainer();
      final notifier = container.read(nearbyLocalDevicesProvider.notifier);

      await notifier.scanNearby();
      final devices = container.read(nearbyLocalDevicesProvider);

      expect(devices.length, equals(3));
      expect(
          devices
              .any((d) => d.connectionType == LocalConnectionType.bluetoothBle),
          isTrue);
      expect(
          devices.any(
              (d) => d.connectionType == LocalConnectionType.localWifiSoftAp),
          isTrue);
    });

    test(
        'Syncs sensor telemetry directly over offline protocol into Riverpod state',
        () async {
      final container = ProviderContainer();
      final notifier = container.read(nearbyLocalDevicesProvider.notifier);

      await notifier.scanNearby();

      final initialReading = container
          .read(storageUnitsProvider)
          .firstWhere((u) => u.id == 'AC-NER-001')
          .reading;

      final success = await notifier.connectAndSyncDevice('AC-NER-001');

      expect(success, isTrue);

      final updatedReading = container
          .read(storageUnitsProvider)
          .firstWhere((u) => u.id == 'AC-NER-001')
          .reading;

      expect(updatedReading.isOnline, isTrue);
      expect(
          updatedReading.timestamp.isAfter(initialReading.timestamp) ||
              updatedReading.timestamp == initialReading.timestamp,
          isTrue);
    });
  });
}
