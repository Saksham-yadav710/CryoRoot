import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/status_level.dart';

class TelemetryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? unit;
  final StatusLevel status;
  final String statusText;
  final String explanation;
  final IconData icon;
  final Color? accentColor;
  final Widget? trailingBadge;
  final String? updatedTimeText;
  final bool hasFault;
  final String? faultMessage;

  const TelemetryCard({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    required this.status,
    required this.statusText,
    required this.explanation,
    required this.icon,
    this.accentColor,
    this.trailingBadge,
    this.updatedTimeText,
    this.hasFault = false,
    this.faultMessage,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = hasFault
        ? AppColors.statusCritical
        : (status == StatusLevel.good ? AppColors.border : status.borderColor);

    final effectiveBgColor = hasFault
        ? AppColors.statusCriticalBg.withValues(alpha: 0.35)
        : AppColors.surface;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: effectiveBorderColor,
          width: hasFault ? 1.8 : (status == StatusLevel.good ? 1.0 : 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top: Title, Icon, & Status / Fault Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (hasFault
                          ? AppColors.statusCritical
                          : (accentColor ?? status.color))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasFault ? Icons.warning_amber_rounded : icon,
                  size: 18,
                  color: hasFault
                      ? AppColors.statusCritical
                      : (accentColor ?? status.color),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Status Badge or Fault Indicator
              if (hasFault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.statusCriticalBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.statusCriticalBorder, width: 1.0),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 10, color: AppColors.statusCritical),
                      SizedBox(width: 3),
                      Text(
                        'FAULT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.statusCritical,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: status.backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: status.borderColor, width: 0.8),
                  ),
                  child: Text(
                    statusText.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: status.color,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Middle: Large Readable Value + Update Timestamp
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: hasFault
                              ? AppColors.statusCritical
                              : AppColors.textPrimary,
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 3),
                      Text(
                        unit!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Latest update timestamp
              if (updatedTimeText != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 10, color: AppColors.textTertiary),
                      const SizedBox(width: 3),
                      Text(
                        updatedTimeText!,
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Bottom: Plain-English Explanation or Fault Diagnostic
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: hasFault
                  ? AppColors.statusCriticalBg
                  : status.backgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  hasFault ? Icons.report_problem_rounded : status.icon,
                  size: 13,
                  color: hasFault ? AppColors.statusCritical : status.color,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    hasFault
                        ? (faultMessage ?? 'Hardware fault detected. Check probe.')
                        : explanation,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: hasFault
                          ? AppColors.statusCritical
                          : (status == StatusLevel.good
                              ? AppColors.textPrimary
                              : status.color),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
