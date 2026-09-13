import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/sensor_reading.dart';

class PowerFlowDiagram extends StatelessWidget {
  final SensorReading reading;

  const PowerFlowDiagram({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final bool isOutage = !reading.gridPower;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOutage ? AppColors.statusWarningBg : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOutage ? AppColors.statusWarningBorder : AppColors.border,
          width: isOutage ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Outage Alert
          Row(
            children: [
              Icon(
                isOutage
                    ? Icons.power_off_rounded
                    : Icons.electric_bolt_rounded,
                color: isOutage ? AppColors.statusWarning : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isOutage
                    ? 'POWER OUTAGE — BACKUP ACTIVE'
                    : 'POWER & ENERGY DISTRIBUTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isOutage
                      ? AppColors.statusWarning
                      : AppColors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),

          if (isOutage) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.statusWarningBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded,
                      color: AppColors.statusGood, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRODUCE SAFE — PCM Thermal Reserve Active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.statusGood,
                          ),
                        ),
                        Text(
                          'Estimated ${reading.formattedPcmHours} backup remaining at current thermal load.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // 3-Stage Power Flow Nodes
          Row(
            children: [
              // 1. Generation Node: Solar + Grid
              Expanded(
                child: _buildFlowBlock(
                  title: 'INPUTS',
                  items: [
                    _buildSubItem(
                      icon: Icons.solar_power_rounded,
                      label: '${reading.solarPower} W',
                      color: AppColors.solarGold,
                      status: reading.solarPower > 0 ? 'Solar' : 'No Sun',
                    ),
                    const SizedBox(height: 4),
                    _buildSubItem(
                      icon: reading.gridPower
                          ? Icons.power_rounded
                          : Icons.power_off_rounded,
                      label: reading.gridPower ? 'ON (230V)' : 'OFF (0V)',
                      color: reading.gridPower
                          ? AppColors.primary
                          : AppColors.statusWarning,
                      status: 'Grid',
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 16, color: AppColors.textTertiary),
              ),

              // 2. Storage & Conversion Node: Battery + PCM
              Expanded(
                child: _buildFlowBlock(
                  title: 'STORAGE',
                  items: [
                    _buildSubItem(
                      icon: Icons.battery_charging_full_rounded,
                      label: '${reading.battery}%',
                      color: AppColors.statusGood,
                      status: 'LiFePO4',
                    ),
                    const SizedBox(height: 4),
                    _buildSubItem(
                      icon: Icons.ac_unit_rounded,
                      label: reading.formattedPcmHours,
                      color: AppColors.pcmCyan,
                      status: 'PCM Tank',
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 16, color: AppColors.textTertiary),
              ),

              // 3. Output Node: Cold Chamber
              Expanded(
                child: _buildFlowBlock(
                  title: 'CHAMBER',
                  items: [
                    _buildSubItem(
                      icon: Icons.thermostat_rounded,
                      label: '${reading.temperature.toStringAsFixed(1)}°C',
                      color: reading.temperatureStatus.color,
                      status: 'Cooling',
                    ),
                    const SizedBox(height: 4),
                    _buildSubItem(
                      icon: Icons.door_front_door_outlined,
                      label: reading.doorOpen ? 'OPEN' : 'CLOSED',
                      color: reading.doorOpen
                          ? AppColors.statusWarning
                          : AppColors.primary,
                      status: 'Door',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowBlock({
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSubItem({
    required IconData icon,
    required String label,
    required Color color,
    required String status,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
