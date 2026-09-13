import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/mandi_market.dart';
import '../../../models/produce_batch.dart';
import '../../../state/produce_providers.dart';
import '../../../state/storage_providers.dart';
import '../../../state/audio_providers.dart';
import '../../../services/decision/market_decision_engine.dart';
import '../../../services/mock/market_data.dart';
import '../../../services/mock/crop_profiles_data.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(produceBatchesProvider);
    final units = ref.watch(storageUnitsProvider);
    final enhancedAudio = ref.watch(enhancedAudioControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Market Intelligence & Advisory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Mandi Prices',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Updated latest wholesale Mandi price trends.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Decision Banner (Actionable sell-or-store guidance)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trending_up_rounded,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Should I Sell Now or Store?',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (batches.isNotEmpty) {
                            final b = batches.first;
                            final u = units.firstWhere((un) => un.id == b.unitId,
                                orElse: () => units.first);
                            final d = MarketDecisionEngine.evaluateBatch(
                              batch: b,
                              currentChamberTemp: u.reading.temperature,
                            );
                            enhancedAudio.speakMarketDecision(
                              cropName: b.cropProfile.name,
                              decisionLabel: d.decision.label,
                              mandiName: d.bestMandi.marketName,
                              currentPrice: d.bestMandi.currentPricePerKg,
                              projectedPrice: d.bestMandi.projectedPrice7DaysPerKg,
                              expectedGain: d.expectedNetGainTotal,
                            );
                          }
                        },
                        icon: const Icon(Icons.volume_up_rounded, size: 16),
                        label: const Text('Audio Advisory'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          textStyle: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Our decision engine cross-references real-time chamber shelf-life degradation with live North-East APMC wholesale prices & 7-day forecasts.',
                    style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.35),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Active Batches: Sell-or-Store Decision Cards
            const Text(
              'STORED PRODUCE DECISION ADVISORIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            if (batches.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text('No produce currently in cold storage.'),
                ),
              )
            else
              ...batches.map((batch) {
                final unit = units.firstWhere(
                  (u) => u.id == batch.unitId,
                  orElse: () => units.first,
                );
                final decision = MarketDecisionEngine.evaluateBatch(
                  batch: batch,
                  currentChamberTemp: unit.reading.temperature,
                );

                return _buildBatchDecisionCard(context, batch, decision);
              }),

            const SizedBox(height: 20),

            // 3. Regional Mandi Prices Feed
            const Text(
              'REGIONAL WHOLESALE MANDI PRICES (TODAY)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            ...CropProfilesData.getProfiles().take(4).map((crop) {
              final quotes = MarketDataService.getQuotesForCrop(crop.id);
              final topQuote = quotes.first;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Text(crop.iconEmoji, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            crop.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            topQuote.marketName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${topQuote.currentPricePerKg.toStringAsFixed(0)} / kg',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              topQuote.changeLast7DaysPerKg >= 0
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 12,
                              color: topQuote.changeLast7DaysPerKg >= 0
                                  ? AppColors.statusGood
                                  : AppColors.statusCritical,
                            ),
                            Text(
                              '${topQuote.changeLast7DaysPerKg >= 0 ? "+" : ""}₹${topQuote.changeLast7DaysPerKg.toStringAsFixed(0)} (7d)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: topQuote.changeLast7DaysPerKg >= 0
                                    ? AppColors.statusGood
                                    : AppColors.statusCritical,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchDecisionCard(
    BuildContext context,
    ProduceBatch batch,
    MarketDecision decision,
  ) {
    final decisionType = decision.decision;
    final status = decisionType.statusLevel;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: status.borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: status.color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Crop + Decision Badge
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: status.backgroundColor.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Text(batch.cropProfile.iconEmoji,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.cropProfile.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Batch ${batch.batchId} • ${batch.quantityKg.toInt()} kg',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: status.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    decisionType.label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body Rationale & Financial Metrics
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  decision.rationale,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BEST MARKET',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        Text(
                          decision.bestMandi.marketName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'PROJECTED NET GAIN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        Text(
                          '₹${NumberFormat('#,##,###').format(decision.expectedNetGainTotal.toInt())}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: decision.expectedNetGainTotal >= 0
                                ? AppColors.primary
                                : AppColors.statusCritical,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/produce/detail/${batch.batchId}');
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('VIEW BATCH & DISPATCH'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
