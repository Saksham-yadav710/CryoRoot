import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/cold_storage_unit.dart';
import '../../../models/status_level.dart';
import '../../../models/unit_connection_state.dart';

class SelectedUnitHeroCard extends StatelessWidget {
  final ColdStorageUnit unit;
  final UnitConnectionState connectionState;
  final String freshnessText;
  final bool isPlayingAudio;
  final VoidCallback onListenPressed;
  final VoidCallback onViewDetailsPressed;

  const SelectedUnitHeroCard({
    super.key,
    required this.unit,
    required this.connectionState,
    required this.freshnessText,
    required this.isPlayingAudio,
    required this.onListenPressed,
    required this.onViewDetailsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final status = unit.status;
    final isOnline = connectionState == UnitConnectionState.live ||
        connectionState == UnitConnectionState.stale;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status == StatusLevel.good
              ? AppColors.border
              : status.borderColor,
          width: status == StatusLevel.good ? 1.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (status == StatusLevel.good ? AppColors.primary : status.color)
                    .withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Header: Unit Name, Location, and Status Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: status.backgroundColor.withValues(alpha: 0.6),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            unit.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              unit.id,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            unit.fullLocation,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 13,
                            color: AppColors.primaryDark.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Owner: ${unit.ownerFarmerName}${unit.isTechnicianAccessGranted ? ' • 🔧 Tech Authorized' : ''}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark.withValues(alpha: 0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Overall Safety Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOnline ? status.color : AppColors.statusOffline,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isOnline ? status.color : AppColors.statusOffline)
                                .withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOnline ? status.icon : Icons.cloud_off_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isOnline ? status.systemSafeLabel : 'OFFLINE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Real-Time Telemetry Connection Indicator Bar (Section 9 & 10)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: connectionState.backgroundColor.withValues(alpha: 0.5),
              border: Border(
                bottom: BorderSide(
                  color: connectionState.borderColor.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: connectionState.color,
                        shape: BoxShape.circle,
                        boxShadow: connectionState == UnitConnectionState.live
                            ? [
                                BoxShadow(
                                  color: connectionState.color
                                      .withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      connectionState.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: connectionState.color,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                Text(
                  freshnessText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // 3. Main Produce Safety Question: "Is my produce safe?"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.eco_rounded,
                  color: isOnline ? status.color : AppColors.statusOffline,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOnline
                        ? unit.produceSafetySummary
                        : 'Unit offline. Displaying last known conditions.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isOnline
                          ? (status == StatusLevel.good
                              ? AppColors.primaryDark
                              : status.color)
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Stored produce occupancy brief
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stored: ${unit.primaryProduce}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${unit.currentOccupancyKg} / ${unit.capacityKg} kg',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 5. Farmer Action Buttons: 🔊 LISTEN & VIEW DETAILED DATA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Prominent Audio Listen Button
                Expanded(
                  flex: 5,
                  child: Semantics(
                    button: true,
                    label: isPlayingAudio
                        ? 'Stop spoken voice readout'
                        : 'Listen to spoken voice overview of ${unit.name}',
                    child: ElevatedButton.icon(
                      onPressed: onListenPressed,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isPlayingAudio
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.volume_up_rounded, size: 20),
                      ),
                      label: Text(
                        isPlayingAudio ? 'STOPPING...' : '🔊 LISTEN',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPlayingAudio
                            ? AppColors.statusWarning
                            : AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Detailed Data Button (no large charts on dashboard)
                Expanded(
                  flex: 6,
                  child: OutlinedButton.icon(
                    onPressed: onViewDetailsPressed,
                    icon: const Icon(Icons.insights_rounded, size: 18),
                    label: const Text(
                      'DETAILED DATA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(
                        color: AppColors.border,
                        width: 1.2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
