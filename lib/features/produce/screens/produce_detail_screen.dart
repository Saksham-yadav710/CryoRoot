import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/status_level.dart';
import '../../../models/produce_batch.dart';
import '../../../models/cold_storage_unit.dart';
import '../../../state/produce_providers.dart';
import '../../../state/storage_providers.dart';
import '../../../state/audio_providers.dart';

class ProduceDetailScreen extends ConsumerWidget {
  final String batchId;

  const ProduceDetailScreen({super.key, required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(produceBatchesProvider);
    final units = ref.watch(storageUnitsProvider);
    final isAudioPlaying = ref.watch(isAudioPlayingProvider);
    final enhancedAudio = ref.watch(enhancedAudioControllerProvider);

    final ProduceBatch? batch = batches.cast<ProduceBatch?>().firstWhere(
          (b) => b?.batchId == batchId,
          orElse: () => null,
        );

    if (batch == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Batch Details')),
        body: const Center(
          child: Text('Produce batch not found or already dispatched.'),
        ),
      );
    }

    final ColdStorageUnit unit = units.firstWhere(
      (u) => u.id == batch.unitId,
      orElse: () => units.first,
    );

    final currentTemp = unit.reading.temperature;
    final currentHumidity = unit.reading.humidity;
    final StatusLevel condition = batch.condition(currentTemp, currentHumidity);
    final String explanation =
        batch.conditionExplanation(currentTemp, currentHumidity);
    final int remainingDays = batch.estimatedRemainingDays(currentTemp);
    final double progress = batch.shelfLifeProgress(currentTemp);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${batch.cropProfile.name} ($batchId)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sharing batch summary for $batchId'),
                  duration: const Duration(seconds: 1),
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
            // 1. Hero Crop Batch Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: condition == StatusLevel.good
                      ? AppColors.border
                      : condition.borderColor,
                  width: condition == StatusLevel.good ? 1.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: condition.color.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          batch.cropProfile.iconEmoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              batch.cropProfile.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${batch.cropProfile.category} • Batch $batchId',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Location: ${batch.unitName} (${unit.village})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: condition.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: condition.borderColor, width: 0.8),
                        ),
                        child: Text(
                          condition.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: condition.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Quantity & Market Valuation Row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'STORED QUANTITY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            Text(
                              '${batch.quantityKg.toInt()} kg',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'ESTIMATED VALUE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            Text(
                              '₹${NumberFormat('#,##,###').format(batch.estimatedMarketValue)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. Audio Produce Health Briefing Button
            ElevatedButton.icon(
              onPressed: () {
                if (isAudioPlaying) {
                  enhancedAudio.stop();
                } else {
                  enhancedAudio.speakProduceReport(
                    batch: batch,
                    currentTemp: currentTemp,
                    remainingDays: remainingDays,
                  );
                }
              },
              icon: Icon(
                isAudioPlaying ? Icons.stop_rounded : Icons.volume_up_rounded,
                size: 20,
              ),
              label: Text(
                isAudioPlaying ? 'STOP AUDIO' : '🔊 LISTEN TO PRODUCE REPORT',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. Storage Age & Safe Window Countdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STORAGE WINDOW & SHELF LIFE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Storage Age',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          Text(
                            '${batch.storageAgeDays} Days',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Entered: ${DateFormat('dd MMM yyyy').format(batch.entryDate)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Remaining Safe Window',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          Text(
                            '$remainingDays Days',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: remainingDays <= 5
                                  ? AppColors.statusWarning
                                  : AppColors.primary,
                            ),
                          ),
                          Text(
                            'Max: ${batch.cropProfile.maxStorageDays} Days',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: AppColors.primaryLight,
                      color: progress > 0.8
                          ? AppColors.statusWarning
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(progress * 100).toInt()}% of safe storage window elapsed',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Current Chamber Conditions vs Optimal Profile
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHAMBER CONDITION EVALUATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    explanation,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: condition == StatusLevel.good
                          ? AppColors.textPrimary
                          : condition.color,
                      height: 1.3,
                    ),
                  ),
                  const Divider(height: 20),
                  _buildComparisonRow(
                    label: 'Current Chamber Temperature',
                    current: '${currentTemp.toStringAsFixed(1)}°C',
                    optimal: batch.cropProfile.tempRangeFormatted,
                    isGood: currentTemp >= batch.cropProfile.optimalTempMin &&
                        currentTemp <= batch.cropProfile.optimalTempMax,
                  ),
                  const Divider(height: 16),
                  _buildComparisonRow(
                    label: 'Current Chamber Humidity',
                    current: '${currentHumidity.toInt()}%',
                    optimal: batch.cropProfile.humidityRangeFormatted,
                    isGood: currentHumidity >=
                            batch.cropProfile.optimalHumidityMin &&
                        currentHumidity <= batch.cropProfile.optimalHumidityMax,
                  ),
                  const Divider(height: 16),
                  _buildComparisonRow(
                    label: 'Chilling Injury Threshold',
                    current:
                        'Safe (> ${batch.cropProfile.chillingInjuryTemp}°C)',
                    optimal: 'Min ${batch.cropProfile.chillingInjuryTemp}°C',
                    isGood: currentTemp >= batch.cropProfile.chillingInjuryTemp,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 5. Actions: View Market & Dispatch
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Market Intelligence pricing comparison will open in Milestone 8.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    label: const Text('VIEW MARKET'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showDispatchConfirmModal(context, ref, batch),
                    icon: const Icon(Icons.local_shipping_rounded, size: 18),
                    label: const Text('DISPATCH'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow({
    required String label,
    required String current,
    required String optimal,
    required bool isGood,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Optimal: $optimal',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color:
                isGood ? AppColors.statusGoodBg : AppColors.statusAttentionBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            current,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isGood ? AppColors.statusGood : AppColors.statusAttention,
            ),
          ),
        ),
      ],
    );
  }

  void _showDispatchConfirmModal(
    BuildContext context,
    WidgetRef ref,
    ProduceBatch batch,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping_rounded,
                      color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Dispatch Batch ${batch.batchId}?',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'You are preparing to dispatch ${batch.quantityKg.toInt()} kg of ${batch.cropProfile.name} from ${batch.unitName}.',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),

              // Option 1: Full Cold-Chain Transit Tracking
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                tileColor: AppColors.primaryLight.withValues(alpha: 0.3),
                leading: const Icon(Icons.satellite_alt_rounded,
                    color: AppColors.primary),
                title: const Text(
                  'Launch Cold-Chain Transit Tracking',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                subtitle: const Text(
                  'Assign Reefer/Crate, Mandi destination & live thermal tracking',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                trailing:
                    const Icon(Icons.chevron_right, color: AppColors.primary),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/produce/dispatch/${batch.batchId}');
                },
              ),

              const SizedBox(height: 10),

              // Option 2: Quick Local Direct Sale
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                leading: const Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.textSecondary),
                title: const Text(
                  'Mark as Sold (Local Farmgate)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Immediate checkout without transport telemetry',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                onTap: () {
                  ref
                      .read(produceBatchesProvider.notifier)
                      .dispatchBatch(batch.batchId);
                  Navigator.pop(context);
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Batch ${batch.batchId} marked as sold and removed from cold storage.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
