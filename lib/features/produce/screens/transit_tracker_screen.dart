import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/transit_manifest.dart';
import '../../../state/transit_providers.dart';
import '../../../state/audio_providers.dart';

class TransitTrackerScreen extends ConsumerWidget {
  final String manifestId;

  const TransitTrackerScreen({super.key, required this.manifestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manifests = ref.watch(transitManifestsProvider);
    final TransitManifest? manifest =
        manifests.cast<TransitManifest?>().firstWhere(
              (m) => m?.manifestId == manifestId,
              orElse: () => null,
            );

    if (manifest == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Transit Tracking')),
        body: const Center(
          child: Text('Transit manifest not found.'),
        ),
      );
    }

    final isDelivered = manifest.status == TransitStatus.delivered;
    final isWarning = manifest.status == TransitStatus.temperatureWarning;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Transit ${manifest.manifestId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Bill of Lading',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Cold-Chain Bill of Lading for ${manifest.manifestId} copied to clipboard.'),
                  backgroundColor: AppColors.primary,
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
            // 1. Live Journey Progress Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isWarning
                      ? AppColors.statusWarning
                      : isDelivered
                          ? AppColors.border
                          : AppColors.primary,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          manifest.transitMode.iconEmoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${manifest.cropProfile.name} • ${manifest.quantityKg.toInt()} kg',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              manifest.transitMode.title,
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
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isWarning
                              ? AppColors.statusWarningBg
                              : isDelivered
                                  ? AppColors.border.withValues(alpha: 0.5)
                                  : AppColors.statusGoodBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          manifest.status.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
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

                  const SizedBox(height: 18),

                  // Origin -> Destination Waypoint Timeline
                  Row(
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.circle,
                              size: 14, color: AppColors.primary),
                          Container(
                            width: 2,
                            height: 28,
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                          const Icon(Icons.location_on,
                              size: 16, color: AppColors.secondary),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ORIGIN: ${manifest.originUnitName}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Departed at ${DateFormat('hh:mm a, dd MMM').format(manifest.departureTime)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'DESTINATION: ${manifest.destinationMandi}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Est. Arrival: ${DateFormat('hh:mm a, dd MMM').format(manifest.estimatedArrivalTime)} (${manifest.remainingTime.inMinutes} mins remaining)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: manifest.journeyProgressPercent,
                      minHeight: 8,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isWarning ? AppColors.statusWarning : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Live In-Transit Thermal & Power Telemetry Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LIVE COLD-CHAIN TELEMETRY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Temperature Box
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isWarning
                                ? AppColors.statusWarningBg
                                : AppColors.primaryLight.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isWarning
                                  ? AppColors.statusWarning
                                  : AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.thermostat_rounded,
                                    size: 16,
                                    color: isWarning
                                        ? AppColors.statusWarning
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Transit Temp',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${manifest.currentTemp.toStringAsFixed(1)}°C',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isWarning
                                      ? AppColors.statusWarning
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Optimal: ${manifest.cropProfile.optimalTempMin}°C - ${manifest.cropProfile.optimalTempMax}°C',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Reserve / Battery Box
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    manifest.transitMode.hasActiveCooling
                                        ? Icons.battery_charging_full_rounded
                                        : Icons.ac_unit_rounded,
                                    size: 16,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    manifest.transitMode.hasActiveCooling
                                        ? 'Battery Life'
                                        : 'PCM Reserve',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${manifest.batteryOrPcmHours.toStringAsFixed(1)} hrs',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Text(
                                'Continuous cold backup',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Digital Cold Chain Quality Certificate
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 20, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'QUALITY & BUYER MANIFEST',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          manifest.verifiedQualityGrade,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow('Vehicle Number', manifest.vehicleNumber),
                  _buildDetailRow('Carrier Driver', manifest.driverName),
                  _buildDetailRow('Driver Phone', manifest.driverPhone),
                  _buildDetailRow('Est. Consignment Value',
                      '₹${NumberFormat('#,##,###').format(manifest.estimatedTotalValue.toInt())}'),
                  if (manifest.buyerNotes.isNotEmpty)
                    _buildDetailRow('Consignment Notes', manifest.buyerNotes),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Driver / Voice Advisory Button
            OutlinedButton.icon(
              onPressed: () {
                ref.read(enhancedAudioControllerProvider).speakTransitAdvisory(
                      cropName: manifest.cropProfile.name,
                      destinationMandi: manifest.destinationMandi,
                      currentTemp: manifest.currentTemp,
                      batteryOrPcmHours: manifest.batteryOrPcmHours,
                      statusLabel: manifest.status.label,
                    );
              },
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('PLAY VOICE STATUS ADVISORY'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primaryDark,
              ),
            ),

            const SizedBox(height: 12),

            // Mark Delivered Button (if not already delivered)
            if (!isDelivered)
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(transitManifestsProvider.notifier)
                        .markDelivered(manifest.manifestId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Consignment ${manifest.manifestId} marked as DELIVERED at ${manifest.destinationMandi}!'),
                        backgroundColor: AppColors.statusGood,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text(
                    'CONFIRM MANDI DELIVERY & RECEIPT',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusGood,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
