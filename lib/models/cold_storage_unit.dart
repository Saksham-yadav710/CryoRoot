import 'sensor_reading.dart';
import 'status_level.dart';

class ColdStorageUnit {
  final String id;
  final String name;
  final String village;
  final String district;
  final int capacityKg;
  final int currentOccupancyKg;
  final String primaryProduce;
  final SensorReading reading;
  final String recommendedAction;
  final bool hasActionRequired;

  const ColdStorageUnit({
    required this.id,
    required this.name,
    required this.village,
    required this.district,
    required this.capacityKg,
    required this.currentOccupancyKg,
    required this.primaryProduce,
    required this.reading,
    required this.recommendedAction,
    this.hasActionRequired = false,
  });

  StatusLevel get status => reading.overallStatus;

  String get fullLocation => '$village, $district';

  String get produceSafetySummary {
    switch (status) {
      case StatusLevel.good:
        return 'Produce is safe and optimal.';
      case StatusLevel.attention:
        return 'Produce is safe. Monitor conditions.';
      case StatusLevel.warning:
        return 'Caution advised. Action required soon.';
      case StatusLevel.critical:
        return 'Risk of produce spoilage! Immediate check required.';
      case StatusLevel.offline:
        return 'Unit is offline. Check physical connectivity.';
    }
  }

  // Generate natural audio summary text for farmer
  String get audioSummaryText {
    final buffer = StringBuffer();
    if (status == StatusLevel.good) {
      buffer.write('Your $name in $village is working normally. ');
      buffer.write(
        'Temperature is ${reading.temperature.toStringAsFixed(1)} degrees and humidity is ${reading.humidity.toInt()} percent. ',
      );
      buffer.write(
        'Battery is ${reading.battery} percent and solar power is ${reading.solarPower} watts. ',
      );
      buffer.write(
          'PCM cold backup has ${reading.formattedPcmHours} remaining. ');
      buffer.write('Your produce is safe. No action is needed.');
    } else if (status == StatusLevel.critical ||
        status == StatusLevel.warning) {
      buffer.write('Attention farmer! ');
      buffer.write('In $name at $village, ');
      if (reading.doorOpen) {
        buffer.write('the storage door is currently open. ');
      }
      if (reading.temperature > 8.0) {
        buffer.write(
          'the temperature has reached ${reading.temperature.toStringAsFixed(1)} degrees celsius which is high. ',
        );
      }
      if (!reading.gridPower) {
        buffer.write(
          'Grid power is off, but PCM backup has ${reading.formattedPcmHours} remaining. ',
        );
      }
      buffer.write('Recommended action: $recommendedAction');
    } else {
      buffer.write('Status update for $name in $village. ');
      buffer.write('Conditions are acceptable. $recommendedAction');
    }
    return buffer.toString();
  }

  ColdStorageUnit copyWith({
    String? id,
    String? name,
    String? village,
    String? district,
    int? capacityKg,
    int? currentOccupancyKg,
    String? primaryProduce,
    SensorReading? reading,
    String? recommendedAction,
    bool? hasActionRequired,
  }) {
    return ColdStorageUnit(
      id: id ?? this.id,
      name: name ?? this.name,
      village: village ?? this.village,
      district: district ?? this.district,
      capacityKg: capacityKg ?? this.capacityKg,
      currentOccupancyKg: currentOccupancyKg ?? this.currentOccupancyKg,
      primaryProduce: primaryProduce ?? this.primaryProduce,
      reading: reading ?? this.reading,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      hasActionRequired: hasActionRequired ?? this.hasActionRequired,
    );
  }
}
