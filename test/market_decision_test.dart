import 'package:flutter_test/flutter_test.dart';
import 'package:cryoroots/models/produce_batch.dart';
import 'package:cryoroots/models/mandi_market.dart';
import 'package:cryoroots/services/mock/crop_profiles_data.dart';
import 'package:cryoroots/services/decision/market_decision_engine.dart';
import 'package:cryoroots/services/mock/market_data.dart';

void main() {
  group('Market Intelligence & Economic Decision Engine Tests', () {
    test('Fetches North-East Mandi quotes across regional crops', () {
      final quotes =
          MarketDataService.getQuotesForCrop(CropProfilesData.khasiMandarin.id);

      expect(quotes.isNotEmpty, true);
      expect(quotes.any((q) => q.marketName.contains('Shillong')), true);
      expect(quotes.first.currentPricePerKg, greaterThan(50.0));
    });

    test(
        'Recommends HOLD & STORE for Khasi Mandarin with rising projected prices',
        () {
      final batch = ProduceBatch(
        batchId: 'AC-2026-00125',
        cropProfile: CropProfilesData.khasiMandarin,
        quantityKg: 1200,
        unitId: 'AC-NER-001',
        unitName: 'Cold Storage 1',
        entryDate: DateTime.now().subtract(const Duration(days: 5)),
      );

      final decision = MarketDecisionEngine.evaluateBatch(
        batch: batch,
        currentChamberTemp: 4.2,
      );

      expect(decision.decision, MarketDecisionType.holdAndStore);
      expect(decision.expectedNetGainTotal, greaterThan(0));
      expect(decision.bestMandi.marketName, contains('Shillong'));
      expect(decision.rationale, contains('projected to rise'));
    });

    test(
        'Recommends DISPATCH IMMEDIATELY (Distress Sale) when chamber warms up',
        () {
      final batch = ProduceBatch(
        batchId: 'AC-2026-00125',
        cropProfile: CropProfilesData.khasiMandarin,
        quantityKg: 1200,
        unitId: 'AC-NER-001',
        unitName: 'Cold Storage 1',
        entryDate: DateTime.now().subtract(const Duration(days: 5)),
      );

      // Elevated chamber temperature
      final decision = MarketDecisionEngine.evaluateBatch(
        batch: batch,
        currentChamberTemp: 11.5,
      );

      expect(decision.decision, MarketDecisionType.distressSale);
      expect(decision.rationale, contains('temperature is elevated'));
    });
  });
}
