import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/alert_item.dart';
import '../../../models/status_level.dart';
import '../../../state/storage_providers.dart';
import '../../../state/audio_providers.dart';
import '../widgets/action_guide_dialog.dart';
import '../../../core/widgets/responsive_layout.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(filteredAlertsProvider);
    final counts = ref.watch(alertCountsProvider);
    final units = ref.watch(storageUnitsProvider);
    final enhancedAudio = ref.watch(enhancedAudioControllerProvider);
    final selectedSeverity = ref.watch(alertSeverityFilterProvider);
    final selectedUnit = ref.watch(alertUnitFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Storage Alerts & Actions'),
      ),
      body: ResponsiveCenter(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
          // 1. Severity Summary Dashboard Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACTIVE FARM ALERTS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${counts.total} Detected',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '${counts.unacknowledged} require farmer action',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: counts.unacknowledged > 0
                            ? AppColors.statusCritical
                            : AppColors.statusGood,
                      ),
                    ),
                  ],
                ),
                // Pill Badges for Critical, Warning, Attention
                Row(
                  children: [
                    _buildCountPill(
                      label: 'CRITICAL',
                      count: counts.critical,
                      color: AppColors.statusCritical,
                      bgColor: AppColors.statusCriticalBg,
                    ),
                    const SizedBox(width: 6),
                    _buildCountPill(
                      label: 'WARNING',
                      count: counts.warning,
                      color: AppColors.statusWarning,
                      bgColor: AppColors.statusWarningBg,
                    ),
                    const SizedBox(width: 6),
                    _buildCountPill(
                      label: 'ATTENTION',
                      count: counts.attention,
                      color: AppColors.statusAttention,
                      bgColor: AppColors.statusAttentionBg,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Filter Chips (Severity & Unit)
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  label: 'All Severities (${counts.total})',
                  isSelected: selectedSeverity == null,
                  onSelected: () => ref
                      .read(alertSeverityFilterProvider.notifier)
                      .state = null,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Critical (${counts.critical})',
                  isSelected: selectedSeverity == StatusLevel.critical,
                  onSelected: () => ref
                      .read(alertSeverityFilterProvider.notifier)
                      .state = StatusLevel.critical,
                  color: AppColors.statusCritical,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Warning (${counts.warning})',
                  isSelected: selectedSeverity == StatusLevel.warning,
                  onSelected: () => ref
                      .read(alertSeverityFilterProvider.notifier)
                      .state = StatusLevel.warning,
                  color: AppColors.statusWarning,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Attention (${counts.attention})',
                  isSelected: selectedSeverity == StatusLevel.attention,
                  onSelected: () => ref
                      .read(alertSeverityFilterProvider.notifier)
                      .state = StatusLevel.attention,
                  color: AppColors.statusAttention,
                ),
              ],
            ),
          ),

          // 3. Storage Unit Filter Chips
          SizedBox(
            height: 40,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  label: 'All Units',
                  isSelected: selectedUnit == null,
                  onSelected: () =>
                      ref.read(alertUnitFilterProvider.notifier).state = null,
                ),
                ...units.map((u) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _buildFilterChip(
                      label: u.name,
                      isSelected: selectedUnit == u.id,
                      onSelected: () => ref
                          .read(alertUnitFilterProvider.notifier)
                          .state = u.id,
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 4. Alerts List
          Expanded(
            child: alerts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            size: 56, color: AppColors.statusGood),
                        SizedBox(height: 14),
                        Text(
                          'No active alerts',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'All monitored storage parameters are within safe bounds.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                    itemCount: alerts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return _buildAlertCard(
                          context, ref, alert, enhancedAudio);
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCountPill({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    Color? color,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: (color ?? AppColors.primary).withValues(alpha: 0.15),
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color:
            isSelected ? (color ?? AppColors.primary) : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? (color ?? AppColors.primary) : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    WidgetRef ref,
    AlertItem alert,
    EnhancedAudioController enhancedAudio,
  ) {
    final StatusLevel severity = alert.severity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alert.isAcknowledged
            ? AppColors.surface
            : severity.backgroundColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alert.isAcknowledged ? AppColors.border : severity.borderColor,
          width: alert.isAcknowledged ? 1.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: severity.color.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity Header + Active Duration
          Row(
            children: [
              Icon(severity.icon, color: severity.color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: severity.color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severity.color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  severity.label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                alert.unitName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Active for ${alert.duration}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Diagnostic Current vs Recommended Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current: ${alert.currentValue}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800)),
                    Text('Recommended: ${alert.expectedValue}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                const Divider(height: 10),
                Text(
                  'Possible Cause: ${alert.possibleCause}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Action: ${alert.recommendedAction}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons: WHAT SHOULD I DO? | 🔊 LISTEN | ACKNOWLEDGE
          Row(
            children: [
              // What Should I Do?
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (ctx) => ActionGuideDialog(
                      alert: alert,
                      onAcknowledge: () {
                        ref
                            .read(activeAlertsProvider.notifier)
                            .acknowledgeAlert(alert.id);
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.help_outline_rounded, size: 16),
                label: const Text(
                  'WHAT SHOULD I DO?',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: severity.color,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
              const Spacer(),
              // Listen Audio
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, size: 20),
                tooltip: 'Listen to alert',
                color: AppColors.primaryDark,
                onPressed: () {
                  enhancedAudio.speakAlert(alert);
                },
              ),
              const SizedBox(width: 4),
              // Acknowledge Button
              ElevatedButton(
                onPressed: alert.isAcknowledged
                    ? null
                    : () {
                        ref
                            .read(activeAlertsProvider.notifier)
                            .acknowledgeAlert(alert.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Alert marked as acknowledged.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: severity.color,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  alert.isAcknowledged ? 'Acknowledged' : 'Acknowledge',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
