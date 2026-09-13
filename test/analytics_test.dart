import 'package:flutter_test/flutter_test.dart';
import 'package:agricool_ner/services/mock/mock_storage_data.dart';

void main() {
  group('StorageAnalytics Data & Metrics Tests', () {
    test('Generates complete 24h analytics dataset for Cold Storage 1', () {
      final analytics = MockStorageData.getAnalyticsForUnit('AC-NER-001');

      expect(analytics.unitId, 'AC-NER-001');
      expect(analytics.temperatureHistory.isNotEmpty, true);
      expect(analytics.batteryHistory.isNotEmpty, true);
      expect(analytics.solarHistory.isNotEmpty, true);
      expect(analytics.pcmHistory.isNotEmpty, true);

      expect(analytics.minTemp <= analytics.maxTemp, true);
      expect(analytics.avgTemp, inInclusiveRange(2.0, 8.0));
      expect(analytics.deviceHealth.isAllHealthy, true);
    });

    test(
        'Correctly tracks higher temperature metrics for Unit 3 alert scenario',
        () {
      final analytics = MockStorageData.getAnalyticsForUnit('AC-NER-003');

      expect(analytics.unitId, 'AC-NER-003');
      expect(analytics.maxTemp, 10.5);
      expect(analytics.doorOpenCountToday, greaterThan(5));
      expect(analytics.doorOpenDurationMinutes, greaterThan(20.0));
    });

    test('Calculates solar peak generation correctly', () {
      final analytics = MockStorageData.getAnalyticsForUnit('AC-NER-001');

      expect(analytics.peakSolarWatts, greaterThan(400));
      expect(analytics.totalSolarGeneratedKwh, greaterThan(0));
    });
  });
}
