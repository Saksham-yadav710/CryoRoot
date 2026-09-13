import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/storage_providers.dart';

class OverallStatusBanner extends StatelessWidget {
  final OverallSystemSummary summary;

  const OverallStatusBanner({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final bool isAllSafe = summary.allSafe;
    final Color bgColor =
        isAllSafe ? AppColors.statusGoodBg : AppColors.statusAttentionBg;
    final Color borderColor = isAllSafe
        ? AppColors.statusGoodBorder
        : AppColors.statusAttentionBorder;
    final Color textColor =
        isAllSafe ? AppColors.statusGood : AppColors.statusAttention;
    final IconData icon =
        isAllSafe ? Icons.check_circle_rounded : Icons.info_outline_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
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
                Text(
                  summary.summaryHeadline,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${summary.totalUnits} Units Active',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
