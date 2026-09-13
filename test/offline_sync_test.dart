import 'package:flutter_test/flutter_test.dart';
import 'package:agricool_ner/services/offline/offline_sync_service.dart';
import 'package:agricool_ner/state/connectivity_provider.dart';

void main() {
  group('Offline Storage & Synchronization Queue Tests', () {
    test(
        'Offline cache initializes with cached telemetry and 0 pending actions',
        () {
      final notifier = OfflineCacheNotifier(
        OfflineStorageCache(
          lastCachedTime: DateTime.now(),
          cachedUnits: [],
          cachedBatches: [],
          cachedAlerts: [],
        ),
      );

      expect(notifier.state.pendingQueueCount, 0);
    });

    test('Queuing offline actions increases pendingQueueCount', () {
      final notifier = OfflineCacheNotifier(
        OfflineStorageCache(
          lastCachedTime: DateTime.now(),
          cachedUnits: [],
          cachedBatches: [],
          cachedAlerts: [],
        ),
      );

      notifier.queueAction(
        SyncActionType.addProduceBatch,
        {'batchId': 'AC-OFFLINE-001', 'crop': 'Tomato', 'quantity': 1500},
      );
      notifier.queueAction(
        SyncActionType.acknowledgeAlert,
        {'alertId': 'ALT-001', 'timestamp': DateTime.now().toIso8601String()},
      );

      expect(notifier.state.pendingQueueCount, 2);
      expect(
          notifier.state.syncQueue.first.type, SyncActionType.addProduceBatch);
      expect(notifier.state.syncQueue.first.isSynced, false);
    });

    test('Syncing all pending actions flushes queue and marks all as synced',
        () {
      final notifier = OfflineCacheNotifier(
        OfflineStorageCache(
          lastCachedTime: DateTime.now().subtract(const Duration(hours: 1)),
          cachedUnits: [],
          cachedBatches: [],
          cachedAlerts: [],
        ),
      );

      notifier.queueAction(
        SyncActionType.addProduceBatch,
        {'batchId': 'AC-OFFLINE-002'},
      );

      expect(notifier.state.pendingQueueCount, 1);

      final syncedCount = notifier.syncAll();

      expect(syncedCount, 1);
      expect(notifier.state.pendingQueueCount, 0);
      expect(notifier.state.syncQueue.first.isSynced, true);
    });
  });
}
