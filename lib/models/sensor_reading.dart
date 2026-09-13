import 'status_level.dart';

class SensorReading {
  final String deviceId;
  final double temperature; // °C
  final double humidity; // %
  final int battery; // %
  final int solarPower; // Watts
  final bool gridPower; // true = ON, false = OFF (Outage)
  final bool doorOpen; // true = Open, false = Closed
  final double pcmReserveHours; // Hours remaining
  final int waterLevel; // %
  final bool isOnline;
  final DateTime timestamp;

  // Sensor hardware health / validity flags
  final bool isTemperatureValid;
  final bool isHumidityValid;
  final bool isBatteryValid;
  final bool isSolarValid;
  final bool isGridValid;
  final bool isDoorValid;
  final bool isPcmValid;
  final bool isWaterValid;

  // Explicit fault diagnostic messages (when probe is detached/error)
  final String? temperatureFaultReason;
  final String? humidityFaultReason;
  final String? batteryFaultReason;
  final String? solarFaultReason;

  // Individual parameter update timestamps
  final DateTime? temperatureTimestamp;
  final DateTime? humidityTimestamp;
  final DateTime? batteryTimestamp;
  final DateTime? solarTimestamp;
  final DateTime? pcmTimestamp;
  final DateTime? gridTimestamp;
  final DateTime? doorTimestamp;
  final DateTime? waterTimestamp;

  const SensorReading({
    required this.deviceId,
    required this.temperature,
    required this.humidity,
    required this.battery,
    required this.solarPower,
    required this.gridPower,
    required this.doorOpen,
    required this.pcmReserveHours,
    required this.waterLevel,
    required this.isOnline,
    required this.timestamp,
    this.isTemperatureValid = true,
    this.isHumidityValid = true,
    this.isBatteryValid = true,
    this.isSolarValid = true,
    this.isGridValid = true,
    this.isDoorValid = true,
    this.isPcmValid = true,
    this.isWaterValid = true,
    this.temperatureFaultReason,
    this.humidityFaultReason,
    this.batteryFaultReason,
    this.solarFaultReason,
    this.temperatureTimestamp,
    this.humidityTimestamp,
    this.batteryTimestamp,
    this.solarTimestamp,
    this.pcmTimestamp,
    this.gridTimestamp,
    this.doorTimestamp,
    this.waterTimestamp,
  });

  // Factory from JSON for future API/MQTT compatibility
  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      deviceId: json['deviceId'] as String? ?? 'AC-DEV-001',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 4.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 90.0,
      battery: (json['battery'] as num?)?.toInt() ?? 80,
      solarPower: (json['solarPower'] as num?)?.toInt() ?? 400,
      gridPower: json['gridPower'] as bool? ?? true,
      doorOpen: json['doorOpen'] as bool? ?? false,
      pcmReserveHours: (json['pcmReserveHours'] as num?)?.toDouble() ?? 40.0,
      waterLevel: (json['waterLevel'] as num?)?.toInt() ?? 80,
      isOnline: json['isOnline'] as bool? ?? true,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isTemperatureValid: json['isTemperatureValid'] as bool? ?? true,
      isHumidityValid: json['isHumidityValid'] as bool? ?? true,
      isBatteryValid: json['isBatteryValid'] as bool? ?? true,
      isSolarValid: json['isSolarValid'] as bool? ?? true,
      isGridValid: json['isGridValid'] as bool? ?? true,
      isDoorValid: json['isDoorValid'] as bool? ?? true,
      isPcmValid: json['isPcmValid'] as bool? ?? true,
      isWaterValid: json['isWaterValid'] as bool? ?? true,
      temperatureFaultReason: json['temperatureFaultReason'] as String?,
      humidityFaultReason: json['humidityFaultReason'] as String?,
      batteryFaultReason: json['batteryFaultReason'] as String?,
      solarFaultReason: json['solarFaultReason'] as String?,
      temperatureTimestamp: json['temperatureTimestamp'] != null
          ? DateTime.parse(json['temperatureTimestamp'] as String)
          : null,
      humidityTimestamp: json['humidityTimestamp'] != null
          ? DateTime.parse(json['humidityTimestamp'] as String)
          : null,
      batteryTimestamp: json['batteryTimestamp'] != null
          ? DateTime.parse(json['batteryTimestamp'] as String)
          : null,
      solarTimestamp: json['solarTimestamp'] != null
          ? DateTime.parse(json['solarTimestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'temperature': temperature,
      'humidity': humidity,
      'battery': battery,
      'solarPower': solarPower,
      'gridPower': gridPower,
      'doorOpen': doorOpen,
      'pcmReserveHours': pcmReserveHours,
      'waterLevel': waterLevel,
      'isOnline': isOnline,
      'timestamp': timestamp.toIso8601String(),
      'isTemperatureValid': isTemperatureValid,
      'isHumidityValid': isHumidityValid,
      'isBatteryValid': isBatteryValid,
      'isSolarValid': isSolarValid,
      'isGridValid': isGridValid,
      'isDoorValid': isDoorValid,
      'isPcmValid': isPcmValid,
      'isWaterValid': isWaterValid,
      'temperatureFaultReason': temperatureFaultReason,
      'humidityFaultReason': humidityFaultReason,
      'batteryFaultReason': batteryFaultReason,
      'solarFaultReason': solarFaultReason,
      'temperatureTimestamp': temperatureTimestamp?.toIso8601String(),
      'humidityTimestamp': humidityTimestamp?.toIso8601String(),
      'batteryTimestamp': batteryTimestamp?.toIso8601String(),
      'solarTimestamp': solarTimestamp?.toIso8601String(),
    };
  }

  // Display strings for UI
  String get displayTemperature =>
      isTemperatureValid ? '${temperature.toStringAsFixed(1)}°C' : '--';

  String get displayHumidity =>
      isHumidityValid ? '${humidity.toInt()}%' : '--';

  String get displayBattery => isBatteryValid ? '$battery%' : '--';

  String get displaySolar => isSolarValid ? '$solarPower' : '--';

  String get displayGrid => !isGridValid ? '--' : (gridPower ? 'ON' : 'OUTAGE');
  String get displayGridPower => displayGrid;

  String get displayDoor {
    if (!isDoorValid) return '--';
    return doorOpen ? 'OPEN' : 'CLOSED';
  }

  String get displayPcmHours => formattedPcmHours;

  String get displayWaterLevel => !isWaterValid ? '--' : '$waterLevel%';

  // Fault status helpers
  bool get hasTemperatureFault =>
      temperatureFaultReason != null &&
      temperatureFaultReason!.trim().isNotEmpty;

  bool get hasHumidityFault =>
      humidityFaultReason != null &&
      humidityFaultReason!.trim().isNotEmpty;

  bool get hasBatteryFault =>
      batteryFaultReason != null &&
      batteryFaultReason!.trim().isNotEmpty;

  bool get hasSolarFault =>
      solarFaultReason != null &&
      solarFaultReason!.trim().isNotEmpty;

  // Relative freshness formatters
  static String formatRelativeTime(DateTime? dt) {
    if (dt == null) return 'Just now';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 5) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  String get tempUpdatedText =>
      formatRelativeTime(temperatureTimestamp ?? timestamp);
  String get humidityUpdatedText =>
      formatRelativeTime(humidityTimestamp ?? timestamp);
  String get batteryUpdatedText =>
      formatRelativeTime(batteryTimestamp ?? timestamp);
  String get solarUpdatedText =>
      formatRelativeTime(solarTimestamp ?? timestamp);
  String get pcmUpdatedText => formatRelativeTime(pcmTimestamp ?? timestamp);
  String get gridUpdatedText => formatRelativeTime(gridTimestamp ?? timestamp);
  String get doorUpdatedText => formatRelativeTime(doorTimestamp ?? timestamp);
  String get waterUpdatedText =>
      formatRelativeTime(waterTimestamp ?? timestamp);

  // Value + Status + Explanation Evaluators

  // 1. TEMPERATURE (Ideal 2°C - 8°C for multi-produce storage)
  StatusLevel get temperatureStatus {
    if (!isTemperatureValid) return StatusLevel.offline;
    if (hasTemperatureFault) return StatusLevel.critical;
    if (!isOnline) return StatusLevel.offline;
    if (temperature >= 2.0 && temperature <= 8.0) return StatusLevel.good;
    if ((temperature > 8.0 && temperature <= 10.0) ||
        (temperature >= 0.0 && temperature < 2.0)) {
      return StatusLevel.attention;
    }
    if (temperature > 10.0 && temperature <= 12.0) return StatusLevel.warning;
    return StatusLevel.critical;
  }

  String get temperatureExplanation {
    if (!isTemperatureValid) return 'Temperature sensor unavailable';
    if (hasTemperatureFault) {
      return temperatureFaultReason ?? 'Sensor probe disconnected / error';
    }
    if (!isOnline) return 'Sensor offline. Last reading shown.';
    if (temperature >= 2.0 && temperature <= 8.0) {
      return 'Within recommended range';
    }
    if (temperature > 8.0 && temperature <= 10.0) {
      return 'Slightly elevated. Monitor closely.';
    }
    if (temperature > 10.0) {
      return 'Critically high! Risk of produce spoilage.';
    }
    return 'Temperature below optimal storage baseline.';
  }

  // 2. HUMIDITY (Ideal 85% - 95%)
  StatusLevel get humidityStatus {
    if (!isHumidityValid) return StatusLevel.offline;
    if (hasHumidityFault) return StatusLevel.critical;
    if (!isOnline) return StatusLevel.offline;
    if (humidity >= 85.0 && humidity <= 95.0) return StatusLevel.good;
    if (humidity >= 80.0 && humidity < 85.0) return StatusLevel.attention;
    if (humidity < 80.0) return StatusLevel.warning;
    return StatusLevel.attention; // >95%
  }

  String get humidityExplanation {
    if (!isHumidityValid) return 'Humidity sensor unavailable';
    if (hasHumidityFault) {
      return humidityFaultReason ?? 'Humidity probe disconnected / error';
    }
    if (!isOnline) return 'Humidity sensor offline';
    if (humidity >= 85.0 && humidity <= 95.0) {
      return 'Optimal moisture level';
    }
    if (humidity < 80.0) {
      return 'Low humidity. Produce may lose weight.';
    }
    return 'High humidity. Monitor condensation.';
  }

  // 3. BATTERY (Healthy >50%, Attention 20-50%, Critical <20%)
  StatusLevel get batteryStatus {
    if (!isBatteryValid) return StatusLevel.offline;
    if (hasBatteryFault) return StatusLevel.critical;
    if (!isOnline) return StatusLevel.offline;
    if (battery >= 50) return StatusLevel.good;
    if (battery >= 20) return StatusLevel.attention;
    return StatusLevel.critical;
  }

  String get batteryExplanation {
    if (!isBatteryValid) return 'Battery telemetry unavailable';
    if (hasBatteryFault) return batteryFaultReason ?? 'Battery BMS error';
    if (!isOnline) return 'Offline telemetry';
    if (battery >= 50) return 'Battery level is healthy';
    if (battery >= 20) return 'Low battery. Conserving power.';
    return 'Critical battery! Needs grid or sun.';
  }

  // 4. SOLAR POWER
  StatusLevel get solarStatus {
    if (!isSolarValid) return StatusLevel.offline;
    if (hasSolarFault) return StatusLevel.warning;
    if (!isOnline) return StatusLevel.offline;
    if (solarPower > 500) return StatusLevel.good;
    if (solarPower > 0) return StatusLevel.attention;
    return StatusLevel.offline; // Inactive (night or dark)
  }

  String get solarExplanation {
    if (!isSolarValid) return 'Solar telemetry unavailable';
    if (hasSolarFault) return solarFaultReason ?? 'MPPT communication fault';
    if (!isOnline) return 'Telemetry offline';
    if (solarPower > 500) return 'Solar power is active';
    if (solarPower > 0) return 'Low sunlight available';
    return 'No solar power (night / overcast)';
  }

  // 5. GRID POWER
  StatusLevel get gridStatus {
    if (!isGridValid) return StatusLevel.offline;
    if (!isOnline) return StatusLevel.offline;
    return gridPower ? StatusLevel.good : StatusLevel.warning;
  }

  String get gridExplanation {
    if (!isGridValid) return 'Grid telemetry unavailable';
    if (!isOnline) return 'Telemetry offline';
    return gridPower ? 'Grid power normal' : 'Power outage in progress';
  }

  // 6. DOOR STATUS
  StatusLevel get doorStatus {
    if (!isDoorValid) return StatusLevel.offline;
    if (!isOnline) return StatusLevel.offline;
    return doorOpen ? StatusLevel.critical : StatusLevel.good;
  }

  String get doorExplanation {
    if (!isDoorValid) return 'Door sensor unavailable';
    if (!isOnline) return 'Telemetry offline';
    return doorOpen ? 'Door is open! Close immediately.' : 'Chamber sealed';
  }

  // 7. PCM THERMAL BACKUP (Safe >12h, Attention 6-12h, Critical <6h)
  StatusLevel get pcmStatus {
    if (!isPcmValid) return StatusLevel.offline;
    if (!isOnline) return StatusLevel.offline;
    if (pcmReserveHours >= 12.0) return StatusLevel.good;
    if (pcmReserveHours >= 6.0) return StatusLevel.attention;
    return StatusLevel.critical;
  }

  String get pcmExplanation {
    if (!isPcmValid) return 'PCM telemetry unavailable';
    if (!isOnline) return 'Telemetry offline';
    if (pcmReserveHours >= 24.0) return 'Thermal battery fully charged';
    if (pcmReserveHours >= 12.0) return 'Enough backup remaining';
    if (pcmReserveHours >= 6.0) return 'PCM reserve depleting';
    return 'Critical PCM! Thermal reserve nearly empty.';
  }

  // 8. WATER LEVEL
  StatusLevel get waterStatus {
    if (!isWaterValid) return StatusLevel.offline;
    if (!isOnline) return StatusLevel.offline;
    if (waterLevel >= 50) return StatusLevel.good;
    if (waterLevel >= 25) return StatusLevel.attention;
    return StatusLevel.warning;
  }

  String get waterExplanation {
    if (!isWaterValid) return 'Water level sensor unavailable';
    if (!isOnline) return 'Telemetry offline';
    if (waterLevel >= 50) return 'Condenser reservoir optimal';
    if (waterLevel >= 25) return 'Reservoir low. Refill soon.';
    return 'Critically low water in cooling loop';
  }

  // Overall chamber system health
  StatusLevel get overallStatus {
    if (!isOnline) return StatusLevel.offline;
    if (hasTemperatureFault || hasHumidityFault) return StatusLevel.critical;
    if (temperatureStatus == StatusLevel.critical ||
        pcmStatus == StatusLevel.critical ||
        batteryStatus == StatusLevel.critical) {
      return StatusLevel.critical;
    }
    if (temperatureStatus == StatusLevel.warning ||
        doorOpen ||
        gridStatus == StatusLevel.warning ||
        batteryStatus == StatusLevel.warning) {
      return StatusLevel.warning;
    }
    if (temperatureStatus == StatusLevel.attention ||
        batteryStatus == StatusLevel.attention ||
        humidityStatus == StatusLevel.attention) {
      return StatusLevel.attention;
    }
    return StatusLevel.good;
  }

  // Formatted string for PCM e.g. "41h 32m"
  String get formattedPcmHours {
    final int hours = pcmReserveHours.floor();
    final int minutes = ((pcmReserveHours - hours) * 60).round();
    return '${hours}h ${minutes}m';
  }

  SensorReading copyWith({
    String? deviceId,
    double? temperature,
    double? humidity,
    int? battery,
    int? solarPower,
    bool? gridPower,
    bool? doorOpen,
    double? pcmReserveHours,
    int? waterLevel,
    bool? isOnline,
    DateTime? timestamp,
    bool? isTemperatureValid,
    bool? isHumidityValid,
    bool? isBatteryValid,
    bool? isSolarValid,
    bool? isGridValid,
    bool? isDoorValid,
    bool? isPcmValid,
    bool? isWaterValid,
    String? temperatureFaultReason,
    String? humidityFaultReason,
    String? batteryFaultReason,
    String? solarFaultReason,
    bool clearTemperatureFault = false,
    bool clearHumidityFault = false,
    bool clearBatteryFault = false,
    bool clearSolarFault = false,
    DateTime? temperatureTimestamp,
    DateTime? humidityTimestamp,
    DateTime? batteryTimestamp,
    DateTime? solarTimestamp,
    DateTime? pcmTimestamp,
    DateTime? gridTimestamp,
    DateTime? doorTimestamp,
    DateTime? waterTimestamp,
  }) {
    return SensorReading(
      deviceId: deviceId ?? this.deviceId,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      battery: battery ?? this.battery,
      solarPower: solarPower ?? this.solarPower,
      gridPower: gridPower ?? this.gridPower,
      doorOpen: doorOpen ?? this.doorOpen,
      pcmReserveHours: pcmReserveHours ?? this.pcmReserveHours,
      waterLevel: waterLevel ?? this.waterLevel,
      isOnline: isOnline ?? this.isOnline,
      timestamp: timestamp ?? this.timestamp,
      isTemperatureValid: isTemperatureValid ?? this.isTemperatureValid,
      isHumidityValid: isHumidityValid ?? this.isHumidityValid,
      isBatteryValid: isBatteryValid ?? this.isBatteryValid,
      isSolarValid: isSolarValid ?? this.isSolarValid,
      isGridValid: isGridValid ?? this.isGridValid,
      isDoorValid: isDoorValid ?? this.isDoorValid,
      isPcmValid: isPcmValid ?? this.isPcmValid,
      isWaterValid: isWaterValid ?? this.isWaterValid,
      temperatureFaultReason: clearTemperatureFault
          ? null
          : (temperatureFaultReason ?? this.temperatureFaultReason),
      humidityFaultReason: clearHumidityFault
          ? null
          : (humidityFaultReason ?? this.humidityFaultReason),
      batteryFaultReason: clearBatteryFault
          ? null
          : (batteryFaultReason ?? this.batteryFaultReason),
      solarFaultReason: clearSolarFault
          ? null
          : (solarFaultReason ?? this.solarFaultReason),
      temperatureTimestamp: temperatureTimestamp ?? this.temperatureTimestamp,
      humidityTimestamp: humidityTimestamp ?? this.humidityTimestamp,
      batteryTimestamp: batteryTimestamp ?? this.batteryTimestamp,
      solarTimestamp: solarTimestamp ?? this.solarTimestamp,
      pcmTimestamp: pcmTimestamp ?? this.pcmTimestamp,
      gridTimestamp: gridTimestamp ?? this.gridTimestamp,
      doorTimestamp: doorTimestamp ?? this.doorTimestamp,
      waterTimestamp: waterTimestamp ?? this.waterTimestamp,
    );
  }
}
