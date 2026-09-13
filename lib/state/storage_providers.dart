import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cold_storage_unit.dart';
import '../models/sensor_reading.dart';
import '../models/status_level.dart';
import '../models/alert_item.dart';
import '../models/storage_analytics.dart';
import '../services/mock/mock_storage_data.dart';
import '../services/rules/alert_rule_engine.dart';

// 1. Storage Units List Provider
final storageUnitsProvider =
    StateNotifierProvider<StorageUnitsNotifier, List<ColdStorageUnit>>((ref) {
  return StorageUnitsNotifier();
});

class StorageUnitsNotifier extends StateNotifier<List<ColdStorageUnit>> {
  StorageUnitsNotifier() : super(MockStorageData.getUnits());

  void updateUnitReading(String unitId, ColdStorageUnit updatedUnit) {
    state = [
      for (final unit in state)
        if (unit.id == unitId) updatedUnit else unit,
    ];
  }

  void updateSensorReading(String unitId, SensorReading newReading) {
    state = [
      for (final unit in state)
        if (unit.id == unitId)
          unit.copyWith(
            reading: newReading,
            hasActionRequired: newReading.overallStatus != StatusLevel.good,
          )
        else
          unit,
    ];
  }

  void refreshFromMock() {
    state = MockStorageData.getUnits();
  }
}

// 2. Selected Unit ID Provider (Defaults to Unit 1)
final selectedUnitIdProvider = StateProvider<String>((ref) {
  final units = ref.watch(storageUnitsProvider);
  return units.isNotEmpty ? units.first.id : 'AC-NER-001';
});

// 3. Selected Storage Unit Provider
final selectedUnitProvider = Provider<ColdStorageUnit?>((ref) {
  final units = ref.watch(storageUnitsProvider);
  final selectedId = ref.watch(selectedUnitIdProvider);

  return units.firstWhere(
    (unit) => unit.id == selectedId,
    orElse: () =>
        units.isNotEmpty ? units.first : MockStorageData.getUnits().first,
  );
});

// 4. Overall Health Summary Model & Provider
class OverallSystemSummary {
  final int totalUnits;
  final int safeUnits;
  final int attentionUnits;
  final int criticalUnits;

  const OverallSystemSummary({
    required this.totalUnits,
    required this.safeUnits,
    required this.attentionUnits,
    required this.criticalUnits,
  });

  bool get allSafe => safeUnits == totalUnits && totalUnits > 0;

  String get summaryHeadline {
    if (allSafe) {
      return '$totalUnits Units / $safeUnits Safe';
    }
    final problematic = attentionUnits + criticalUnits;
    return '$safeUnits Safe / $problematic Needs Attention';
  }
}

final overallSummaryProvider = Provider<OverallSystemSummary>((ref) {
  final units = ref.watch(storageUnitsProvider);
  int safe = 0;
  int attention = 0;
  int critical = 0;

  for (final unit in units) {
    if (unit.status == StatusLevel.good) {
      safe++;
    } else if (unit.status == StatusLevel.attention) {
      attention++;
    } else {
      critical++;
    }
  }

  return OverallSystemSummary(
    totalUnits: units.length,
    safeUnits: safe,
    attentionUnits: attention,
    criticalUnits: critical,
  );
});

// 5. Unit Analytics Provider (Family provider for any unit)
final unitAnalyticsProvider =
    Provider.family<StorageAnalytics, String>((ref, unitId) {
  return MockStorageData.getAnalyticsForUnit(unitId);
});

final selectedUnitAnalyticsProvider = Provider<StorageAnalytics>((ref) {
  final selectedId = ref.watch(selectedUnitIdProvider);
  return ref.watch(unitAnalyticsProvider(selectedId));
});

// 6. Audio Playback State Provider
final isAudioPlayingProvider = StateProvider<bool>((ref) => false);


// 8. Active Alerts Provider (Evaluated through AlertRuleEngine)
final activeAlertsProvider =
    StateNotifierProvider<AlertsNotifier, List<AlertItem>>((ref) {
  final units = ref.watch(storageUnitsProvider);
  return AlertsNotifier(ref, units);
});

class AlertsNotifier extends StateNotifier<List<AlertItem>> {
  final Ref _ref;
  final Set<String> _acknowledgedIds = {};

  AlertsNotifier(Ref ref, List<ColdStorageUnit> units)
      : _ref = ref,
        super(AlertRuleEngine.evaluateAllUnits(units)) {
    // Re-evaluate alerts whenever storage units update
    _ref.listen<List<ColdStorageUnit>>(storageUnitsProvider, (_, newUnits) {
      updateUnits(newUnits);
    });
  }

  void updateUnits(List<ColdStorageUnit> units) {
    final generated = AlertRuleEngine.evaluateAllUnits(units);
    state = generated.map((a) {
      if (_acknowledgedIds.contains(a.id)) {
        return a.copyWith(isAcknowledged: true);
      }
      return a;
    }).toList();
  }

  void acknowledgeAlert(String alertId) {
    _acknowledgedIds.add(alertId);
    state = [
      for (final a in state)
        if (a.id == alertId) a.copyWith(isAcknowledged: true) else a,
    ];
  }
}

// 9. Alert Filter Providers
final alertSeverityFilterProvider = StateProvider<StatusLevel?>((ref) => null);
final alertUnitFilterProvider = StateProvider<String?>((ref) => null);

final filteredAlertsProvider = Provider<List<AlertItem>>((ref) {
  final alerts = ref.watch(activeAlertsProvider);
  final severityFilter = ref.watch(alertSeverityFilterProvider);
  final unitFilter = ref.watch(alertUnitFilterProvider);

  return alerts.where((alert) {
    if (severityFilter != null && alert.severity != severityFilter) {
      return false;
    }
    if (unitFilter != null && alert.unitId != unitFilter) {
      return false;
    }
    return true;
  }).toList();
});

// 10. Alert Severity Counts Provider
class AlertSeverityCounts {
  final int total;
  final int critical;
  final int warning;
  final int attention;
  final int unacknowledged;

  const AlertSeverityCounts({
    required this.total,
    required this.critical,
    required this.warning,
    required this.attention,
    required this.unacknowledged,
  });
}

final alertCountsProvider = Provider<AlertSeverityCounts>((ref) {
  final alerts = ref.watch(activeAlertsProvider);
  int crit = 0;
  int warn = 0;
  int att = 0;
  int unack = 0;

  for (final a in alerts) {
    if (!a.isAcknowledged) unack++;
    if (a.severity == StatusLevel.critical) {
      crit++;
    } else if (a.severity == StatusLevel.warning) {
      warn++;
    } else if (a.severity == StatusLevel.attention) {
      att++;
    }
  }

  return AlertSeverityCounts(
    total: alerts.length,
    critical: crit,
    warning: warn,
    attention: att,
    unacknowledged: unack,
  );
});
