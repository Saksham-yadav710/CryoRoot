import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline/offline_sync_service.dart';
import '../services/mock/mock_storage_data.dart';
import '../services/mock/crop_profiles_data.dart';
import '../models/produce_batch.dart';

enum AppNetworkStatus {
  online,
  offline,
  syncing,
}

final appNetworkStatusProvider =
    StateProvider<AppNetworkStatus>((ref) => AppNetworkStatus.online);

final offlineCacheProvider =
    StateNotifierProvider<OfflineCacheNotifier, OfflineStorageCache>((ref) {
  final initialCache = OfflineStorageCache(
    lastCachedTime: DateTime.now(),
    cachedUnits: MockStorageData.getUnits(),
    cachedBatches: [
      ProduceBatch(
        batchId: 'AC-2026-00125',
        cropProfile: CropProfilesData.khasiMandarin,
        quantityKg: 1200,
        unitId: 'AC-NER-001',
        unitName: 'Cold Storage 1',
        entryDate: DateTime.now().subtract(const Duration(days: 8)),
      ),
      ProduceBatch(
        batchId: 'AC-2026-00126',
        cropProfile: CropProfilesData.getProfiles()
            .firstWhere((p) => p.id == 'CROP-TOMATO'),
        quantityKg: 2000,
        unitId: 'AC-NER-001',
        unitName: 'Cold Storage 1',
        entryDate: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ],
    cachedAlerts: MockStorageData.getInitialAlerts(),
  );

  return OfflineCacheNotifier(initialCache);
});

class OfflineCacheNotifier extends StateNotifier<OfflineStorageCache> {
  OfflineCacheNotifier(super.state);

  void queueAction(SyncActionType type, Map<String, dynamic> payload) {
    state.enqueueAction(type, payload);
    state = OfflineStorageCache(
      lastCachedTime: state.lastCachedTime,
      cachedUnits: state.cachedUnits,
      cachedBatches: state.cachedBatches,
      cachedAlerts: state.cachedAlerts,
      syncQueue: List.from(state.syncQueue),
    );
  }

  int syncAll() {
    final count = state.syncAllPending();
    state = OfflineStorageCache(
      lastCachedTime: DateTime.now(),
      cachedUnits: state.cachedUnits,
      cachedBatches: state.cachedBatches,
      cachedAlerts: state.cachedAlerts,
      syncQueue: List.from(state.syncQueue),
    );
    return count;
  }
}
