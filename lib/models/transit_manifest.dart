import 'crop_profile.dart';
import 'status_level.dart';

enum TransitMode {
  solarReeferVan(
    title: 'Solar-Assisted Mini Reefer',
    description: 'Active compressor powered by roof solar + LiFePO4 battery',
    iconEmoji: '🚐',
    typicalTempRange: '3°C - 6°C',
    hasActiveCooling: true,
  ),
  insulatedPcmCrate(
    title: 'Insulated PCM CryoRoot Crate',
    description: 'Passive phase-change cooling bricks (up to 12h cold life)',
    iconEmoji: '📦',
    typicalTempRange: '5°C - 9°C',
    hasActiveCooling: false,
  ),
  ventilatedLocalCarrier(
    title: 'Ventilated Local Carrier',
    description: 'Shaded ambient transit for short-haul journeys (< 2h)',
    iconEmoji: '🛻',
    typicalTempRange: 'Ambient (18°C - 24°C)',
    hasActiveCooling: false,
  );

  final String title;
  final String description;
  final String iconEmoji;
  final String typicalTempRange;
  final bool hasActiveCooling;

  const TransitMode({
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.typicalTempRange,
    required this.hasActiveCooling,
  });
}

enum TransitStatus {
  inTransit('In Transit', StatusLevel.good),
  arrivingSoon('Arriving Soon', StatusLevel.good),
  temperatureWarning('Thermal Warning', StatusLevel.warning),
  delivered('Delivered', StatusLevel.good);

  final String label;
  final StatusLevel statusLevel;

  const TransitStatus(this.label, this.statusLevel);
}

class TransitDataPoint {
  final DateTime timestamp;
  final double temperature;
  final double humidity;

  const TransitDataPoint({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
  });
}

class TransitManifest {
  final String manifestId;
  final String batchId;
  final CropProfile cropProfile;
  final double quantityKg;
  final String originUnitId;
  final String originUnitName;
  final String destinationMandi;
  final TransitMode transitMode;
  final TransitStatus status;
  final DateTime departureTime;
  final DateTime estimatedArrivalTime;
  final double currentTemp;
  final double currentHumidity;
  final double batteryOrPcmHours;
  final String vehicleNumber;
  final String driverName;
  final String driverPhone;
  final List<TransitDataPoint> telemetryLogs;
  final String buyerNotes;

  const TransitManifest({
    required this.manifestId,
    required this.batchId,
    required this.cropProfile,
    required this.quantityKg,
    required this.originUnitId,
    required this.originUnitName,
    required this.destinationMandi,
    required this.transitMode,
    required this.status,
    required this.departureTime,
    required this.estimatedArrivalTime,
    required this.currentTemp,
    required this.currentHumidity,
    required this.batteryOrPcmHours,
    required this.vehicleNumber,
    required this.driverName,
    required this.driverPhone,
    this.telemetryLogs = const [],
    this.buyerNotes = '',
  });

  Duration get elapsedTime => DateTime.now().difference(departureTime);

  Duration get remainingTime {
    final diff = estimatedArrivalTime.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  double get journeyProgressPercent {
    final totalDuration =
        estimatedArrivalTime.difference(departureTime).inMinutes;
    if (totalDuration <= 0) return 1.0;
    final elapsed = DateTime.now().difference(departureTime).inMinutes;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }

  // Quality grading compliance verified by continuous thermal sensor
  String get verifiedQualityGrade {
    if (currentTemp <= cropProfile.optimalTempMax + 1.0 &&
        currentTemp >= cropProfile.optimalTempMin - 1.0) {
      return 'Grade A+ (Certified Cold Chain)';
    } else if (currentTemp <= cropProfile.optimalTempMax + 3.0) {
      return 'Grade A (Mandi Premium)';
    } else {
      return 'Grade B (Standard Market)';
    }
  }

  double get estimatedTotalValue => quantityKg * cropProfile.defaultPricePerKg;

  TransitManifest copyWith({
    String? manifestId,
    String? batchId,
    CropProfile? cropProfile,
    double? quantityKg,
    String? originUnitId,
    String? originUnitName,
    String? destinationMandi,
    TransitMode? transitMode,
    TransitStatus? status,
    DateTime? departureTime,
    DateTime? estimatedArrivalTime,
    double? currentTemp,
    double? currentHumidity,
    double? batteryOrPcmHours,
    String? vehicleNumber,
    String? driverName,
    String? driverPhone,
    List<TransitDataPoint>? telemetryLogs,
    String? buyerNotes,
  }) {
    return TransitManifest(
      manifestId: manifestId ?? this.manifestId,
      batchId: batchId ?? this.batchId,
      cropProfile: cropProfile ?? this.cropProfile,
      quantityKg: quantityKg ?? this.quantityKg,
      originUnitId: originUnitId ?? this.originUnitId,
      originUnitName: originUnitName ?? this.originUnitName,
      destinationMandi: destinationMandi ?? this.destinationMandi,
      transitMode: transitMode ?? this.transitMode,
      status: status ?? this.status,
      departureTime: departureTime ?? this.departureTime,
      estimatedArrivalTime: estimatedArrivalTime ?? this.estimatedArrivalTime,
      currentTemp: currentTemp ?? this.currentTemp,
      currentHumidity: currentHumidity ?? this.currentHumidity,
      batteryOrPcmHours: batteryOrPcmHours ?? this.batteryOrPcmHours,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      telemetryLogs: telemetryLogs ?? this.telemetryLogs,
      buyerNotes: buyerNotes ?? this.buyerNotes,
    );
  }
}
