import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/sensor_reading.dart';
import '../../../models/status_level.dart';
import 'telemetry_card.dart';

class TelemetryGrid extends StatelessWidget {
  final SensorReading reading;

  const TelemetryGrid({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final isOnline = reading.isOnline;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;
          final isMedium = constraints.maxWidth >= 520 && !isWide;
          final crossAxisCount = isWide ? 4 : 2;
          final childAspectRatio = isWide ? 1.4 : (isMedium ? 1.3 : 0.98);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'PRIMARY STORAGE CONDITIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOnline
                        ? 'VALUE + STATUS + EXPLANATION'
                        : 'OFFLINE (LAST KNOWN)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isOnline
                          ? AppColors.textTertiary
                          : AppColors.statusOffline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Primary 4-Card (Desktop) or 2-Card (Mobile) Grid
              GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
                children: [
                  // 1. Temperature Card
                  TelemetryCard(
                    title: 'Temperature',
                    value: reading.displayTemperature,
                    status: reading.temperatureStatus,
                    statusText: !reading.isTemperatureValid
                        ? 'UNAVAILABLE'
                        : (!isOnline
                            ? 'OFFLINE'
                            : reading.temperatureStatus.label),
                    explanation: reading.temperatureExplanation,
                    icon: Icons.thermostat_rounded,
                    accentColor: AppColors.secondary,
                    updatedTimeText: reading.tempUpdatedText,
                    hasFault: reading.hasTemperatureFault,
                    faultMessage: reading.temperatureFaultReason,
                  ),

                  // 2. Humidity Card
                  TelemetryCard(
                    title: 'Humidity',
                    value: reading.displayHumidity,
                    status: reading.humidityStatus,
                    statusText: !reading.isHumidityValid
                        ? 'UNAVAILABLE'
                        : (!isOnline
                            ? 'OFFLINE'
                            : reading.humidityStatus.label),
                    explanation: reading.humidityExplanation,
                    icon: Icons.water_drop_rounded,
                    accentColor: const Color(0xFF0284C7),
                    updatedTimeText: reading.humidityUpdatedText,
                    hasFault: reading.hasHumidityFault,
                    faultMessage: reading.humidityFaultReason,
                  ),

                  // 3. Battery Card
                  TelemetryCard(
                    title: 'Battery',
                    value: reading.displayBattery,
                    status: reading.batteryStatus,
                    statusText: !reading.isBatteryValid
                        ? 'UNAVAILABLE'
                        : (!isOnline
                            ? 'OFFLINE'
                            : reading.batteryStatus.label),
                    explanation: reading.batteryExplanation,
                    icon: Icons.battery_charging_full_rounded,
                    accentColor: AppColors.statusGood,
                    updatedTimeText: reading.batteryUpdatedText,
                    hasFault: reading.hasBatteryFault,
                    faultMessage: reading.batteryFaultReason,
                  ),

                  // 4. Solar Power Card
                  TelemetryCard(
                    title: 'Solar Power',
                    value: reading.displaySolar,
                    unit: reading.isSolarValid ? 'W' : null,
                    status: reading.solarStatus,
                    statusText: !reading.isSolarValid
                        ? 'UNAVAILABLE'
                        : (!isOnline
                            ? 'OFFLINE'
                            : (reading.solarPower > 0
                                ? 'ACTIVE'
                                : 'INACTIVE')),
                    explanation: reading.solarExplanation,
                    icon: Icons.solar_power_rounded,
                    accentColor: AppColors.solarGold,
                    updatedTimeText: reading.solarUpdatedText,
                    hasFault: reading.hasSolarFault,
                    faultMessage: reading.solarFaultReason,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (isWide) ...[
                // Desktop: Balanced side-by-side PCM Reserve & Secondary Metrics
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TelemetryCard(
                        title: 'PCM Backup',
                        value: reading.displayPcmHours,
                        status: reading.pcmStatus,
                        statusText: !reading.isPcmValid
                            ? 'UNAVAILABLE'
                            : (!isOnline
                                ? 'OFFLINE'
                                : reading.pcmStatus.systemSafeLabel),
                        explanation: reading.pcmExplanation,
                        icon: Icons.ac_unit_rounded,
                        accentColor: AppColors.pcmCyan,
                        updatedTimeText: reading.pcmUpdatedText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SECONDARY PARAMETERS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactCard(
                                  title: 'GRID POWER',
                                  value: reading.displayGridPower,
                                  statusLevel: reading.gridStatus,
                                  statusText: !reading.isGridValid
                                      ? 'UNAVAIL'
                                      : (reading.gridPower
                                          ? 'NORMAL'
                                          : 'OUTAGE'),
                                  icon: reading.gridPower
                                      ? Icons.power_rounded
                                      : Icons.power_off_rounded,
                                  iconColor: reading.gridPower
                                      ? AppColors.primary
                                      : AppColors.statusWarning,
                                  bgColor: reading.gridPower
                                      ? AppColors.surface
                                      : AppColors.statusWarningBg,
                                  updatedTimeText: reading.gridUpdatedText,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactCard(
                                  title: 'DOOR',
                                  value: reading.displayDoor,
                                  statusLevel: reading.doorStatus,
                                  statusText: !reading.isDoorValid
                                      ? 'UNAVAIL'
                                      : (reading.doorOpen
                                          ? 'WARNING'
                                          : 'SECURE'),
                                  icon: reading.doorOpen
                                      ? Icons.door_front_door_outlined
                                      : Icons.meeting_room_rounded,
                                  iconColor: reading.doorOpen
                                      ? AppColors.statusCritical
                                      : AppColors.primary,
                                  bgColor: reading.doorOpen
                                      ? AppColors.statusCriticalBg
                                      : AppColors.surface,
                                  updatedTimeText: reading.doorUpdatedText,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactCard(
                                  title: 'WATER TANK',
                                  value: reading.displayWaterLevel,
                                  statusLevel: StatusLevel.good,
                                  statusText: !reading.isWaterValid
                                      ? 'UNAVAIL'
                                      : 'GOOD',
                                  icon: Icons.opacity_rounded,
                                  iconColor: const Color(0xFF0284C7),
                                  bgColor: AppColors.surface,
                                  updatedTimeText: reading.waterUpdatedText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Mobile: Stacked view
                TelemetryCard(
                  title: 'PCM Backup',
                  value: reading.displayPcmHours,
                  status: reading.pcmStatus,
                  statusText: !reading.isPcmValid
                      ? 'UNAVAILABLE'
                      : (!isOnline
                          ? 'OFFLINE'
                          : reading.pcmStatus.systemSafeLabel),
                  explanation: reading.pcmExplanation,
                  icon: Icons.ac_unit_rounded,
                  accentColor: AppColors.pcmCyan,
                  updatedTimeText: reading.pcmUpdatedText,
                ),
                const SizedBox(height: 16),
                const Text(
                  'SECONDARY PARAMETERS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactCard(
                        title: 'GRID POWER',
                        value: reading.displayGridPower,
                        statusLevel: reading.gridStatus,
                        statusText: !reading.isGridValid
                            ? 'UNAVAIL'
                            : (reading.gridPower ? 'NORMAL' : 'OUTAGE'),
                        icon: reading.gridPower
                            ? Icons.power_rounded
                            : Icons.power_off_rounded,
                        iconColor: reading.gridPower
                            ? AppColors.primary
                            : AppColors.statusWarning,
                        bgColor: reading.gridPower
                            ? AppColors.surface
                            : AppColors.statusWarningBg,
                        updatedTimeText: reading.gridUpdatedText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactCard(
                        title: 'DOOR',
                        value: reading.displayDoor,
                        statusLevel: reading.doorStatus,
                        statusText: !reading.isDoorValid
                            ? 'UNAVAIL'
                            : (reading.doorOpen ? 'WARNING' : 'SECURE'),
                        icon: reading.doorOpen
                            ? Icons.door_front_door_outlined
                            : Icons.meeting_room_rounded,
                        iconColor: reading.doorOpen
                            ? AppColors.statusCritical
                            : AppColors.primary,
                        bgColor: reading.doorOpen
                            ? AppColors.statusCriticalBg
                            : AppColors.surface,
                        updatedTimeText: reading.doorUpdatedText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactCard(
                        title: 'WATER TANK',
                        value: reading.displayWaterLevel,
                        statusLevel: StatusLevel.good,
                        statusText:
                            !reading.isWaterValid ? 'UNAVAIL' : 'GOOD',
                        icon: Icons.opacity_rounded,
                        iconColor: const Color(0xFF0284C7),
                        bgColor: AppColors.surface,
                        updatedTimeText: reading.waterUpdatedText,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactCard({
    required String title,
    required String value,
    required StatusLevel statusLevel,
    required String statusText,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    String? updatedTimeText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusLevel == StatusLevel.good
              ? AppColors.border
              : statusLevel.borderColor,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 16, color: iconColor),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: statusLevel.backgroundColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: statusLevel.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (updatedTimeText != null)
                Text(
                  updatedTimeText,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
