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
    final reading = unit.reading;

    // Determine specific cause and action
    String problemHeadline = 'Storage Operating Within Safe Limits';
    String? possibleCause;
    String recommendedAction = unit.recommendedAction;

    if (reading.doorOpen && reading.temperature > 8.0) {
      problemHeadline = 'Temperature is too high.';
      possibleCause = 'Storage door may be open.';
      recommendedAction = 'Check and close the storage door immediately.';
    } else if (reading.doorOpen) {
      problemHeadline = 'Chamber door is left open.';
      possibleCause = 'Door seal not engaged after produce loading.';
      recommendedAction = 'Close the door to prevent cold air loss.';
    } else if (!reading.gridPower) {
      problemHeadline = 'Grid power outage in progress.';
      possibleCause = 'Main utility line disconnected in local area.';
      recommendedAction =
          'PCM backup is active (${reading.displayPcmHours} left). Avoid opening the door.';
    } else if (reading.temperature > 8.0) {
      problemHeadline =
          'Chamber temperature is elevated (${reading.displayTemperature}).';
      possibleCause = 'High ambient heat or compressor load.';
      recommendedAction = 'Inspect cooling ventilation and seal.';
    } else if (reading.battery < 20) {
      problemHeadline = 'Battery reserve is low (${reading.displayBattery}).';
      possibleCause = 'Heavy inverter load or reduced solar generation.';
      recommendedAction =
          'Reduce secondary loads until solar charging resumes.';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: requiresAction ? status.backgroundColor : AppColors.statusGoodBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              requiresAction ? status.borderColor : AppColors.statusGoodBorder,
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge: 🟢 NO ACTION NEEDED vs 🔴 ACTION REQUIRED
          Row(
            children: [
              Icon(
                requiresAction
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_rounded,
                color: requiresAction ? status.color : AppColors.statusGood,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                requiresAction ? '🔴 ACTION REQUIRED' : '🟢 NO ACTION NEEDED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: requiresAction ? status.color : AppColors.statusGood,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Problem / Status Headline
          Text(
            problemHeadline,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),

          // Possible Cause (if problematic)
          if (requiresAction && possibleCause != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Possible cause: ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    possibleCause,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 6),

          // Recommended Action
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                requiresAction ? 'Recommended action: ' : 'Status: ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color:
                      requiresAction ? status.color : AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: Text(
                  recommendedAction,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),

          // "WHAT SHOULD I DO?" Interactive Button
          if (requiresAction) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onActionDetailsPressed,
                icon: const Icon(Icons.help_outline_rounded, size: 16),
                label: const Text(
                  'WHAT SHOULD I DO?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: status.color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
