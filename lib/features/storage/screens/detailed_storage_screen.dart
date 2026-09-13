import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/cold_storage_unit.dart';
import '../../../state/storage_providers.dart';
import '../../../state/audio_providers.dart';
import '../widgets/metric_stat_card.dart';
import '../widgets/time_series_chart.dart';
import '../widgets/power_flow_diagram.dart';
import '../widgets/chamber_setpoint_control_card.dart';
import '../widgets/farmer_sensor_health_card.dart';
import '../widgets/technician_hardware_card.dart';

class DetailedStorageScreen extends ConsumerStatefulWidget {
  final String unitId;

  const DetailedStorageScreen({super.key, required this.unitId});

  @override
  ConsumerState<DetailedStorageScreen> createState() =>
      _DetailedStorageScreenState();
}

class _DetailedStorageScreenState extends ConsumerState<DetailedStorageScreen> {
  int _selectedChartTabIndex = 0; // 0: Temp, 1: Battery/Solar, 2: PCM
  bool _isTechnicianMode = false;

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(storageUnitsProvider);
    final isAudioPlaying = ref.watch(isAudioPlayingProvider);
    final enhancedAudio = ref.watch(enhancedAudioControllerProvider);

    final ColdStorageUnit unit = units.firstWhere(
      (u) => u.id == widget.unitId,
      orElse: () => units.first,
    );

    final analytics = ref.watch(unitAnalyticsProvider(unit.id));
    final reading = unit.reading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${unit.name} Analytics',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${unit.village} • Device ID: ${reading.deviceId}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          // Live Connectivity Badge
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: reading.isOnline
                  ? AppColors.statusGoodBg
                  : AppColors.statusOfflineBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: reading.isOnline
                    ? AppColors.statusGoodBorder
                    : AppColors.statusOfflineBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: reading.isOnline
                        ? AppColors.statusGood
                        : AppColors.statusOffline,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  reading.isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: reading.isOnline
                        ? AppColors.statusGood
                        : AppColors.statusOffline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Voice Diagnostic Briefing Action Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.record_voice_over_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Technical Audio Briefing',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Listen to spoken summary of 24h metrics & chamber health',
                          style: TextStyle(fontSize: 10, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (isAudioPlaying) {
                        enhancedAudio.stop();
                      } else {
                        enhancedAudio.speakDetailedAnalytics(unit, analytics);
                      }
                    },
                    icon: Icon(
                      isAudioPlaying
                          ? Icons.stop_rounded
                          : Icons.volume_up_rounded,
                      size: 16,
                    ),
                    label: Text(isAudioPlaying ? 'Stop' : 'Listen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. Chamber Climate & Setpoint Control (Farmer Presets & Technician Overrides)
            ChamberSetpointControlCard(
              unit: unit,
              isTechnicianMode: _isTechnicianMode,
            ),

            const SizedBox(height: 16),

            // 3. Power Flow & Outage / PCM Reserve Card
            PowerFlowDiagram(reading: reading),

            const SizedBox(height: 16),

            // 3. 24-Hour Analytics & Trend Visualizer Section
            const Text(
              '24-HOUR ANALYTICS & TRENDS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Chart Metric Tab Switcher
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Temperature'),
                  icon: Icon(Icons.thermostat_rounded, size: 16),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Solar & Battery'),
                  icon: Icon(Icons.solar_power_rounded, size: 16),
                ),
                ButtonSegment(
                  value: 2,
                  label: Text('PCM Backup'),
                  icon: Icon(Icons.ac_unit_rounded, size: 16),
                ),
              ],
              selected: {_selectedChartTabIndex},
              onSelectionChanged: (set) {
                setState(() {
                  _selectedChartTabIndex = set.first;
                });
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Metric Summary Row (Min / Max / Avg / Current)
            if (_selectedChartTabIndex == 0) ...[
              Row(
                children: [
                  Expanded(
                    child: MetricStatCard(
                      label: 'Min Temp',
                      value: '${analytics.minTemp.toStringAsFixed(1)}°C',
                      icon: Icons.arrow_downward_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricStatCard(
                      label: 'Avg Temp',
                      value: '${analytics.avgTemp.toStringAsFixed(1)}°C',
                      icon: Icons.horizontal_rule_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricStatCard(
                      label: 'Max Temp',
                      value: '${analytics.maxTemp.toStringAsFixed(1)}°C',
                      icon: Icons.arrow_upward_rounded,
                      color: analytics.maxTemp > 8.0
                          ? AppColors.statusWarning
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TimeSeriesChart(
                dataPoints: analytics.temperatureHistory,
                title: 'Internal Chamber Temperature (24h Trend)',
                unit: '°C',
                lineColor: AppColors.secondary,
                safeMinThreshold: 2.0,
                safeMaxThreshold: 8.0,
                safeZoneLabel: 'Optimal 2°C - 8°C Zone',
              ),
            ] else if (_selectedChartTabIndex == 1) ...[
              Row(
                children: [
                  Expanded(
                    child: MetricStatCard(
                      label: 'Peak Solar',
                      value: '${analytics.peakSolarWatts.toInt()}',
                      unit: 'W',
                      icon: Icons.solar_power_rounded,
                      color: AppColors.solarGold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricStatCard(
                      label: 'Total Gen',
                      value: '${analytics.totalSolarGeneratedKwh}',
                      unit: 'kWh',
                      icon: Icons.bolt_rounded,
                      color: AppColors.solarGold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricStatCard(
                      label: 'Min Battery',
                      value: '${analytics.minBattery.toInt()}%',
                      icon: Icons.battery_alert_rounded,
                      color: AppColors.statusGood,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TimeSeriesChart(
                dataPoints: analytics.solarHistory,
                title: 'Solar Generation Profile (Watts)',
                unit: 'W',
                lineColor: AppColors.solarGold,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: MetricStatCard(
                      label: 'Current PCM',
                      value: reading.formattedPcmHours,
                      icon: Icons.ac_unit_rounded,
                      color: AppColors.pcmCyan,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricStatCard(
                      label: 'Drain Rate',
                      value: '${analytics.pcmDrainRatePerHour}h/h',
                      subtitle: 'Thermal loss',
                      icon: Icons.trending_down_rounded,
                      color: AppColors.pcmCyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TimeSeriesChart(
                dataPoints: analytics.pcmHistory,
                title: 'Phase Change Thermal Battery Reserve (Hours)',
                unit: 'h',
                lineColor: AppColors.pcmCyan,
                safeMinThreshold: 12.0,
                safeMaxThreshold: 48.0,
                safeZoneLabel: 'Safe Cold Backup',
              ),
            ],

            const SizedBox(height: 16),

            // 4. Chamber Activity & Door Monitoring
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHAMBER ACCESS & DOOR MONITORING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Door Openings Today',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${analytics.doorOpenCountToday} times',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Open Time',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${analytics.doorOpenDurationMinutes.toStringAsFixed(1)} mins',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: analytics.doorOpenDurationMinutes > 20.0
                                    ? AppColors.statusWarning
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 5. Sensor Health & Hardware Diagnostics (Farmer vs Technician mode)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SENSOR HEALTH & HARDWARE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Farmer View'),
                      icon: Icon(Icons.person_outline_rounded, size: 14),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Tech Mode'),
                      icon: Icon(Icons.engineering_rounded, size: 14),
                    ),
                  ],
                  selected: {_isTechnicianMode},
                  onSelectionChanged: (set) {
                    setState(() {
                      _isTechnicianMode = set.first;
                    });
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStateProperty.all(
                      const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (!_isTechnicianMode)
              FarmerSensorHealthCard(unit: unit)
            else
              TechnicianHardwareCard(
                unit: unit,
                health: analytics.deviceHealth,
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
