import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/storage_analytics.dart';
import '../../../models/status_level.dart';

class DeviceHealthCard extends StatelessWidget {
  final DeviceHealthStatus health;
  final String deviceId;

  const DeviceHealthCard({
    super.key,
    required this.health,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DEVICE & SENSOR HEALTH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: health.isAllHealthy
                      ? AppColors.statusGoodBg
                      : AppColors.statusAttentionBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  health.isAllHealthy ? 'SYSTEM HEALTHY' : 'ATTENTION',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: health.isAllHealthy
                        ? AppColors.statusGood
                        : AppColors.statusAttention,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHealthRow(
            icon: Icons.memory_rounded,
            title: 'IoT Microcontroller (ESP32)',
            subtitle: 'Firmware: ${health.controllerFirmware}',
            status: health.controllerStatus,
          ),
          const Divider(height: 16),
          _buildHealthRow(
            icon: Icons.compress_rounded,
            title: 'Variable Compressor Unit',
            subtitle: '${health.compressorHoursRun} operating hours run',
            status: health.compressorStatus,
          ),
          const Divider(height: 16),
          _buildHealthRow(
            icon: Icons.sensors_rounded,
            title: 'Precision Temperature Sensor (NTC)',
            subtitle: 'Calibrated ±0.1°C accuracy',
            status: health.tempSensorStatus,
          ),
          const Divider(height: 16),
          _buildHealthRow(
            icon: Icons.water_drop_outlined,
            title: 'Capacitive Humidity Sensor',
            subtitle: 'Dual redundant probe',
            status: health.humiditySensorStatus,
          ),
          const Divider(height: 16),
          _buildHealthRow(
            icon: Icons.solar_power_outlined,
            title: 'Solar MPPT Inverter',
            subtitle: 'Efficiency: 96.8% conversion',
            status: health.solarInverterStatus,
          ),
          const Divider(height: 16),
          _buildHealthRow(
            icon: Icons.cell_tower_rounded,
            title: 'Telemetry Connectivity',
            subtitle:
                '${health.connectivityType} (${health.networkSignalRssi} dBm)',
            status: StatusLevel.good,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required StatusLevel status,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: status.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          status.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: status.color,
          ),
        ),
      ],
    );
  }
}
