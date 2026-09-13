import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/cold_storage_unit.dart';
import '../../../models/status_level.dart';
import '../../../state/storage_providers.dart';

class OverallStatusBanner extends StatelessWidget {
  final OverallSystemSummary summary;
  final List<ColdStorageUnit>? units;
  final ValueChanged<String>? onUnitTapped;

  const OverallStatusBanner({
    super.key,
    required this.summary,
    this.units,
    this.onUnitTapped,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAllSafe = summary.allSafe;
    final bool hasOffline = summary.offlineUnits > 0;

    final Color bgColor = isAllSafe
        ? AppColors.statusGoodBg
        : (summary.criticalUnits > 0
            ? AppColors.statusCriticalBg
            : AppColors.statusAttentionBg);

    final Color borderColor = isAllSafe
        ? AppColors.statusGoodBorder
        : (summary.criticalUnits > 0
            ? AppColors.statusCriticalBorder
            : AppColors.statusAttentionBorder);

    final Color textColor = isAllSafe
        ? AppColors.statusGood
        : (summary.criticalUnits > 0
            ? AppColors.statusCritical
            : AppColors.statusAttention);

    final IconData icon = isAllSafe
        ? Icons.check_circle_rounded
        : (summary.criticalUnits > 0
            ? Icons.error_rounded
            : Icons.warning_amber_rounded);

    // Identify problematic units
    final problematicUnits = units
            ?.where((u) => u.status != StatusLevel.good || !u.reading.isOnline)
            .toList() ??
        [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'FARM STORAGE OVERVIEW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary.summaryHeadline,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Live / Connectivity Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasOffline
                        ? AppColors.statusOfflineBorder
                        : AppColors.statusGoodBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: hasOffline
                            ? AppColors.statusAttention
                            : AppColors.statusGood,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      summary.connectivitySummary,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: hasOffline
                            ? AppColors.statusAttention
                            : AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Problematic or offline unit callouts (if any)
          if (problematicUnits.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: problematicUnits.map((u) {
                final isOffline = !u.reading.isOnline;
                final badgeColor = isOffline
                    ? AppColors.statusOffline
                    : (u.status == StatusLevel.critical
                        ? AppColors.statusCritical
                        : AppColors.statusAttention);

                return InkWell(
                  onTap: () => onUnitTapped?.call(u.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor, width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOffline
                              ? Icons.sensors_off_rounded
                              : Icons.warning_rounded,
                          size: 12,
                          color: badgeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${u.name}: ${isOffline ? 'OFFLINE' : u.status.label}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
