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

  // Sensor hardware health / validity flags (Requirement 14 graceful fallback)
  final bool isTemperatureValid;
  final bool isHumidityValid;
  final bool isBatteryValid;
  final bool isSolarValid;
  final bool isGridValid;
  final bool isDoorValid;
  final bool isPcmValid;
  final bool isWaterValid;

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
    };
  }

  // Formatted display values with graceful '--' fallback (Requirement 14)
  String get displayTemperature =>
      isTemperatureValid ? '${temperature.toStringAsFixed(1)}°C' : '--';

  String get displayHumidity => isHumidityValid ? '${humidity.toInt()}%' : '--';

  String get displayBattery => isBatteryValid ? '$battery%' : '--';

  String get displaySolar => isSolarValid ? '$solarPower' : '--';

  String get displayGridPower {
    if (!isGridValid) return '--';
    return gridPower ? 'ON' : 'OUTAGE';
  }

  String get displayPcmHours => isPcmValid ? formattedPcmHours : '--';

  String get displayWaterLevel => isWaterValid ? '$waterLevel%' : '--';

  String get displayDoor {
    if (!isDoorValid) return '--';
    return doorOpen ? 'OPEN' : 'CLOSED';
  }

  // Value + Status + Explanation Evaluators

  // 1. TEMPERATURE (Ideal 2°C - 8°C for multi-produce storage)
  StatusLevel get temperatureStatus {
    if (!isTemperatureValid) return StatusLevel.offline;
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
    if (!isOnline) return StatusLevel.offline;
    if (humidity >= 85.0 && humidity <= 95.0) return StatusLevel.good;
    if (humidity >= 80.0 && humidity < 85.0) return StatusLevel.attention;
    if (humidity < 80.0) return StatusLevel.warning;
    return StatusLevel.attention; // >95%
  }

  String get humidityExplanation {
    if (!isHumidityValid) return 'Humidity sensor unavailable';
    if (!isOnline) return 'Humidity sensor offline';
    if (humidity >= 85.0 && humidity <= 95.0) {
      return 'Optimal moisture level';
    }
    if (humidity < 80.0) {
      return 'Low humidity. Produce may lose weight.';
    }
    return 'Excess humidity. Check ventilation.';
  }

  // 3. BATTERY
  StatusLevel get batteryStatus {
    if (!isBatteryValid) return StatusLevel.offline;
    if (!isOnline) return StatusLevel.offline;
    if (battery >= 60) return StatusLevel.good;
    if (battery >= 30) return StatusLevel.attention;
    if (battery >= 15) return StatusLevel.warning;
    return StatusLevel.critical;
  }

  String get batteryExplanation {
    if (!isBatteryValid) return 'Battery sensor unavailable';
    if (!isOnline) return 'Battery status offline';
    if (battery >= 60) return 'Battery level is healthy';
    if (battery >= 30) return 'Moderate charge level';
    if (battery >= 15) return 'Low battery! Conserve power';
    return 'Critically low battery backup!';
  }

  // 4. SOLAR POWER
  StatusLevel get solarStatus {
    if (!isSolarValid) return StatusLevel.offline;
    if (!isOnline) return StatusLevel.offline;
    if (solarPower >= 250) return StatusLevel.good;
    if (solarPower > 0) return StatusLevel.attention;
    return StatusLevel.offline;
  }

  String get solarExplanation {
    if (!isSolarValid) return 'Solar telemetry unavailable';
    if (!isOnline) return 'Solar telemetry offline';
    if (solarPower >= 250) return 'Solar power is active & charging';
    if (solarPower > 0) return 'Low solar irradiance';
    return 'No solar generation (night / covered)';
  }

  // 5. GRID POWER
  StatusLevel get gridStatus {
    if (!isGridValid) return StatusLevel.offline;
    if (!isOnline) return StatusLevel.offline;
    return gridPower ? StatusLevel.good : StatusLevel.warning;
  }

  String get gridExplanation {
    if (!isGridValid) return 'Grid telemetry unavailable';
    if (!isOnline) return 'Grid telemetry offline';
    if (gridPower) return 'Grid power is connected & active';
    return 'Power outage! Running on solar & PCM';
  }

  // 6. PCM RESERVE (Phase Change Material Cold Backup)
  StatusLevel get pcmStatus {
    if (!isPcmValid) return StatusLevel.offline;
    if (!isOnline) return StatusLevel.offline;
    if (pcmReserveHours >= 24.0) return StatusLevel.good;
    if (pcmReserveHours >= 12.0) return StatusLevel.attention;
    if (pcmReserveHours >= 4.0) return StatusLevel.warning;
    return StatusLevel.critical;
  }

  String get pcmExplanation {
    if (!isPcmValid) return 'PCM telemetry unavailable';
    if (!isOnline) return 'PCM telemetry offline';
    if (pcmReserveHours >= 24.0) {
      return 'Enough cold backup remaining';
    }
    if (pcmReserveHours >= 12.0) {
      return 'Moderate cold reserve available';
    }
    if (pcmReserveHours >= 4.0) {
      return 'Reserve depleting! Restore power';
    }
    return 'PCM depleted! Immediate action required';
  }

  // Door status
  StatusLevel get doorStatus {
    if (!isDoorValid) return StatusLevel.offline;
    return doorOpen ? StatusLevel.warning : StatusLevel.good;
  }

  String get doorExplanation {
    if (!isDoorValid) return 'Door sensor unavailable';
    return doorOpen ? 'Door is currently OPEN' : 'Door is securely closed';
  }

  // Overall combined unit safety
  StatusLevel get overallStatus {
    if (!isOnline) return StatusLevel.offline;
    if (temperatureStatus == StatusLevel.critical ||
        batteryStatus == StatusLevel.critical ||
        pcmStatus == StatusLevel.critical) {
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
    );
  }
}
