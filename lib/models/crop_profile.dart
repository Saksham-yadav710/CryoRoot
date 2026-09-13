class CropProfile {
  final String id;
  final String name;
  final String
      category; // e.g. "Solanaceous", "Citrus", "Spices", "Leafy", "Tuber", "Cole Crop"
  final String iconEmoji;
  final double optimalTempMin; // °C
  final double optimalTempMax; // °C
  final double optimalHumidityMin; // %
  final double optimalHumidityMax; // %
  final int maxStorageDays; // Maximum safe storage shelf life
  final double defaultPricePerKg; // Baseline wholesale market rate in INR
  final double chillingInjuryTemp; // Risk threshold below this temp
  final String storageAdvice;
  final bool isCustom;
  final List<String> aliases;

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
    this.isCustom = false,
    this.aliases = const [],
  });

  String get tempRangeFormatted =>
      '${optimalTempMin.toStringAsFixed(1)}°C - ${optimalTempMax.toStringAsFixed(1)}°C';

  String get humidityRangeFormatted =>
      '${optimalHumidityMin.toStringAsFixed(0)}% - ${optimalHumidityMax.toStringAsFixed(0)}%';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'iconEmoji': iconEmoji,
      'optimalTempMin': optimalTempMin,
      'optimalTempMax': optimalTempMax,
      'optimalHumidityMin': optimalHumidityMin,
      'optimalHumidityMax': optimalHumidityMax,
      'maxStorageDays': maxStorageDays,
      'defaultPricePerKg': defaultPricePerKg,
      'chillingInjuryTemp': chillingInjuryTemp,
      'storageAdvice': storageAdvice,
      'isCustom': isCustom,
      'aliases': aliases,
    };
  }

  factory CropProfile.fromJson(Map<String, dynamic> json) {
    return CropProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      iconEmoji: json['iconEmoji'] as String? ?? '🌱',
      optimalTempMin: (json['optimalTempMin'] as num).toDouble(),
      optimalTempMax: (json['optimalTempMax'] as num).toDouble(),
      optimalHumidityMin: (json['optimalHumidityMin'] as num).toDouble(),
      optimalHumidityMax: (json['optimalHumidityMax'] as num).toDouble(),
      maxStorageDays: json['maxStorageDays'] as int,
      defaultPricePerKg: (json['defaultPricePerKg'] as num).toDouble(),
      chillingInjuryTemp: (json['chillingInjuryTemp'] as num).toDouble(),
      storageAdvice: json['storageAdvice'] as String? ?? '',
      isCustom: json['isCustom'] as bool? ?? false,
      aliases: (json['aliases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  CropProfile copyWith({
    String? id,
    String? name,
    String? category,
    String? iconEmoji,
    double? optimalTempMin,
    double? optimalTempMax,
    double? optimalHumidityMin,
    double? optimalHumidityMax,
    int? maxStorageDays,
    double? defaultPricePerKg,
    double? chillingInjuryTemp,
    String? storageAdvice,
    bool? isCustom,
    List<String>? aliases,
  }) {
    return CropProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      optimalTempMin: optimalTempMin ?? this.optimalTempMin,
      optimalTempMax: optimalTempMax ?? this.optimalTempMax,
      optimalHumidityMin: optimalHumidityMin ?? this.optimalHumidityMin,
      optimalHumidityMax: optimalHumidityMax ?? this.optimalHumidityMax,
      maxStorageDays: maxStorageDays ?? this.maxStorageDays,
      defaultPricePerKg: defaultPricePerKg ?? this.defaultPricePerKg,
      chillingInjuryTemp: chillingInjuryTemp ?? this.chillingInjuryTemp,
      storageAdvice: storageAdvice ?? this.storageAdvice,
      isCustom: isCustom ?? this.isCustom,
      aliases: aliases ?? this.aliases,
    );
  }
}
