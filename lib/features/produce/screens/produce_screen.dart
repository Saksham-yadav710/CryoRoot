import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/produce_batch.dart';
import '../../../models/transit_manifest.dart';
import '../../../models/status_level.dart';
import '../../../state/produce_providers.dart';
import '../../../state/storage_providers.dart';
import '../../../state/transit_providers.dart';

final produceTabSelectionProvider = StateProvider<int>((ref) => 0);

class ProduceScreen extends ConsumerWidget {
  const ProduceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(filteredProduceBatchesProvider);
    final metrics = ref.watch(farmProduceMetricsProvider);
    final units = ref.watch(storageUnitsProvider);
    final selectedFilterUnitId = ref.watch(produceFilterUnitIdProvider);
    final selectedTab = ref.watch(produceTabSelectionProvider);
    final transits = ref.watch(transitManifestsProvider);
    final activeTransits = ref.watch(activeTransitsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Produce & Cold Chain'),
      ),
      floatingActionButton: selectedTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/produce/add'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'INTAKE PRODUCE',
                style:
                    TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.4),
              ),
            )
          : null,
      body: Column(
        children: [
          // 1. Farm Inventory Summary Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL PRODUCE STORED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${NumberFormat('#,##,###').format(metrics.totalKg.toInt())} kg',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Across ${metrics.totalBatches} batches • ${activeTransits.length} en-route',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white70),
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
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${NumberFormat('#,##,###').format(metrics.totalEstimatedValuation.toInt())}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF86EFAC),
                      ),
                    ),
                    const Text(
                      'Wholesale market baseline',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Segmented Mode Selector (Storage vs Cold Transit)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => ref
                          .read(produceTabSelectionProvider.notifier)
                          .state = 0,
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selectedTab == 0
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'In Storage (${ref.watch(produceBatchesProvider).length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: selectedTab == 0
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => ref
                          .read(produceTabSelectionProvider.notifier)
                          .state = 1,
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selectedTab == 1
                              ? AppColors.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Cold Transit (${activeTransits.length})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: selectedTab == 1
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                            if (activeTransits.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4ADE80),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (selectedTab == 0) ...[
            // Storage Search & Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                height: 38,
                child: TextField(
                  onChanged: (val) {
                    ref.read(produceSearchQueryProvider.notifier).state = val;
                  },
                  decoration: InputDecoration(
                    hintText: 'Search crop, batch ID, or unit...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
            ),

            // Storage Unit Filter Chips
            SizedBox(
              height: 40,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip(
                    label:
                        'All Units (${ref.watch(produceBatchesProvider).length})',
                    isSelected: selectedFilterUnitId == null,
                    onSelected: () => ref
                        .read(produceFilterUnitIdProvider.notifier)
                        .state = null,
                  ),
                  ...units.map((u) {
                    final count = ref
                        .watch(produceBatchesProvider)
                        .where((b) => b.unitId == u.id)
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildFilterChip(
                        label: '${u.name} ($count)',
                        isSelected: selectedFilterUnitId == u.id,
                        onSelected: () => ref
                            .read(produceFilterUnitIdProvider.notifier)
                            .state = u.id,
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Batches List View
            Expanded(
              child: batches.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 52, color: AppColors.textTertiary),
                          SizedBox(height: 12),
                          Text(
                            'No produce batches found',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap + INTAKE PRODUCE to record incoming crop harvest.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount: batches.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final batch = batches[index];
                        final unit = units.firstWhere(
                          (u) => u.id == batch.unitId,
                          orElse: () => units.first,
                        );
                        final currentTemp = unit.reading.temperature;
                        final currentHumidity = unit.reading.humidity;
                        final condition =
                            batch.condition(currentTemp, currentHumidity);
                        final remainingDays =
                            batch.estimatedRemainingDays(currentTemp);

                        return _buildBatchTile(
                          context: context,
                          batch: batch,
                          unit: unit,
                          condition: condition,
                          remainingDays: remainingDays,
                        );
                      },
                    ),
            ),
          ] else ...[
            // Cold Chain Transits Tab
            Expanded(
              child: transits.isEmpty
                  ? const Center(
                      child: Text('No active cold-chain transits currently.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                      itemCount: transits.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final manifest = transits[index];
                        return _buildTransitTile(context, manifest);
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primaryContainer,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildBatchTile({
    required BuildContext context,
    required ProduceBatch batch,
    required dynamic unit,
    required StatusLevel condition,
    required int remainingDays,
  }) {
    return InkWell(
      onTap: () => context.push('/produce/detail/${batch.batchId}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: condition == StatusLevel.good
                ? AppColors.border
                : condition.borderColor,
            width: condition == StatusLevel.good ? 1.0 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    batch.cropProfile.iconEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            batch.cropProfile.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: condition.backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              condition.label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: condition.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Batch ${batch.batchId} • ${batch.unitName}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quantity',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textTertiary)),
                    Text(
                      '${batch.quantityKg.toInt()} kg',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Storage Age',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textTertiary)),
                    Text(
                      '${batch.storageAgeDays} days ago',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Remaining Window',
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textTertiary)),
                    Text(
                      '$remainingDays days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: remainingDays <= 5
                            ? AppColors.statusWarning
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitTile(BuildContext context, TransitManifest manifest) {
    final isWarning = manifest.status == TransitStatus.temperatureWarning;
    final isDelivered = manifest.status == TransitStatus.delivered;

    return InkWell(
      onTap: () => context.push('/produce/transit/${manifest.manifestId}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isWarning
                ? AppColors.statusWarning
                : isDelivered
                    ? AppColors.border
                    : AppColors.primary.withValues(alpha: 0.5),
            width: isWarning ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(manifest.transitMode.iconEmoji,
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${manifest.cropProfile.name} (${manifest.quantityKg.toInt()} kg)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Manifest ${manifest.manifestId} • ${manifest.vehicleNumber}',
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
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isWarning
                        ? AppColors.statusWarningBg
                        : isDelivered
                            ? AppColors.border.withValues(alpha: 0.5)
                            : AppColors.statusGoodBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    manifest.status.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isWarning
                          ? AppColors.statusWarning
                          : isDelivered
                              ? AppColors.textSecondary
                              : AppColors.statusGood,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Destination Mandi',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        Text(
                          manifest.destinationMandi,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Transit Temp',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      Text(
                        '${manifest.currentTemp.toStringAsFixed(1)}°C',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isWarning
                              ? AppColors.statusWarning
                              : AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: manifest.journeyProgressPercent,
                      minHeight: 5,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isWarning ? AppColors.statusWarning : AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(manifest.journeyProgressPercent * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
