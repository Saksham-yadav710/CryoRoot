import 'status_level.dart';
import 'crop_profile.dart';

enum MarketDecisionType {
  holdAndStore,
  sellNow,
  monitorClose,
  distressSale,
}

extension MarketDecisionTypeExtension on MarketDecisionType {
  String get label {
    switch (this) {
      case MarketDecisionType.holdAndStore:
        return 'HOLD & STORE';
      case MarketDecisionType.sellNow:
        return 'SELL NOW';
      case MarketDecisionType.monitorClose:
        return 'MONITOR PRICES';
      case MarketDecisionType.distressSale:
        return 'DISPATCH IMMEDIATELY';
    }
  }

  StatusLevel get statusLevel {
    switch (this) {
      case MarketDecisionType.holdAndStore:
        return StatusLevel.good;
      case MarketDecisionType.sellNow:
        return StatusLevel.good;
      case MarketDecisionType.monitorClose:
        return StatusLevel.attention;
      case MarketDecisionType.distressSale:
        return StatusLevel.critical;
    }
  }
}

class MandiQuote {
  final String marketName;
  final String state;
  final String district;
  final double currentPricePerKg;
  final double changeLast7DaysPerKg;
  final double projectedPrice7DaysPerKg;
  final double distanceKm;
  final double transportCostPerKg;

  const MandiQuote({
    required this.marketName,
    required this.state,
    required this.district,
    required this.currentPricePerKg,
    required this.changeLast7DaysPerKg,
    required this.projectedPrice7DaysPerKg,
    required this.distanceKm,
    required this.transportCostPerKg,
  });

  double get netProfitPerKg7Days =>
      projectedPrice7DaysPerKg - currentPricePerKg - transportCostPerKg;
}

class MarketDecision {
  final String batchId;
  final CropProfile cropProfile;
  final double quantityKg;
  final int remainingShelfLifeDays;
  final double currentChamberTemp;
  final MandiQuote bestMandi;
  final MarketDecisionType decision;
  final String rationale;
  final double expectedNetGainTotal;
  final double dailyStorageCostTotal;
  final double holdingDaysRecommended;

  const MarketDecision({
    required this.batchId,
    required this.cropProfile,
    required this.quantityKg,
    required this.remainingShelfLifeDays,
    required this.currentChamberTemp,
    required this.bestMandi,
    required this.decision,
    required this.rationale,
    required this.expectedNetGainTotal,
    required this.dailyStorageCostTotal,
    required this.holdingDaysRecommended,
  });
}
