class CropProfile {
  final String id;
  final String name;
  final String category; // e.g. "Solanaceous", "Citrus", "Spices", "Leafy"
  final String iconEmoji;
  final double optimalTempMin; // °C
  final double optimalTempMax; // °C
  final double optimalHumidityMin; // %
  final double optimalHumidityMax; // %
  final int maxStorageDays; // Maximum safe storage shelf life
  final double defaultPricePerKg; // Baseline wholesale market rate in INR
  final double chillingInjuryTemp; // Risk threshold below this temp
  final String storageAdvice;

  const CropProfile({
    required this.id,
    required this.name,
    required this.category,
    required this.iconEmoji,
    required this.optimalTempMin,
    required this.optimalTempMax,
    required this.optimalHumidityMin,
    required this.optimalHumidityMax,
    required this.maxStorageDays,
    required this.defaultPricePerKg,
    required this.chillingInjuryTemp,
    required this.storageAdvice,
  });

  String get tempRangeFormatted =>
      '${optimalTempMin.toStringAsFixed(0)}°C - ${optimalTempMax.toStringAsFixed(0)}°C';

  String get humidityRangeFormatted =>
      '${optimalHumidityMin.toStringAsFixed(0)}% - ${optimalHumidityMax.toStringAsFixed(0)}%';
}
