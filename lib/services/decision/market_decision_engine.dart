import '../../models/produce_batch.dart';
import '../../models/mandi_market.dart';
import '../mock/market_data.dart';

class MarketDecisionEngine {
  static const double solarColdStorageCostPerKgPerDay = 0.25; // ₹0.25 / kg / day

  static MarketDecision evaluateBatch({
    required ProduceBatch batch,
    required double currentChamberTemp,
  }) {
    final remainingDays = batch.estimatedRemainingDays(currentChamberTemp);
    final quotes = MarketDataService.getQuotesForCrop(batch.cropProfile.id);

    // Pick Mandi with highest projected net realization
    MandiQuote bestMandi = quotes.first;
    for (final q in quotes) {
      if (q.netProfitPerKg7Days > bestMandi.netProfitPerKg7Days) {
        bestMandi = q;
      }
    }

    final double holdingDays = (remainingDays >= 7) ? 7.0 : remainingDays.toDouble();
    final double storageCostPerKg = holdingDays * solarColdStorageCostPerKgPerDay;

    final double priceDiffPerKg =
        bestMandi.projectedPrice7DaysPerKg - bestMandi.currentPricePerKg;
    final double netGainPerKg = priceDiffPerKg - storageCostPerKg - bestMandi.transportCostPerKg;
    final double totalExpectedGain = netGainPerKg * batch.quantityKg;

    // Decision Logic
    MarketDecisionType decision;
    String rationale;

    if (currentChamberTemp > 9.5 || remainingDays <= 2) {
      decision = MarketDecisionType.distressSale;
      rationale =
          'Chamber temperature is elevated or produce safe window is ending in $remainingDays days. '
          'Dispatch immediately to ${bestMandi.marketName} to protect against produce degradation.';
    } else if (netGainPerKg >= 2.0 && remainingDays >= 7) {
      decision = MarketDecisionType.holdAndStore;
      rationale =
          'Wholesale price in ${bestMandi.marketName} is projected to rise from ₹${bestMandi.currentPricePerKg.toStringAsFixed(0)}/kg to ₹${bestMandi.projectedPrice7DaysPerKg.toStringAsFixed(0)}/kg. '
          'Holding for 7 days in cold storage yields an estimated net gain of ₹${totalExpectedGain.toInt()} after storage & transport costs.';
    } else if (priceDiffPerKg < 0 || remainingDays <= 4) {
      decision = MarketDecisionType.sellNow;
      rationale =
          'Current mandi price of ₹${bestMandi.currentPricePerKg.toStringAsFixed(0)}/kg at ${bestMandi.marketName} is at a seasonal high. '
          'Selling now locks in ₹${(bestMandi.currentPricePerKg * batch.quantityKg).toInt()} before supply increases.';
    } else {
      decision = MarketDecisionType.monitorClose;
      rationale =
          'Prices across regional markets are stable with mild fluctuation. '
          'Chamber storage is optimal. Keep produce stored and re-evaluate mandi quotes in 48 hours.';
    }

    return MarketDecision(
      batchId: batch.batchId,
      cropProfile: batch.cropProfile,
      quantityKg: batch.quantityKg,
      remainingShelfLifeDays: remainingDays,
      currentChamberTemp: currentChamberTemp,
      bestMandi: bestMandi,
      decision: decision,
      rationale: rationale,
      expectedNetGainTotal: totalExpectedGain,
      dailyStorageCostTotal: batch.quantityKg * solarColdStorageCostPerKgPerDay,
      holdingDaysRecommended: holdingDays,
    );
  }
}
