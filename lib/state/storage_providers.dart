import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cold_storage_unit.dart';
import '../models/sensor_reading.dart';
import '../models/status_level.dart';
import '../models/alert_item.dart';
import '../models/storage_analytics.dart';
import '../models/unit_connection_state.dart';
import '../models/app_user.dart';
import '../services/mock/mock_storage_data.dart';
import '../services/rules/alert_rule_engine.dart';
import '../services/security/storage_security_engine.dart';
import '../services/telemetry/telemetry_repository.dart';

// 0. Telemetry Repository Provider (Hardware-Independent Ingestion & Freshness Engine)
final telemetryRepositoryProvider = Provider<TelemetryRepository>((ref) {
  final repo = TelemetryRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

// 1. Storage Units List Provider (Updated reactively by TelemetryRepository stream)
final storageUnitsProvider =
    StateNotifierProvider<StorageUnitsNotifier, List<ColdStorageUnit>>((ref) {
  final repo = ref.watch(telemetryRepositoryProvider);
  return StorageUnitsNotifier(repo);
});

class StorageUnitsNotifier extends StateNotifier<List<ColdStorageUnit>> {
  final TelemetryRepository? _repo;
  StreamSubscription? _readingSub;

  StorageUnitsNotifier([this._repo]) : super(MockStorageData.getUnits()) {
    final repo = _repo;
    if (repo != null) {
      for (final unit in state) {
        repo.registerUnit(unit.id, initialReading: unit.reading);
      }
      _readingSub = repo.readingStream.listen((event) {
        updateSensorReading(event.unitId, event.reading);
      });
    }
  }

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

  Future<void> simulateDisconnect(String unitId) async {
    await _repo?.simulateDisconnect(unitId);
    final current =
        state.firstWhere((u) => u.id == unitId, orElse: () => state.first);
    updateSensorReading(unitId, current.reading.copyWith(isOnline: false));
  }

  Future<void> simulateReconnect(String unitId) async {
    await _repo?.simulateReconnect(unitId);
    final current =
        state.firstWhere((u) => u.id == unitId, orElse: () => state.first);
    updateSensorReading(
      unitId,
      current.reading.copyWith(isOnline: true, timestamp: DateTime.now()),
    );
  }

  bool updateUnitSetpoints(
    String unitId, {
    AppUser? caller,
    bool isTechnicianPanelAuth = false,
    double? targetTemperature,
    double? targetHumidity,
    double? tempHysteresis,
    bool? isDefrostActive,
  }) {
    final unitIndex = state.indexWhere((u) => u.id == unitId);
    if (unitIndex == -1) return false;

    final targetUnit = state[unitIndex];

    // If caller is provided, strictly enforce security engine access
    if (caller != null &&
        !StorageSecurityEngine.canControlSetpoints(targetUnit, caller,
            isTechnicianPanelAuth: isTechnicianPanelAuth)) {
      return false;
    }

    state = [
      for (final unit in state)
        if (unit.id == unitId)
          unit.copyWith(
            targetTemperature: targetTemperature ?? unit.targetTemperature,
            targetHumidity: targetHumidity ?? unit.targetHumidity,
            tempHysteresis: tempHysteresis ?? unit.tempHysteresis,
            isDefrostActive: isDefrostActive ?? unit.isDefrostActive,
          )
        else
          unit,
    ];
    return true;
  }

  bool toggleTechnicianAccess(
    String unitId, {
    required AppUser caller,
    required bool grantAccess,
  }) {
    final unitIndex = state.indexWhere((u) => u.id == unitId);
    if (unitIndex == -1) return false;

    final targetUnit = state[unitIndex];

    // Only the registered owner farmer can grant or revoke technician access
    if (!StorageSecurityEngine.canToggleTechnicianAccess(targetUnit, caller)) {
      return false;
    }

    state = [
      for (final unit in state)
        if (unit.id == unitId)
          unit.copyWith(
            isTechnicianAccessGranted: grantAccess,
            technicianAccessGrantedAt: grantAccess ? DateTime.now() : null,
          )
        else
          unit,
    ];
    return true;
  }

  void setSensorFault(
    String unitId, {
    bool? tempFault,
    String? tempReason,
    bool? humidityFault,
    String? humidityReason,
    bool? batteryFault,
    String? batteryReason,
    bool? solarFault,
    String? solarReason,
  }) {
    state = [
      for (final unit in state)
        if (unit.id == unitId)
          unit.copyWith(
            reading: unit.reading.copyWith(
              clearTemperatureFault: tempFault == false,
              temperatureFaultReason: tempFault == true
                  ? (tempReason ?? 'Hardware probe fault')
                  : null,
              clearHumidityFault: humidityFault == false,
              humidityFaultReason: humidityFault == true
                  ? (humidityReason ?? 'I2C communication error')
                  : null,
              clearBatteryFault: batteryFault == false,
              batteryFaultReason: batteryFault == true
                  ? (batteryReason ?? 'BMS telemetry fault')
                  : null,
              clearSolarFault: solarFault == false,
              solarFaultReason: solarFault == true
                  ? (solarReason ?? 'Inverter MPPT comms lost')
                  : null,
            ),
          )
        else
          unit,
    ];
  }

  void refreshFromMock() {
    state = MockStorageData.getUnits();
    _repo?.forceRefreshAll();
  }

  @override
  void dispose() {
    _readingSub?.cancel();
    super.dispose();
  }
}

// 2. Selected Unit ID Provider (Defaults to Unit 1, persists user selection across telemetry updates)
final selectedUnitIdProvider = StateProvider<String>((ref) {
  final units = ref.read(storageUnitsProvider);
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

// 3b. Per-Unit Connection State Provider (Live / Stale / Offline)
final unitConnectionStateStreamProvider =
    StreamProvider.family<UnitConnectionState, String>((ref, unitId) {
  final repo = ref.watch(telemetryRepositoryProvider);
  return repo.connectionStream
      .where((e) => e.unitId == unitId)
      .map((e) => e.state);
});

final unitConnectionStateProvider =
    Provider.family<UnitConnectionState, String>((ref, unitId) {
  final streamState = ref.watch(unitConnectionStateStreamProvider(unitId));
  final repo = ref.watch(telemetryRepositoryProvider);
  final directState = repo.getConnectionState(unitId);
  return streamState.value ?? directState;
});

// 3c. Relative Time Ticker (Ticks every 1s to update human freshness: "just now", "12s ago")
final relativeTimeTickProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) => i);
});

final unitFreshnessTextProvider =
    Provider.family<String, String>((ref, unitId) {
  ref.watch(relativeTimeTickProvider);
  final units = ref.watch(storageUnitsProvider);
  final unit = units.firstWhere(
    (u) => u.id == unitId,
    orElse: () => units.first,
  );
  return 'Last updated ${UnitConnectionState.formatRelativeTime(unit.reading.timestamp)}';
});

// 4. Overall Health & Connectivity Summary Model & Provider
class OverallSystemSummary {
  final int totalUnits;
  final int safeUnits;
  final int attentionUnits;
  final int criticalUnits;
  final int liveUnits;
  final int offlineUnits;

  const OverallSystemSummary({
    required this.totalUnits,
    required this.safeUnits,
    required this.attentionUnits,
    required this.criticalUnits,
    required this.liveUnits,
    required this.offlineUnits,
  });

  bool get allSafe => safeUnits == totalUnits && totalUnits > 0;
  bool get allLive => liveUnits == totalUnits && totalUnits > 0;

  String get summaryHeadline {
    if (allSafe && allLive) {
      return '$totalUnits Units / $safeUnits Safe';
    } else if (allSafe && !allLive) {
      return '$safeUnits Safe • $offlineUnits Offline';
    }
    final problematic = attentionUnits + criticalUnits;
    if (offlineUnits > 0) {
      return '$safeUnits Safe / $problematic Needs Attention ($offlineUnits Offline)';
    }
    return '$safeUnits Safe / $problematic Needs Attention';
  }

  String get connectivitySummary {
    return '$liveUnits Live • $offlineUnits Offline';
  }
}

final overallSummaryProvider = Provider<OverallSystemSummary>((ref) {
  final units = ref.watch(storageUnitsProvider);
  final repo = ref.watch(telemetryRepositoryProvider);
  int safe = 0;
  int attention = 0;
  int critical = 0;
  int live = 0;
  int offline = 0;

  for (final unit in units) {
    final conn = repo.getConnectionState(unit.id);
    if (conn == UnitConnectionState.live || conn == UnitConnectionState.stale) {
      live++;
    } else {
      offline++;
    }

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
    liveUnits: live,
    offlineUnits: offline,
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

// 8. Active Alerts Provider (Evaluated through AlertRuleEngine, listens internally to preserve acknowledgments)
final activeAlertsProvider =
    StateNotifierProvider<AlertsNotifier, List<AlertItem>>((ref) {
  final units = ref.read(storageUnitsProvider);
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
