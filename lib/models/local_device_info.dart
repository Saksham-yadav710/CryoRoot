enum LocalConnectionType {
  bluetoothBle(
    label: 'Bluetooth BLE',
    description: 'Auto-sync within 15-30m range (Zero Internet)',
    iconEmoji: '🔵',
  ),
  localWifiSoftAp(
    label: 'Local Wi-Fi SoftAP',
    description: 'Direct chamber hotspot at 192.168.4.1 (Zero Internet)',
    iconEmoji: '📶',
  );

  final String label;
  final String description;
  final String iconEmoji;

  const LocalConnectionType({
    required this.label,
    required this.description,
    required this.iconEmoji,
  });
}

enum LocalDeviceState {
  disconnected,
  scanning,
  connecting,
  connected,
  syncing,
  synced,
}

class LocalDeviceInfo {
  final String unitId;
  final String unitName;
  final String village;
  final LocalConnectionType connectionType;
  final String address; // MAC address or IP Address (e.g., 192.168.4.1)
  final int signalRssi; // -40 dBm (Strong) to -90 dBm (Weak)
  final LocalDeviceState state;
  final DateTime? lastSyncedAt;

  const LocalDeviceInfo({
    required this.unitId,
    required this.unitName,
    required this.village,
    required this.connectionType,
    required this.address,
    required this.signalRssi,
    this.state = LocalDeviceState.disconnected,
    this.lastSyncedAt,
  });

  String get signalQuality {
    if (signalRssi >= -60) return 'Excellent (-${signalRssi.abs()} dBm)';
    if (signalRssi >= -75) return 'Good (-${signalRssi.abs()} dBm)';
    return 'Fair (-${signalRssi.abs()} dBm)';
  }

  LocalDeviceInfo copyWith({
    String? unitId,
    String? unitName,
    String? village,
    LocalConnectionType? connectionType,
    String? address,
    int? signalRssi,
    LocalDeviceState? state,
    DateTime? lastSyncedAt,
  }) {
    return LocalDeviceInfo(
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      village: village ?? this.village,
      connectionType: connectionType ?? this.connectionType,
      address: address ?? this.address,
      signalRssi: signalRssi ?? this.signalRssi,
      state: state ?? this.state,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
