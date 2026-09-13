import 'crop_profile.dart';
import 'status_level.dart';

class ProduceBatch {
  final String batchId;
  final CropProfile cropProfile;
  final double quantityKg;
  final String unitId;
  final String unitName;
  final DateTime entryDate;
  final DateTime? targetSellingDate;
  final String notes;

  const ProduceBatch({
    required this.batchId,
    required this.cropProfile,
    required this.quantityKg,
    required this.unitId,
    required this.unitName,
    required this.entryDate,
    this.targetSellingDate,
    this.notes = '',
  });

  // Calculate storage age in days
  int get storageAgeDays {
    final difference = DateTime.now().difference(entryDate).inDays;
    return difference >= 0 ? difference : 0;
  }

  // Calculate remaining storage days considering chamber temperature
  int estimatedRemainingDays(double currentChamberTemp) {
    int maxDays = cropProfile.maxStorageDays;
    int age = storageAgeDays;

    // Thermal degradation factor: if temp exceeds optimal max, degradation accelerates
    if (currentChamberTemp > cropProfile.optimalTempMax) {
      final excess = currentChamberTemp - cropProfile.optimalTempMax;
      final acceleratedAge = (age + (excess * 2.5)).toInt();
      final remaining = maxDays - acceleratedAge;
      return remaining > 0 ? remaining : 0;
    }

    final remaining = maxDays - age;
    return remaining > 0 ? remaining : 0;
  }

  // Evaluate batch condition against current chamber telemetry
  StatusLevel condition(double currentTemp, double currentHumidity) {
    if (currentTemp < cropProfile.chillingInjuryTemp) {
      return StatusLevel.critical;
    }
    if (currentTemp >= cropProfile.optimalTempMin &&
        currentTemp <= cropProfile.optimalTempMax &&
        currentHumidity >= cropProfile.optimalHumidityMin) {
      if (estimatedRemainingDays(currentTemp) <= 3) {
        return StatusLevel.attention; // Near end of safe window
      }
      return StatusLevel.good;
    }
    if (currentTemp > cropProfile.optimalTempMax + 3.0) {
      return StatusLevel.critical;
    }
    if (currentTemp > cropProfile.optimalTempMax ||
        currentHumidity < cropProfile.optimalHumidityMin - 10.0) {
      return StatusLevel.warning;
    }
    return StatusLevel.attention;
  }

  String conditionExplanation(double currentTemp, double currentHumidity) {
    final status = condition(currentTemp, currentHumidity);
    switch (status) {
      case StatusLevel.good:
        return 'Chamber matches optimal ${cropProfile.name} storage parameters.';
      case StatusLevel.attention:
        if (estimatedRemainingDays(currentTemp) <= 3) {
          return 'Approaching end of optimal storage window. Consider selling soon.';
        }
        return 'Minor deviation from ideal temperature range.';
      case StatusLevel.warning:
        return 'Elevated temperature (${currentTemp.toStringAsFixed(1)}°C). Accelerated shelf-life drain.';
      case StatusLevel.critical:
        if (currentTemp < cropProfile.chillingInjuryTemp) {
          return 'Chilling injury risk! Temperature below ${cropProfile.chillingInjuryTemp}°C threshold.';
        }
        return 'Critical storage heat! Spoilage risk imminent.';
      case StatusLevel.offline:
        return 'Chamber telemetry offline.';
    }
  }

  // Market Valuation
  double get estimatedMarketValue => quantityKg * cropProfile.defaultPricePerKg;

  // Shelf life percentage consumed (0.0 to 1.0)
  double shelfLifeProgress(double currentTemp) {
    final int remaining = estimatedRemainingDays(currentTemp);
    final int total = storageAgeDays + remaining;
    if (total <= 0) return 1.0;
    return (storageAgeDays / total).clamp(0.0, 1.0);
  }

  ProduceBatch copyWith({
    String? batchId,
    CropProfile? cropProfile,
    double? quantityKg,
    String? unitId,
    String? unitName,
    DateTime? entryDate,
    DateTime? targetSellingDate,
    String? notes,
  }) {
    return ProduceBatch(
      batchId: batchId ?? this.batchId,
      cropProfile: cropProfile ?? this.cropProfile,
      quantityKg: quantityKg ?? this.quantityKg,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      entryDate: entryDate ?? this.entryDate,
      targetSellingDate: targetSellingDate ?? this.targetSellingDate,
      notes: notes ?? this.notes,
    );
  }
}
