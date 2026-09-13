import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/cold_storage_unit.dart';

class FarmerSensorHealthCard extends StatelessWidget {
  final ColdStorageUnit unit;

  const FarmerSensorHealthCard({
    super.key,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final reading = unit.reading;
    final hasAnyFault = reading.hasTemperatureFault ||
        reading.hasHumidityFault ||
        reading.hasBatteryFault ||
        reading.hasSolarFault;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAnyFault ? AppColors.statusCriticalBorder : AppColors.border,
          width: hasAnyFault ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: hasAnyFault
                          ? AppColors.statusCriticalBg
                          : AppColors.statusGoodBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      hasAnyFault
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                      color: hasAnyFault
                          ? AppColors.statusCritical
                          : AppColors.statusGood,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STORAGE SENSORS HEALTH',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Farmer Glanceable Status',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasAnyFault
                      ? AppColors.statusCriticalBg
                      : AppColors.statusGoodBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: hasAnyFault
                        ? AppColors.statusCriticalBorder
                        : AppColors.statusGoodBorder,
                  ),
                ),
                child: Text(
                  hasAnyFault ? 'FAULT DETECTED' : 'ALL WORKING WELL',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: hasAnyFault
                        ? AppColors.statusCritical
                        : AppColors.statusGood,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 1. Temperature Sensor
          _buildFarmerSensorItem(
            name: 'Temperature Sensor (Chamber Core)',
            icon: Icons.thermostat_rounded,
            hasFault: reading.hasTemperatureFault,
            faultReason: reading.temperatureFaultReason,
            healthySubtitle: 'Accurate reading: ${reading.displayTemperature}',
            advice:
                'Check probe wire plug at chamber socket T1. Ensure cable is not pinched by the door.',
          ),

          const Divider(height: 16),

          // 2. Humidity Sensor
          _buildFarmerSensorItem(
            name: 'Humidity Sensor (Moisture Probe)',
            icon: Icons.water_drop_rounded,
            hasFault: reading.hasHumidityFault,
            faultReason: reading.humidityFaultReason,
            healthySubtitle: 'Accurate reading: ${reading.displayHumidity}',
            advice:
                'Inspect sensor tip for ice build-up or dirt. Gently wipe with dry cloth.',
          ),

          const Divider(height: 16),

          // 3. Battery BMS Monitor
          _buildFarmerSensorItem(
            name: 'Battery Monitor (BMS Telemetry)',
            icon: Icons.battery_charging_full_rounded,
            hasFault: reading.hasBatteryFault,
            faultReason: reading.batteryFaultReason,
            healthySubtitle: 'Charge reported: ${reading.displayBattery}',
            advice:
                'Check battery terminal connections and main DC isolator switch.',
          ),

          const Divider(height: 16),

          // 4. Solar Power Monitor
          _buildFarmerSensorItem(
            name: 'Solar MPPT Link',
            icon: Icons.solar_power_rounded,
            hasFault: reading.hasSolarFault,
            faultReason: reading.solarFaultReason,
            healthySubtitle: 'Generation reported: ${reading.displaySolar}',
            advice:
                'Check rooftop solar disconnect switch and look for shaded panels.',
          ),

          const Divider(height: 16),

          // 5. Door Magnetic Seal Sensor
          _buildFarmerSensorItem(
            name: 'Door Magnetic Sensor',
            icon: Icons.meeting_room_rounded,
            hasFault: false,
            faultReason: null,
            healthySubtitle:
                reading.doorOpen ? 'Door is currently open' : 'Door is closed & sealed',
            advice: '',
          ),

          const Divider(height: 16),

          // 6. PCM Backup Thermal Sensor
          _buildFarmerSensorItem(
            name: 'PCM Cold Backup Sensor',
            icon: Icons.ac_unit_rounded,
            hasFault: false,
            faultReason: null,
            healthySubtitle:
                'Reserve: ${reading.formattedPcmHours} cold backup intact',
            advice: '',
          ),

          if (hasAnyFault) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusCriticalBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.statusCriticalBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_in_talk_rounded,
                      color: AppColors.statusCritical, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need Field Technician Assistance?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.statusCritical,
                          ),
                        ),
                        Text(
                          'A local CryoRoot service technician is available 24/7.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Dialing Local Field Technician (+91 98765 43210)...',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusCritical,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800),
                      elevation: 0,
                    ),
                    child: const Text('Call Tech'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFarmerSensorItem({
    required String name,
    required IconData icon,
    required bool hasFault,
    required String? faultReason,
    required String healthySubtitle,
    required String advice,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: hasFault
                    ? AppColors.statusCriticalBg
                    : AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasFault ? Icons.error_outline_rounded : icon,
                size: 18,
                color: hasFault
                    ? AppColors.statusCritical
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    hasFault
                        ? (faultReason ?? 'Sensor communication fault')
                        : healthySubtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          hasFault ? FontWeight.w700 : FontWeight.w500,
                      color: hasFault
                          ? AppColors.statusCritical
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasFault
                    ? AppColors.statusCriticalBg
                    : AppColors.statusGoodBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: hasFault
                      ? AppColors.statusCriticalBorder
                      : AppColors.statusGoodBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: hasFault
                          ? AppColors.statusCritical
                          : AppColors.statusGood,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasFault ? 'FAULT' : 'WORKING WELL',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: hasFault
                          ? AppColors.statusCritical
                          : AppColors.statusGood,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (hasFault && advice.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 14, color: AppColors.statusAttention),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    advice,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
