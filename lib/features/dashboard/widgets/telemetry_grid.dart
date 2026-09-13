import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/sensor_reading.dart';
import 'telemetry_card.dart';

class TelemetryGrid extends StatelessWidget {
  final SensorReading reading;

  const TelemetryGrid({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KEY STORAGE CONDITIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          // 2-Column Responsive Grid of Telemetry Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.08,
            children: [
              // 1. Temperature Card
              TelemetryCard(
                title: 'Temperature',
                value: '${reading.temperature.toStringAsFixed(1)}°C',
                status: reading.temperatureStatus,
                statusText: reading.temperatureStatus.label,
                explanation: reading.temperatureExplanation,
                icon: Icons.thermostat_rounded,
                accentColor: AppColors.secondary,
              ),

              // 2. Humidity Card
              TelemetryCard(
                title: 'Humidity',
                value: '${reading.humidity.toInt()}%',
                status: reading.humidityStatus,
                statusText: reading.humidityStatus.label,
                explanation: reading.humidityExplanation,
                icon: Icons.water_drop_rounded,
                accentColor: const Color(0xFF0284C7),
              ),

              // 3. Battery Card
              TelemetryCard(
                title: 'Battery',
                value: '${reading.battery}%',
                status: reading.batteryStatus,
                statusText: reading.batteryStatus.label,
                explanation: reading.batteryExplanation,
                icon: Icons.battery_charging_full_rounded,
                accentColor: AppColors.statusGood,
              ),

              // 4. Solar Power Card
              TelemetryCard(
                title: 'Solar Power',
                value: '${reading.solarPower}',
                unit: 'W',
                status: reading.solarStatus,
                statusText: reading.solarPower > 0 ? 'ACTIVE' : 'INACTIVE',
                explanation: reading.solarExplanation,
                icon: Icons.solar_power_rounded,
                accentColor: AppColors.solarGold,
              ),

              // 5. Grid Power Card (Clear Outage Alert)
              TelemetryCard(
                title: 'Grid Power',
                value: reading.gridPower ? 'ON' : 'OUTAGE',
                status: reading.gridStatus,
                statusText: reading.gridPower ? 'CONNECTED' : 'OFFLINE',
                explanation: reading.gridExplanation,
                icon: reading.gridPower
                    ? Icons.power_rounded
                    : Icons.power_off_rounded,
                accentColor: reading.gridPower
                    ? AppColors.primary
                    : AppColors.statusWarning,
              ),

              // 6. PCM Backup Card (Cold Reserve)
              TelemetryCard(
                title: 'PCM Backup',
                value: reading.formattedPcmHours,
                status: reading.pcmStatus,
                statusText: reading.pcmStatus.systemSafeLabel,
                explanation: reading.pcmExplanation,
                icon: Icons.ac_unit_rounded,
                accentColor: AppColors.pcmCyan,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Secondary Row: Door Status & Water Level (Compact)
          Row(
            children: [
              // Door Status
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: reading.doorOpen
                        ? AppColors.statusWarningBg
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: reading.doorOpen
                          ? AppColors.statusWarningBorder
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        reading.doorOpen
                            ? Icons.door_front_door_outlined
                            : Icons.meeting_room_rounded,
                        size: 18,
                        color: reading.doorOpen
                            ? AppColors.statusWarning
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DOOR: ${reading.doorOpen ? 'OPEN' : 'CLOSED'}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: reading.doorOpen
                                    ? AppColors.statusWarning
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              reading.doorExplanation,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Water Level
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.opacity_rounded,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WATER: ${reading.waterLevel}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Humidifier tank level',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
    );
  }
}
