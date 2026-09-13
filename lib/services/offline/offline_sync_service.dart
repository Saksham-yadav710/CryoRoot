import '../../models/cold_storage_unit.dart';
import '../../models/produce_batch.dart';
import '../../models/alert_item.dart';

enum SyncActionType {
  addProduceBatch,
  dispatchProduceBatch,
  acknowledgeAlert,
  updateUnitTelemetry,
}

class SyncQueueAction {
  final String id;
  final SyncActionType type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  bool isSynced;

  SyncQueueAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.timestamp,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'timestamp': timestamp.toIso8601String(),
        'isSynced': isSynced,
      };

  factory SyncQueueAction.fromJson(Map<String, dynamic> json) =>
      SyncQueueAction(
        id: json['id'] as String,
        type: SyncActionType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => SyncActionType.addProduceBatch,
        ),
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        timestamp: DateTime.parse(json['timestamp'] as String),
        isSynced: json['isSynced'] as bool? ?? false,
      );
}

class OfflineStorageCache {
  DateTime lastCachedTime;
  List<ColdStorageUnit> cachedUnits;
  List<ProduceBatch> cachedBatches;
  List<AlertItem> cachedAlerts;
  final List<SyncQueueAction> syncQueue;

  OfflineStorageCache({
    required this.lastCachedTime,
    required this.cachedUnits,
    required this.cachedBatches,
    required this.cachedAlerts,
    List<SyncQueueAction>? syncQueue,
  }) : syncQueue = syncQueue ?? [];

  int get pendingQueueCount => syncQueue.where((a) => !a.isSynced).length;

  void enqueueAction(SyncActionType type, Map<String, dynamic> payload) {
    syncQueue.add(
      SyncQueueAction(
        id: 'SYNC-${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        payload: payload,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Replays and flushes all pending offline queue items
  int syncAllPending() {
    int syncedCount = 0;
    for (final action in syncQueue) {
      if (!action.isSynced) {
        action.isSynced = true;
        syncedCount++;
      }
    }
    lastCachedTime = DateTime.now();
    return syncedCount;
  }
}
