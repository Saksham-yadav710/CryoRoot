import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/cold_storage_unit.dart';
import '../../../models/status_level.dart';

class RecommendationCard extends StatelessWidget {
  final ColdStorageUnit unit;
  final VoidCallback onActionDetailsPressed;

  const RecommendationCard({
    super.key,
    required this.unit,
    required this.onActionDetailsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool requiresAction = unit.hasActionRequired ||
        unit.status == StatusLevel.critical ||
        unit.status == StatusLevel.warning;
    final StatusLevel status = unit.status;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: requiresAction
            ? status.backgroundColor
            : AppColors.primaryLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              requiresAction ? status.borderColor : AppColors.primaryContainer,
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                requiresAction
                    ? Icons.warning_amber_rounded
                    : Icons.task_alt_rounded,
                color: requiresAction ? status.color : AppColors.primaryDark,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                requiresAction ? 'RECOMMENDED ACTION' : 'STORAGE ADVICE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: requiresAction ? status.color : AppColors.primaryDark,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            unit.recommendedAction,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          if (requiresAction) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onActionDetailsPressed,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text(
                  'WHAT SHOULD I DO?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: status.color,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: status.borderColor),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
