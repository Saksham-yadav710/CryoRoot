import '../../models/crop_profile.dart';

class CropProfilesData {
  static List<CropProfile> getProfiles() {
    return const [
      CropProfile(
        id: 'CROP-TOMATO',
        name: 'Tomato',
        category: 'Solanaceous Fruit',
        iconEmoji: '🍅',
        optimalTempMin: 4.0,
        optimalTempMax: 8.0,
        optimalHumidityMin: 90.0,
        optimalHumidityMax: 95.0,
        maxStorageDays: 28,
        defaultPricePerKg: 32.0,
        chillingInjuryTemp: 2.0,
        storageAdvice:
            'Store at 4°C - 8°C with high relative humidity to prevent firmness loss and calyx drying.',
      ),
      CropProfile(
        id: 'CROP-CHILLI',
        name: 'Green Chilli',
        category: 'Spices & Condiments',
        iconEmoji: '🌶️',
        optimalTempMin: 7.0,
        optimalTempMax: 10.0,
        optimalHumidityMin: 85.0,
        optimalHumidityMax: 95.0,
        maxStorageDays: 21,
        defaultPricePerKg: 65.0,
        chillingInjuryTemp: 5.0,
        storageAdvice:
            'Sensitive to chilling injury below 5°C. Maintain moisture to prevent shriveling.',
      ),
      CropProfile(
        id: 'CROP-CABBAGE',
        name: 'Cabbage',
        category: 'Cole Crop',
        iconEmoji: '🥬',
        optimalTempMin: 0.0,
        optimalTempMax: 3.0,
        optimalHumidityMin: 90.0,
        optimalHumidityMax: 98.0,
        maxStorageDays: 60,
        defaultPricePerKg: 18.0,
        chillingInjuryTemp: -1.0,
        storageAdvice:
            'Excellent cold storage tolerance. Requires high humidity to prevent outer leaf yellowing.',
      ),
      CropProfile(
        id: 'CROP-LEAFY',
        name: 'Leafy Vegetables (Spinach/Mustard)',
        category: 'Leafy Greens',
        iconEmoji: '🌿',
        optimalTempMin: 1.0,
        optimalTempMax: 4.0,
        optimalHumidityMin: 92.0,
        optimalHumidityMax: 98.0,
        maxStorageDays: 14,
        defaultPricePerKg: 24.0,
        chillingInjuryTemp: 0.0,
        storageAdvice:
            'High respiration rate. Pre-cool rapidly and keep humidified to stop wilting.',
      ),
      CropProfile(
        id: 'CROP-GINGER',
        name: 'Ginger (Fresh Rhizomes)',
        category: 'Spices / Tuber',
        iconEmoji: '🫚',
        optimalTempMin: 10.0,
        optimalTempMax: 13.0,
        optimalHumidityMin: 80.0,
        optimalHumidityMax: 90.0,
        maxStorageDays: 90,
        defaultPricePerKg: 110.0,
        chillingInjuryTemp: 8.0,
        storageAdvice:
            'Requires moderate cool temperatures. Avoid temperatures below 8°C to prevent internal browning.',
      ),
      CropProfile(
        id: 'CROP-ORANGE',
        name: 'Khasi Mandarin Orange',
        category: 'Citrus',
        iconEmoji: '🍊',
        optimalTempMin: 4.0,
        optimalTempMax: 7.0,
        optimalHumidityMin: 85.0,
        optimalHumidityMax: 90.0,
        maxStorageDays: 45,
        defaultPricePerKg: 75.0,
        chillingInjuryTemp: 3.0,
        storageAdvice:
            'Famous NER sweet mandarin. Storage preserves juiciness and acid-to-sugar ratio.',
      ),
      CropProfile(
        id: 'CROP-BHUT-JOLOKIA',
        name: 'King Chilli / Bhut Jolokia',
        category: 'GI-Tagged Spice',
        iconEmoji: '🔥',
        optimalTempMin: 8.0,
        optimalTempMax: 11.0,
        optimalHumidityMin: 85.0,
        optimalHumidityMax: 92.0,
        maxStorageDays: 25,
        defaultPricePerKg: 280.0,
        chillingInjuryTemp: 6.0,
        storageAdvice:
            'High-value specialty crop. Cold storage prevents capsaicin degradation and moisture loss.',
      ),
      CropProfile(
        id: 'CROP-ASSAM-LEMON',
        name: 'Kaji Nemu (Assam Lemon)',
        category: 'GI-Tagged Citrus',
        iconEmoji: '🍋',
        optimalTempMin: 6.0,
        optimalTempMax: 9.0,
        optimalHumidityMin: 85.0,
        optimalHumidityMax: 92.0,
        maxStorageDays: 40,
        defaultPricePerKg: 60.0,
        chillingInjuryTemp: 4.0,
        storageAdvice:
            'Thin-skinned fragrant lemon. Store at 6°C - 9°C to retain natural aroma and freshness.',
      ),
    ];
  }

  static CropProfile getProfileById(String id) {
    return getProfiles().firstWhere(
      (p) => p.id == id,
      orElse: () => getProfiles().first,
    );
  }

  static CropProfile get tomato => getProfileById('CROP-TOMATO');
  static CropProfile get khasiMandarin => getProfileById('CROP-ORANGE');
  static CropProfile get bhutJolokia => getProfileById('CROP-BHUT-JOLOKIA');
  static CropProfile get kajiNemu => getProfileById('CROP-ASSAM-LEMON');
  static CropProfile get ginger => getProfileById('CROP-GINGER');
}
