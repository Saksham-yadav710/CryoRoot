import 'dart:async';
import '../../models/crop_profile.dart';

/// Real-time Agricultural Science condition estimation and lookup service.
///
/// Automatically determines optimal cold-storage parameters
/// (temperature, humidity, chilling injury limits, max storage days,
/// and storage advice) for any vegetable or crop entered by the farmer.
class CropConditionLookupService {
  /// Fetches/estimates cold storage conditions in real-time.
  /// Simulates realistic network/knowledge-base retrieval latency (300-500ms).
  static Future<CropProfile> fetchConditionsForCrop(
    String cropName, {
    String? categoryHint,
  }) async {
    // Simulate real-time API query latency to give live feedback to the farmer
    await Future.delayed(const Duration(milliseconds: 400));

    final normalized = cropName.trim().toLowerCase();
    final id =
        'CUSTOM-${cropName.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '-')}-${DateTime.now().millisecondsSinceEpoch % 10000}';

    // 1. Check for botanical categories & keyword patterns
    if (_matchesKeywords(normalized, [
      'leaf',
      'spinach',
      'saag',
      'methi',
      'palak',
      'coriander',
      'dhania',
      'mint',
      'pudina',
      'herb',
      'curry',
      'kale',
      'lettuce',
      'chard',
      'celery',
      'parsley',
      'basil',
      'amaranth',
      'fenugreek',
      'sorrel'
    ])) {
      return CropProfile(
        id: id,
        name: _formatTitleCase(cropName),
        category: 'Leafy Green & Herbs',
        iconEmoji: '🌿',
        optimalTempMin: 0.5,
        optimalTempMax: 2.5,
        optimalHumidityMin: 95.0,
        optimalHumidityMax: 98.0,
        maxStorageDays: 14,
        defaultPricePerKg: 35.0,
        chillingInjuryTemp: -0.5,
        storageAdvice:
            'High respiration leafy crop. Rapid pre-cooling to 1°C and saturation humidity (95%+) are required to arrest wilting and moisture evaporation.',
        isCustom: true,
        aliases: [cropName],
      );
    }

    if (_matchesKeywords(normalized, [
      'cabbage',
      'cauliflower',
      'gobi',
      'broccoli',
      'kohlrabi',
      'knol',
      'brussel',
      'kale',
      'bok choy',
      'pak choi'
    ])) {
      return CropProfile(
        id: id,
        name: _formatTitleCase(cropName),
        category: 'Cole Crop',
        iconEmoji: '🥦',
        optimalTempMin: 0.0,
        optimalTempMax: 2.0,
        optimalHumidityMin: 92.0,
        optimalHumidityMax: 98.0,
        maxStorageDays: 45,
        defaultPricePerKg: 40.0,
        chillingInjuryTemp: -1.0,
        storageAdvice:
            'Brassica family crops tolerate near-freezing conditions well. Keep cold and humid to preserve curd firmness and stop leaf yellowing.',
        isCustom: true,
        aliases: [cropName],
      );
    }

    if (_matchesKeywords(normalized, [
      'onion',
      'pyaz',
      'garlic',
      'lahsun',
      'shallot',
      'scallion',
      'leek',
      'chive'
    ])) {
      return CropProfile(
        id: id,
        name: _formatTitleCase(cropName),
        category: 'Allium',
        iconEmoji: '🧅',
        optimalTempMin: 0.0,
        optimalTempMax: 2.5,
        optimalHumidityMin: 65.0,
        optimalHumidityMax: 72.0,
        maxStorageDays: 180,
        defaultPricePerKg: 35.0,
        chillingInjuryTemp: -2.0,
        storageAdvice:
            'Critical Rule: Alliums require DRY cold storage (65%-72% RH). High humidity leads to neck rot, fungal decay, and root sprouting.',
        isCustom: true,
        aliases: [cropName],
      );
    }

    if (_matchesKeywords(normalized, [
      'gourd',
      'karela',
      'lauki',
      'torai',
      'turai',
      'cucumber',
      'kheera',
      'pumpkin',
      'kaddu',
      'zucchini',
      'squash',
      'tinda',
      'parwal',
      'kundru',
      'chichinda',
      'melon'
    ])) {
      return CropProfile(
        id: id,
        name: _formatTitleCase(cropName),
        category: 'Cucurbit / Gourd',
        iconEmoji: '🥒',
        optimalTempMin: 10.0,
        optimalTempMax: 13.0,
        optimalHumidityMin: 85.0,
        optimalHumidityMax: 92.0,
        maxStorageDays: 18,
        defaultPricePerKg: 30.0,
        chillingInjuryTemp: 7.5,
        storageAdvice:
            'Chilling-sensitive cucurbit. Never store below 7.5°C to prevent sunken water-soaked skin lesions. Maintain moderate cool humidity.',
        isCustom: true,
        aliases: [cropName],
      );
    }

    if (_matchesKeywords(normalized, [
      'chilli',
      'chili',
      'mirch',
      'pepper',
      'capsicum',
      'jalapeno',
      'habanero',
      'paprika',
      'pimento'
    ])) {
      return CropProfile(
        id: id,
        name: _formatTitleCase(cropName),
        category: 'Pepper & Spice',
        iconEmoji: '🌶️',
        optimalTempMin: 7.0,
        optimalTempMax: 10.0,
        optimalHumidityMin: 88.0,
        optimalHumidityMax: 95.0,
        maxStorageDays: 24,
        defaultPricePerKg: 65.0,
        chillingInjuryTemp: 5.0,
        storageAdvice:
            'Peppers are sensitive to chilling below 5°C which causes calyx rotting and surface pitting. High humidity stops skin shriveling.',
        isCustom: true,
        aliases: [cropName],
      );
    }

    if (_matchesKeywords(normalized, [
      'potato',
      'aloo',
      'alu',
      'sweet potato',
      'yam',
      'suran',
      'jimikand',
      'taro',
      'arbi',
      'cassava',
      'tapioca',
      'tuber'
    ])) {
      return CropProfile(
        id: id,
        name: _formatTitleCase(cropName),
        category: 'Tuber & Starch Crop',
        iconEmoji: '🥔',
        optimalTempMin: 8.0,
        optimalTempMax: 11.0,
        optimalHumidityMin: 85.0,
        optimalHumidityMax: 92.0,
        maxStorageDays: 120,
        defaultPricePerKg: 25.0,
        chillingInjuryTemp: 4.0,
        storageAdvice:
            'Ensure tubers are cured and dry before storing. Temperatures below 4°C induce starch sweetening and internal browning.',
        isCustom: true,
        aliases: [cropName],
      );
    }

    if (_matchesKeywords(normalized, [
      'carrot',
      'gajar',
      'beet',
      'radish',
      'mooli',
      'turnip',
      'shalgam',
      'parsnip',
      'rutabaga'
    ])) {
      return CropProfile(
        id: id,
        name: _formatTitleCase(cropName),
        category: 'Root Vegetable',
        iconEmoji: '🥕',
        optimalTempMin: 0.0,
        optimalTempMax: 2.0,
        optimalHumidityMin: 95.0,
        optimalHumidityMax: 98.0,
        maxStorageDays: 75,
        defaultPricePerKg: 30.0,
        chillingInjuryTemp: -1.0,
        storageAdvice:
            'Root crops require high relative humidity (95%+) near freezing to maintain turgor pressure and prevent core woodiness.',
        isCustom: true,
        aliases: [cropName],
      );
    }

    if (_matchesKeywords(normalized, [
      'pea',
      'matar',
      'bean',
      'sem',
      'fava',
      'gwar',
      'lobia',
      'edamame',
      'legume',
      'pod'
    ])) {
      return CropProfile(
        id: id,
        name: _formatTitleCase(cropName),
        category: 'Legume & Pod',
        iconEmoji: '🫛',
        optimalTempMin: 4.0,
        optimalTempMax: 7.0,
        optimalHumidityMin: 90.0,
        optimalHumidityMax: 95.0,
        maxStorageDays: 16,
        defaultPricePerKg: 45.0,
        chillingInjuryTemp: 2.5,
        storageAdvice:
            'Sugar converts to starch quickly if temperature exceeds 7°C. Prompt cooling preserves tender pod crispness.',
        isCustom: true,
        aliases: [cropName],
      );
    }

    if (_matchesKeywords(normalized, [
      'mushroom',
      'khumb',
      'fungi',
      'dhingri',
      'shiitake',
      'portobello',
      'morel'
    ])) {
      return CropProfile(
        id: id,
        name: _formatTitleCase(cropName),
        category: 'Mushroom / Fungi',
        iconEmoji: '🍄',
        optimalTempMin: 0.0,
        optimalTempMax: 2.0,
        optimalHumidityMin: 90.0,
        optimalHumidityMax: 95.0,
        maxStorageDays: 8,
        defaultPricePerKg: 140.0,
        chillingInjuryTemp: -1.0,
        storageAdvice:
            'Very high respiration rate. Store cold in breathable packaging. Prevent condensation droplets from falling onto caps.',
        isCustom: true,
        aliases: [cropName],
      );
    }

    if (_matchesKeywords(normalized,
        ['apple', 'pear', 'peach', 'plum', 'cherry', 'apricot', 'quince'])) {
      return CropProfile(
        id: id,
        name: _formatTitleCase(cropName),
        category: 'Deciduous Fruit',
        iconEmoji: '🍎',
        optimalTempMin: -0.5,
        optimalTempMax: 2.0,
        optimalHumidityMin: 90.0,
        optimalHumidityMax: 95.0,
        maxStorageDays: 150,
        defaultPricePerKg: 100.0,
        chillingInjuryTemp: -2.0,
        storageAdvice:
            'Ethylene producer. Keep separate from green leafy vegetables and potatoes to prevent early senescence.',
        isCustom: true,
        aliases: [cropName],
      );
    }

    if (_matchesKeywords(normalized, [
      'mango',
      'banana',
      'papaya',
      'guava',
      'pineapple',
      'jackfruit',
      'dragon',
      'passion',
      'avocado',
      'sapota',
      'chiku',
      'custard',
      'sitaphal'
    ])) {
      return CropProfile(
        id: id,
        name: _formatTitleCase(cropName),
        category: 'Tropical Fruit',
        iconEmoji: '🥭',
        optimalTempMin: 10.0,
        optimalTempMax: 13.0,
        optimalHumidityMin: 85.0,
        optimalHumidityMax: 90.0,
        maxStorageDays: 25,
        defaultPricePerKg: 60.0,
        chillingInjuryTemp: 8.0,
        storageAdvice:
            'Tropical fruits are vulnerable to severe chilling injury below 8°C. Store in moderate cool chamber to prolong freshness.',
        isCustom: true,
        aliases: [cropName],
      );
    }

    if (_matchesKeywords(normalized, [
      'orange',
      'lemon',
      'lime',
      'mandarin',
      'citrus',
      'grapefruit',
      'mosambi',
      'kinnow',
      'santra'
    ])) {
      return CropProfile(
        id: id,
        name: _formatTitleCase(cropName),
        category: 'Citrus',
        iconEmoji: '🍊',
        optimalTempMin: 5.0,
        optimalTempMax: 8.0,
        optimalHumidityMin: 85.0,
        optimalHumidityMax: 90.0,
        maxStorageDays: 45,
        defaultPricePerKg: 55.0,
        chillingInjuryTemp: 3.5,
        storageAdvice:
            'Citrus stores well at 5°C - 8°C. Ensure good ventilation to prevent peel pitting and stem end decay.',
        isCustom: true,
        aliases: [cropName],
      );
    }

    // 2. Default intelligent general vegetable fallback
    return CropProfile(
      id: id,
      name: _formatTitleCase(cropName),
      category: categoryHint ?? 'Fresh Vegetable',
      iconEmoji: '🥬',
      optimalTempMin: 4.0,
      optimalTempMax: 8.0,
      optimalHumidityMin: 90.0,
      optimalHumidityMax: 95.0,
      maxStorageDays: 21,
      defaultPricePerKg: 40.0,
      chillingInjuryTemp: 2.0,
      storageAdvice:
          'Store at standard cool vegetable chamber conditions (4°C - 8°C) with high humidity (90%+) to prevent moisture loss.',
      isCustom: true,
      aliases: [cropName],
    );
  }

  static bool _matchesKeywords(String text, List<String> keywords) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  static String _formatTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
