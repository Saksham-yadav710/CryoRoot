import 'package:flutter_test/flutter_test.dart';
import 'package:cryoroots/models/status_level.dart';
import 'package:cryoroots/models/produce_batch.dart';
import 'package:cryoroots/services/mock/crop_profiles_data.dart';

void main() {
  group('CropProfilesData & ProduceBatch Tests', () {
    test('Retrieves all North-East crop profiles with valid parameters', () {
      final profiles = CropProfilesData.getProfiles();
      expect(profiles.length, greaterThanOrEqualTo(6));

      final tomato = profiles.firstWhere((c) => c.id == 'CROP-TOMATO');
      expect(tomato.optimalTempMin, 4.0);
      expect(tomato.optimalTempMax, 8.0);
      expect(tomato.maxStorageDays, 28);
    });

    test('Calculates remaining storage days under normal temperatures', () {
      final profiles = CropProfilesData.getProfiles();
      final tomato = profiles.firstWhere((c) => c.id == 'CROP-TOMATO');
      final now = DateTime.now();

      final batch = ProduceBatch(
        batchId: 'AC-2026-00125',
        cropProfile: tomato,
        quantityKg: 2000,
        unitId: 'AC-NER-001',
        unitName: 'Cold Storage 1',
        entryDate: now.subtract(const Duration(days: 4)),
      );

      expect(batch.storageAgeDays, 4);
      expect(batch.estimatedRemainingDays(5.0), 24); // 28 - 4 = 24
      expect(batch.condition(5.0, 92.0), StatusLevel.good);
      expect(batch.estimatedMarketValue, 2000 * 32.0);
    });

    test('Calculates accelerated shelf-life degradation under high temperature',
        () {
      final profiles = CropProfilesData.getProfiles();
      final tomato = profiles.firstWhere((c) => c.id == 'CROP-TOMATO');
      final now = DateTime.now();

      final batch = ProduceBatch(
        batchId: 'AC-2026-00125',
        cropProfile: tomato,
        quantityKg: 2000,
        unitId: 'AC-NER-003',
        unitName: 'Cold Storage 3',
        entryDate: now.subtract(const Duration(days: 4)),
      );

      // In Unit 3 with 10.5°C temp (excess: 2.5°C over 8.0°C max)
      final remaining = batch.estimatedRemainingDays(10.5);
      expect(remaining, lessThan(24));
      expect(batch.condition(10.5, 78.0), isNot(StatusLevel.good));
    });

    test('Triggers Critical status on chilling injury risk', () {
      final profiles = CropProfilesData.getProfiles();
      final ginger = profiles.firstWhere((c) => c.id == 'CROP-GINGER');
      final now = DateTime.now();

      final batch = ProduceBatch(
        batchId: 'AC-2026-00130',
        cropProfile: ginger,
        quantityKg: 500,
        unitId: 'AC-NER-001',
        unitName: 'Cold Storage 1',
        entryDate: now.subtract(const Duration(days: 1)),
      );

      // Ginger suffers chilling injury below 8°C. At 4.0°C:
      expect(batch.condition(4.0, 85.0), StatusLevel.critical);
      expect(batch.conditionExplanation(4.0, 85.0),
          contains('Chilling injury risk'));
    });
  });
}
