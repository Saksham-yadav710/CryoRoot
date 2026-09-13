import 'dart:async';
import '../../models/sensor_reading.dart';
import '../../models/unit_connection_state.dart';
import 'telemetry_source.dart';
import 'mock_live_telemetry_source.dart';

/// Repository managing real-time telemetry streams, cached last-known readings,
/// and per-unit connection freshness monitoring (LIVE / STALE / OFFLINE).
class TelemetryRepository {
  final TelemetrySource _source;
  final Map<String, SensorReading> _lastKnownReadings = {};
  final Map<String, UnitConnectionState> _connectionStates = {};
  final Map<String, DateTime> _lastReceivedTimes = {};
  final Map<String, StreamSubscription<SensorReading>> _subscriptions = {};

  final StreamController<({String unitId, SensorReading reading})>
      _readingStreamController = StreamController.broadcast();
  final StreamController<({String unitId, UnitConnectionState state})>
      _connectionStreamController = StreamController.broadcast();

  Timer? _freshnessMonitorTimer;

  TelemetryRepository({TelemetrySource? source})
      : _source = source ?? MockLiveTelemetrySource() {
    _startFreshnessMonitoring();
  }

  TelemetrySource get source => _source;

  /// Register and start listening to telemetry for a unit.
  void registerUnit(String unitId, {SensorReading? initialReading}) {
    if (initialReading != null) {
      _lastKnownReadings[unitId] = initialReading;
      _lastReceivedTimes[unitId] = initialReading.timestamp;
      _connectionStates[unitId] = initialReading.isOnline
          ? UnitConnectionState.live
          : UnitConnectionState.offline;
    }

    _subscriptions[unitId]?.cancel();
    _subscriptions[unitId] =
        _source.getTelemetryStream(unitId).listen((newReading) {
      _handleIncomingReading(unitId, newReading);
    }, onError: (err) {
      _setConnectionState(unitId, UnitConnectionState.offline);
    });
  }

  void _handleIncomingReading(String unitId, SensorReading reading) {
    // Preserve last-known reading in memory
    _lastKnownReadings[unitId] = reading;
    _lastReceivedTimes[unitId] = reading.timestamp;

    // Immediately update connection state to LIVE
    _setConnectionState(unitId, UnitConnectionState.live);

    // Emit event for state subscribers
    if (!_readingStreamController.isClosed) {
      _readingStreamController.add((unitId: unitId, reading: reading));
    }
  }

  void _setConnectionState(String unitId, UnitConnectionState newState) {
    if (_connectionStates[unitId] != newState) {
      _connectionStates[unitId] = newState;
      if (!_connectionStreamController.isClosed) {
        _connectionStreamController.add((unitId: unitId, state: newState));
      }
    }
  }

  /// Freshness monitoring tick: evaluates packet freshness every 3 seconds.
  /// - < 15s: LIVE
  /// - 15s to 45s: STALE (CONNECTION SLOW)
  /// - > 45s: OFFLINE
  void _startFreshnessMonitoring() {
    _freshnessMonitorTimer?.cancel();
    _freshnessMonitorTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) {
      final now = DateTime.now();

      for (final unitId in _lastReceivedTimes.keys) {
        if (!_source.isConnected(unitId)) {
          _setConnectionState(unitId, UnitConnectionState.offline);
          continue;
        }

        final lastTime = _lastReceivedTimes[unitId];
        if (lastTime == null) {
          _setConnectionState(unitId, UnitConnectionState.offline);
          continue;
        }

        final age = now.difference(lastTime);
        if (age.inSeconds < 15) {
          _setConnectionState(unitId, UnitConnectionState.live);
        } else if (age.inSeconds < 45) {
          _setConnectionState(unitId, UnitConnectionState.stale);
        } else {
          _setConnectionState(unitId, UnitConnectionState.offline);
        }
      }
    });
  }

  /// Get the cached last known sensor reading for a unit (guaranteed non-null if initialized).
  SensorReading? getLastKnownReading(String unitId) {
    return _lastKnownReadings[unitId];
  }

  /// Get the current connection state of a unit (live, stale, or offline).
  UnitConnectionState getConnectionState(String unitId) {
    return _connectionStates[unitId] ?? UnitConnectionState.offline;
  }

  /// Get the exact timestamp when the last packet was received for a unit.
  DateTime? getLastReceivedTime(String unitId) {
    return _lastReceivedTimes[unitId];
  }

  /// Global stream of all incoming readings across units.
  Stream<({String unitId, SensorReading reading})> get readingStream =>
      _readingStreamController.stream;

  /// Global stream of connection status transitions across units.
  Stream<({String unitId, UnitConnectionState state})> get connectionStream =>
      _connectionStreamController.stream;

  /// Simulate disconnection for a specific unit (useful for testing & simulator).
  Future<void> simulateDisconnect(String unitId) async {
    await _source.disconnect(unitId);
    _setConnectionState(unitId, UnitConnectionState.offline);
  }

  /// Simulate reconnection for a specific unit.
  Future<void> simulateReconnect(String unitId) async {
    _setConnectionState(unitId, UnitConnectionState.syncing);
    await _source.connect(unitId);
  }

  /// Force immediate refresh across all units.
  void forceRefreshAll() {
    if (_source is MockLiveTelemetrySource) {
      for (final unitId in _lastKnownReadings.keys) {
        (_source as MockLiveTelemetrySource).forceRefresh(unitId);
      }
    }
  }

  void dispose() {
    _freshnessMonitorTimer?.cancel();
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _readingStreamController.close();
    _connectionStreamController.close();
    _source.dispose();
  }
}
