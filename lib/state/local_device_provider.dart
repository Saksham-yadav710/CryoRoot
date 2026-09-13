import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/local_device_info.dart';
import '../services/connectivity/local_device_sync_service.dart';
import 'storage_providers.dart';

final localDeviceSyncServiceProvider = Provider((ref) {
  return LocalDeviceSyncService();
});

final nearbyLocalDevicesProvider =
    StateNotifierProvider<NearbyLocalDevicesNotifier, List<LocalDeviceInfo>>(
        (ref) {
  return NearbyLocalDevicesNotifier(ref);
});

class NearbyLocalDevicesNotifier extends StateNotifier<List<LocalDeviceInfo>> {
  final Ref ref;

  NearbyLocalDevicesNotifier(this.ref) : super([]) {
    scanNearby();
  }

  Future<void> scanNearby() async {
    final service = ref.read(localDeviceSyncServiceProvider);
    final devices = await service.scanForNearbyChambers();
    state = devices;
  }

  Future<bool> connectAndSyncDevice(String unitId) async {
    final service = ref.read(localDeviceSyncServiceProvider);

    state = state.map((d) {
      if (d.unitId == unitId) {
        return d.copyWith(state: LocalDeviceState.syncing);
      }
      return d;
    }).toList();

    try {
      final device = state.firstWhere((d) => d.unitId == unitId);
      final units = ref.read(storageUnitsProvider);
      final targetUnit = units.firstWhere((u) => u.id == unitId);

      final updatedReading = await service.pullSensorTelemetryOffline(
        device: device,
        currentReading: targetUnit.reading,
      );

      // Ingest sensor reading directly into Riverpod store
      ref.read(storageUnitsProvider.notifier).updateSensorReading(
            unitId,
            updatedReading,
          );

      state = state.map((d) {
        if (d.unitId == unitId) {
          return d.copyWith(
            state: LocalDeviceState.connected,
            lastSyncedAt: DateTime.now(),
          );
        }
        return d;
      }).toList();

      return true;
    } catch (_) {
      state = state.map((d) {
        if (d.unitId == unitId) {
          return d.copyWith(state: LocalDeviceState.disconnected);
        }
        return d;
      }).toList();
      return false;
    }
  }
}

// Active Connected Device Provider
final activeConnectedDeviceProvider = Provider<LocalDeviceInfo?>((ref) {
  final devices = ref.watch(nearbyLocalDevicesProvider);
  final selectedUnitId = ref.watch(selectedUnitIdProvider);

  return devices.cast<LocalDeviceInfo?>().firstWhere(
        (d) => d?.unitId == selectedUnitId,
        orElse: () => devices.isNotEmpty ? devices.first : null,
      );
});
