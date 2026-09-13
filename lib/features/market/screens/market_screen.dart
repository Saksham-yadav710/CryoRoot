import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/mandi_market.dart';
import '../../../models/produce_batch.dart';
import '../../../models/cold_storage_unit.dart';
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
                  const SizedBox(height: 6),
                  const Text(
                    'Real-time economic advisory balancing storage power costs against 7-day APMC mandi price forecasts.',
                    style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
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

                return _buildBatchDecisionCard(context, ref, batch, decision, unit);
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
    WidgetRef ref,
    ProduceBatch batch,
    MarketDecision decision,
    ColdStorageUnit unit,
  ) {
    final decisionType = decision.decision;
    final status = decisionType.statusLevel;
    final isGainPositive = decision.expectedNetGainTotal >= 0;

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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () =>
              _showBatchMarketDetailModal(context, ref, batch, decision, unit),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Crop + Weight + Decision Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: status.backgroundColor.withValues(alpha: 0.7),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    Text(batch.cropProfile.iconEmoji,
                        style: const TextStyle(fontSize: 24)),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
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

              // Key Glanceable Details (No Text Overload)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  children: [
                    // Metrics Row: Best Mandi & Projected Profit/Loss
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Target Mandi
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.storefront_outlined,
                                      size: 13, color: AppColors.textTertiary),
                                  SizedBox(width: 4),
                                  Text(
                                    'BEST MANDI',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textTertiary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                decision.bestMandi.marketName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Center: Mandi Rate
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'MANDI RATE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textTertiary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${decision.bestMandi.currentPricePerKg.toStringAsFixed(0)}/kg',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right: Net Gain/Loss
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'NET 7D GAIN',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textTertiary,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${isGainPositive ? "+" : ""}₹${NumberFormat('#,##,###').format(decision.expectedNetGainTotal.toInt())}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: isGainPositive
                                    ? AppColors.primary
                                    : AppColors.statusCritical,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    const SizedBox(height: 8),

                    // Tap Affordance Hint
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tap to view economic analysis & dispatch',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBatchMarketDetailModal(
    BuildContext context,
    WidgetRef ref,
    ProduceBatch batch,
    MarketDecision decision,
    ColdStorageUnit unit,
  ) {
    final decisionType = decision.decision;
    final status = decisionType.statusLevel;
    final isGainPositive = decision.expectedNetGainTotal >= 0;
    final enhancedAudio = ref.read(enhancedAudioControllerProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header: Crop & Decision Pill
              Row(
                children: [
                  Text(batch.cropProfile.iconEmoji,
                      style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batch.cropProfile.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Batch ${batch.batchId} • ${batch.quantityKg.toInt()} kg in ${batch.unitName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: status.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      decisionType.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Market Economic Rationale Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: status.backgroundColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: status.borderColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology_rounded,
                            size: 16, color: status.color),
                        const SizedBox(width: 6),
                        Text(
                          'AI ECONOMIC RATIONALE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: status.color,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      decision.rationale,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Detailed Financial Breakdown Grid
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildDetailModalRow(
                      label: 'Target Wholesale Mandi',
                      value: decision.bestMandi.marketName,
                      isBold: true,
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    _buildDetailModalRow(
                      label: 'Current Mandi Price',
                      value: '₹${decision.bestMandi.currentPricePerKg.toStringAsFixed(0)} / kg',
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    _buildDetailModalRow(
                      label: 'Projected 7-Day Price',
                      value: '₹${decision.bestMandi.projectedPrice7DaysPerKg.toStringAsFixed(0)} / kg',
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    _buildDetailModalRow(
                      label: 'Estimated 7-Day Net EVA Gain',
                      value:
                          '${isGainPositive ? "+" : ""}₹${NumberFormat('#,##,###').format(decision.expectedNetGainTotal.toInt())}',
                      valueColor: isGainPositive
                          ? AppColors.primary
                          : AppColors.statusCritical,
                      isBold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Action Buttons: Audio Listen & Dispatch
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        enhancedAudio.speakMarketDecision(
                          cropName: batch.cropProfile.name,
                          decisionLabel: decision.decision.label,
                          mandiName: decision.bestMandi.marketName,
                          currentPrice: decision.bestMandi.currentPricePerKg,
                          projectedPrice:
                              decision.bestMandi.projectedPrice7DaysPerKg,
                          expectedGain: decision.expectedNetGainTotal,
                        );
                      },
                      icon: const Icon(Icons.volume_up_rounded, size: 18),
                      label: const Text('LISTEN ADVISORY'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/produce/detail/${batch.batchId}');
                      },
                      icon: const Icon(Icons.local_shipping_rounded, size: 18),
                      label: const Text('VIEW & DISPATCH'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailModalRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
