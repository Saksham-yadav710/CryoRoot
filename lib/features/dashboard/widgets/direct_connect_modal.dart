import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/local_device_info.dart';
import '../../../state/local_device_provider.dart';

class DirectConnectModal extends ConsumerWidget {
  const DirectConnectModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const DirectConnectModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(nearbyLocalDevicesProvider);
    final notifier = ref.read(nearbyLocalDevicesProvider.notifier);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.sensors_rounded,
                      color: AppColors.primary, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Direct Offline Sync',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.primary),
                tooltip: 'Scan for Nearby Chambers',
                onPressed: () => notifier.scanNearby(),
              ),
            ],
          ),

          const SizedBox(height: 4),
          const Text(
            'Transfer real-time sensor data from cold storage using Bluetooth (BLE) or Local Wi-Fi AP with zero internet.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 16),

          // Discovered Chambers List
          if (devices.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else
            ...devices.map((device) {
              final isConnected = device.state == LocalDeviceState.connected;
              final isSyncing = device.state == LocalDeviceState.syncing;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.primaryLight.withValues(alpha: 0.3)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isConnected
                        ? AppColors.primary
                        : AppColors.border,
                    width: isConnected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Text(device.connectionType.iconEmoji,
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                device.unitName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  device.connectionType.label,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${device.village} • Signal: ${device.signalQuality}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (device.lastSyncedAt != null)
                            Text(
                              'Last synced: ${DateFormat('hh:mm:ss a').format(device.lastSyncedAt!)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isSyncing)
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    else
                      ElevatedButton(
                        onPressed: () async {
                          final success = await notifier
                              .connectAndSyncDevice(device.unitId);
                          if (context.mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '✅ Ingested latest sensor telemetry from ${device.unitName} via ${device.connectionType.label} (No Internet)!'),
                                backgroundColor: AppColors.statusGood,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isConnected
                              ? AppColors.primary
                              : AppColors.surface,
                          foregroundColor: isConnected
                              ? Colors.white
                              : AppColors.primaryDark,
                          elevation: 0,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isConnected ? 'SYNC NOW' : 'CONNECT',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 12),

          // Offline Protocol Explanation Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.offline_bolt_rounded,
                    size: 20, color: AppColors.statusGood),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Zero Internet Mode active: Readings transfer directly over local radio frequency. Safe for remote hill farms.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
