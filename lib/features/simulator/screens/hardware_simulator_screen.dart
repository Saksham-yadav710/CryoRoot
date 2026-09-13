import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/sensor_reading.dart';
import '../../../state/storage_providers.dart';
import '../../../state/audio_providers.dart';
import '../../../services/rules/alert_rule_engine.dart';

class HardwareSimulatorScreen extends ConsumerStatefulWidget {
  const HardwareSimulatorScreen({super.key});

  @override
  ConsumerState<HardwareSimulatorScreen> createState() =>
      _HardwareSimulatorScreenState();
}

class _HardwareSimulatorScreenState
    extends ConsumerState<HardwareSimulatorScreen> {
  late String _selectedUnitId;

  // Local working state for fine-tuning
  double _temp = 4.2;
  double _humidity = 90.0;
  int _battery = 78;
  int _solar = 420;
  bool _gridPower = true;
  bool _doorOpen = false;
  double _pcmHours = 41.5;
  int _waterLevel = 85;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    final units = ref.read(storageUnitsProvider);
    _selectedUnitId =
        units.isNotEmpty ? units.first.id : 'AC-NER-001';
    _loadUnitValues(_selectedUnitId);
  }

  void _loadUnitValues(String unitId) {
    final units = ref.read(storageUnitsProvider);
    final unit = units.firstWhere(
      (u) => u.id == unitId,
      orElse: () => units.first,
    );
    final r = unit.reading;
    setState(() {
      _selectedUnitId = unit.id;
      _temp = r.temperature;
      _humidity = r.humidity;
      _battery = r.battery;
      _solar = r.solarPower;
      _gridPower = r.gridPower;
      _doorOpen = r.doorOpen;
      _pcmHours = r.pcmReserveHours;
      _waterLevel = r.waterLevel;
      _isOnline = r.isOnline;
    });
  }

  void _syncToProvider() {
    final newReading = SensorReading(
      deviceId: 'DEV-$_selectedUnitId',
      temperature: _temp,
      humidity: _humidity,
      battery: _battery,
      solarPower: _solar,
      gridPower: _gridPower,
      doorOpen: _doorOpen,
      pcmReserveHours: _pcmHours,
      waterLevel: _waterLevel,
      isOnline: _isOnline,
      timestamp: DateTime.now(),
    );

    ref
        .read(storageUnitsProvider.notifier)
        .updateSensorReading(_selectedUnitId, newReading);
  }

  void _applyPreset({
    required double temp,
    required double humidity,
    required int battery,
    required int solar,
    required bool gridPower,
    required bool doorOpen,
    required double pcmHours,
    required int waterLevel,
    required bool isOnline,
  }) {
    setState(() {
      _temp = temp;
      _humidity = humidity;
      _battery = battery;
      _solar = solar;
      _gridPower = gridPower;
      _doorOpen = doorOpen;
      _pcmHours = pcmHours;
      _waterLevel = waterLevel;
      _isOnline = isOnline;
    });
    _syncToProvider();
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(storageUnitsProvider);
    final enhancedAudio = ref.watch(enhancedAudioControllerProvider);
    final currentUnit = units.firstWhere(
      (u) => u.id == _selectedUnitId,
      orElse: () => units.first,
    );

    final alerts = AlertRuleEngine.evaluateUnit(currentUnit);
    final status = currentUnit.status;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.tune_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Hardware Sensor Simulator'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              ref.read(storageUnitsProvider.notifier).refreshFromMock();
              _loadUnitValues(_selectedUnitId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reset to initial hardware telemetry.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('RESET'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Target Unit Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.solar_power,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Target Unit:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedUnitId,
                        isExpanded: true,
                        items: units.map((u) {
                          return DropdownMenuItem<String>(
                            value: u.id,
                            child: Text(
                              '${u.name} (${u.village})',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _loadUnitValues(val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Live Output & Active Alerts Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: status.backgroundColor.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: status.borderColor, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(status.icon, color: status.color, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'SIMULATED STATUS: ${status.label.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: status.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          enhancedAudio.speakUnitOverview(currentUnit);
                        },
                        icon: const Icon(Icons.volume_up_rounded, size: 16),
                        label: const Text('Voice Test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          textStyle: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Active Alerts Triggered: ${alerts.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (alerts.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    ...alerts.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Icon(Icons.circle,
                                  size: 6, color: a.severity.color),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${a.title} (${a.currentValue})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: a.severity.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // One-Tap Presets
            const Text(
              'ONE-TAP HARDWARE SCENARIO PRESETS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip(
                  label: '🟢 Normal Safe',
                  color: AppColors.statusGood,
                  onTap: () => _applyPreset(
                    temp: 4.2,
                    humidity: 90.0,
                    battery: 85,
                    solar: 650,
                    gridPower: true,
                    doorOpen: false,
                    pcmHours: 42.0,
                    waterLevel: 85,
                    isOnline: true,
                  ),
                ),
                _buildPresetChip(
                  label: '🔴 Door Open + Warm',
                  color: AppColors.statusCritical,
                  onTap: () => _applyPreset(
                    temp: 11.2,
                    humidity: 74.0,
                    battery: 80,
                    solar: 700,
                    gridPower: true,
                    doorOpen: true,
                    pcmHours: 32.0,
                    waterLevel: 80,
                    isOnline: true,
                  ),
                ),
                _buildPresetChip(
                  label: '🟡 Grid Outage (PCM Active)',
                  color: AppColors.statusWarning,
                  onTap: () => _applyPreset(
                    temp: 4.8,
                    humidity: 88.0,
                    battery: 40,
                    solar: 0,
                    gridPower: false,
                    doorOpen: false,
                    pcmHours: 18.0,
                    waterLevel: 80,
                    isOnline: true,
                  ),
                ),
                _buildPresetChip(
                  label: '❄️ Chilling Danger (0.6°C)',
                  color: AppColors.secondary,
                  onTap: () => _applyPreset(
                    temp: 0.6,
                    humidity: 94.0,
                    battery: 90,
                    solar: 500,
                    gridPower: true,
                    doorOpen: false,
                    pcmHours: 45.0,
                    waterLevel: 85,
                    isOnline: true,
                  ),
                ),
                _buildPresetChip(
                  label: '⚠️ Low Battery (12%)',
                  color: AppColors.statusWarning,
                  onTap: () => _applyPreset(
                    temp: 6.5,
                    humidity: 82.0,
                    battery: 12,
                    solar: 40,
                    gridPower: false,
                    doorOpen: false,
                    pcmHours: 7.5,
                    waterLevel: 70,
                    isOnline: true,
                  ),
                ),
                _buildPresetChip(
                  label: '💧 Low Humidifier Water',
                  color: AppColors.primary,
                  onTap: () => _applyPreset(
                    temp: 5.0,
                    humidity: 62.0,
                    battery: 75,
                    solar: 500,
                    gridPower: true,
                    doorOpen: false,
                    pcmHours: 35.0,
                    waterLevel: 10,
                    isOnline: true,
                  ),
                ),
                _buildPresetChip(
                  label: '📡 Chamber Offline',
                  color: AppColors.statusOffline,
                  onTap: () => _applyPreset(
                    temp: 4.5,
                    humidity: 88.0,
                    battery: 70,
                    solar: 0,
                    gridPower: false,
                    doorOpen: false,
                    pcmHours: 30.0,
                    waterLevel: 80,
                    isOnline: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Live Telemetry Sliders
            const Text(
              'LIVE SENSOR TELEMETRY CONTROLS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // 1. Temperature Slider
                  _buildSliderRow(
                    label: 'Chamber Temperature',
                    valueDisplay: '${_temp.toStringAsFixed(1)} °C',
                    value: _temp,
                    min: -2.0,
                    max: 18.0,
                    divisions: 100,
                    activeColor: _temp > 8.0 || _temp < 2.0
                        ? AppColors.statusWarning
                        : AppColors.primary,
                    onChanged: (v) {
                      setState(() => _temp = v);
                      _syncToProvider();
                    },
                  ),
                  const Divider(height: 20),

                  // 2. Humidity Slider
                  _buildSliderRow(
                    label: 'Relative Humidity',
                    valueDisplay: '${_humidity.toInt()} %',
                    value: _humidity,
                    min: 40.0,
                    max: 100.0,
                    divisions: 60,
                    activeColor: AppColors.primary,
                    onChanged: (v) {
                      setState(() => _humidity = v);
                      _syncToProvider();
                    },
                  ),
                  const Divider(height: 20),

                  // 3. Battery SOC Slider
                  _buildSliderRow(
                    label: 'Battery SOC',
                    valueDisplay: '$_battery %',
                    value: _battery.toDouble(),
                    min: 0.0,
                    max: 100.0,
                    divisions: 100,
                    activeColor: _battery < 20
                        ? AppColors.statusCritical
                        : AppColors.statusGood,
                    onChanged: (v) {
                      setState(() => _battery = v.toInt());
                      _syncToProvider();
                    },
                  ),
                  const Divider(height: 20),

                  // 4. Solar Generation Slider
                  _buildSliderRow(
                    label: 'Solar Generation',
                    valueDisplay: '$_solar W',
                    value: _solar.toDouble(),
                    min: 0.0,
                    max: 1200.0,
                    divisions: 24,
                    activeColor: AppColors.solarGold,
                    onChanged: (v) {
                      setState(() => _solar = v.toInt());
                      _syncToProvider();
                    },
                  ),
                  const Divider(height: 20),

                  // 5. PCM Reserve Hours Slider
                  _buildSliderRow(
                    label: 'PCM Reserve Hours',
                    valueDisplay: '${_pcmHours.toStringAsFixed(1)} h',
                    value: _pcmHours,
                    min: 0.0,
                    max: 48.0,
                    divisions: 48,
                    activeColor: AppColors.pcmCyan,
                    onChanged: (v) {
                      setState(() => _pcmHours = v);
                      _syncToProvider();
                    },
                  ),
                  const Divider(height: 20),

                  // 6. Water Level Slider
                  _buildSliderRow(
                    label: 'Humidifier Water Reservoir',
                    valueDisplay: '$_waterLevel %',
                    value: _waterLevel.toDouble(),
                    min: 0.0,
                    max: 100.0,
                    divisions: 20,
                    activeColor: _waterLevel < 20
                        ? AppColors.statusWarning
                        : AppColors.primary,
                    onChanged: (v) {
                      setState(() => _waterLevel = v.toInt());
                      _syncToProvider();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Binary Toggles Card (Grid Power, Door, Connectivity)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Grid AC Mains Power',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      _gridPower
                          ? 'Grid connected (Normal)'
                          : 'Grid failure (Outage)',
                      style: TextStyle(
                        fontSize: 11,
                        color: _gridPower
                            ? AppColors.statusGood
                            : AppColors.statusWarning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: _gridPower,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) {
                      setState(() => _gridPower = v);
                      _syncToProvider();
                    },
                  ),
                  const Divider(height: 10),
                  SwitchListTile(
                    title: const Text('Chamber Door Sensor',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      _doorOpen ? 'Door is OPEN' : 'Door is CLOSED',
                      style: TextStyle(
                        fontSize: 11,
                        color: _doorOpen
                            ? AppColors.statusCritical
                            : AppColors.statusGood,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: _doorOpen,
                    activeThumbColor: AppColors.statusCritical,
                    onChanged: (v) {
                      setState(() => _doorOpen = v);
                      _syncToProvider();
                    },
                  ),
                  const Divider(height: 10),
                  SwitchListTile(
                    title: const Text('IoT Gateway Connectivity',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      _isOnline
                          ? 'ESP32 GSM Connected'
                          : 'Connection Lost / Offline',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isOnline
                            ? AppColors.statusGood
                            : AppColors.statusOffline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: _isOnline,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) {
                      setState(() => _isOnline = v);
                      _syncToProvider();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueDisplay,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              valueDisplay,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: activeColor,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: activeColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
