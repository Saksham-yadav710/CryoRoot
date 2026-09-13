import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/app_user.dart';
import '../../../models/cold_storage_unit.dart';
import '../../../models/storage_analytics.dart';
import '../../../state/storage_providers.dart';
import '../../../state/technician_auth_provider.dart';

class TechnicianHardwareCard extends ConsumerStatefulWidget {
  final ColdStorageUnit unit;
  final DeviceHealthStatus health;
  final VoidCallback? onLockPanel;

  const TechnicianHardwareCard({
    super.key,
    required this.unit,
    required this.health,
    this.onLockPanel,
  });

  @override
  ConsumerState<TechnicianHardwareCard> createState() =>
      _TechnicianHardwareCardState();
}

class _TechnicianHardwareCardState
    extends ConsumerState<TechnicianHardwareCard> {
  late double _targetTemp;
  late double _targetHumidity;
  late double _hysteresis;
  late bool _defrostActive;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _targetTemp = widget.unit.targetTemperature;
    _targetHumidity = widget.unit.targetHumidity;
    _hysteresis = widget.unit.tempHysteresis;
    _defrostActive = widget.unit.isDefrostActive;
  }

  @override
  void didUpdateWidget(covariant TechnicianHardwareCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasChanges &&
        (oldWidget.unit.targetTemperature != widget.unit.targetTemperature ||
            oldWidget.unit.targetHumidity != widget.unit.targetHumidity)) {
      _targetTemp = widget.unit.targetTemperature;
      _targetHumidity = widget.unit.targetHumidity;
      _hysteresis = widget.unit.tempHysteresis;
      _defrostActive = widget.unit.isDefrostActive;
    }
  }

  Future<void> _applyRegulationSetpoints() async {
    setState(() {
      _isSaving = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    final success = ref.read(storageUnitsProvider.notifier).updateUnitSetpoints(
          widget.unit.id,
          caller: AppUser.technician,
          isTechnicianPanelAuth: true,
          targetTemperature: _targetTemp,
          targetHumidity: _targetHumidity,
          tempHysteresis: _hysteresis,
          isDefrostActive: _defrostActive,
        );

    if (mounted) {
      setState(() {
        _isSaving = false;
        if (success) {
          _hasChanges = false;
        }
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hardware Regulation Applied: ${_targetTemp.toStringAsFixed(1)}°C, ${_targetHumidity.toStringAsFixed(0)}% RH synchronized to chamber.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.statusGood,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Security Notice: Could not apply technician setpoints to hardware.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.statusCritical,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reading = widget.unit.reading;
    final health = widget.health;
    final authState = ref.watch(technicianAuthProvider);
    final tempDiff = reading.temperature - _targetTemp;
    final humidityDiff = reading.humidity - _targetHumidity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasChanges
              ? AppColors.primary
              : AppColors.primaryDark.withValues(alpha: 0.3),
          width: _hasChanges ? 1.5 : 1.0,
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
          // Header Row with Verified Status & Lock Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.engineering_rounded,
                      size: 18,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HARDWARE & FIELD SERVICING SPEC',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        authState.isAuthenticated
                            ? 'Verified: ${authState.user?.name ?? "Bikash Sharma"}'
                            : 'Technician Diagnostics Mode',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.statusGoodBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.statusGoodBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded,
                            size: 11, color: AppColors.statusGood),
                        SizedBox(width: 4),
                        Text(
                          'UNLOCKED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.statusGood,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onLockPanel != null) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Lock Technician Panel',
                      icon: const Icon(Icons.lock_rounded, size: 16),
                      color: AppColors.textSecondary,
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onLockPanel,
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // -----------------------------------------------------------------
          // TECHNICIAN CLIMATE REGULATION CONSOLE (Temp & Humidity Controls)
          // -----------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasChanges
                    ? AppColors.primary
                    : AppColors.primaryDark.withValues(alpha: 0.2),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune_rounded,
                            size: 16, color: AppColors.primaryDark),
                        SizedBox(width: 6),
                        Text(
                          'TECHNICIAN CLIMATE REGULATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    if (_hasChanges)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.statusAttentionBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppColors.statusAttentionBorder),
                        ),
                        child: const Text(
                          'PENDING SYNC',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.statusAttention,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // 1. Target Temperature Regulation Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.thermostat_rounded,
                            size: 15, color: AppColors.secondary),
                        SizedBox(width: 4),
                        Text(
                          'Target Temperature',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '${_targetTemp.toStringAsFixed(1)}°C',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(Live: ${reading.temperature.toStringAsFixed(1)}°C, ΔT ${tempDiff >= 0 ? "+" : ""}${tempDiff.toStringAsFixed(1)}°C)',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.secondary,
                    inactiveTrackColor: AppColors.border,
                    thumbColor: AppColors.secondary,
                    overlayColor: AppColors.secondary.withValues(alpha: 0.15),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _targetTemp,
                    min: -5.0,
                    max: 15.0,
                    divisions: 40,
                    onChanged: (val) {
                      setState(() {
                        _targetTemp = (val * 2).round() / 2;
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
                // Quick Temperature Presets
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickChip('0.0°C Freeze', 0.0, true),
                      const SizedBox(width: 6),
                      _buildQuickChip('2.5°C Chill', 2.5, true),
                      const SizedBox(width: 6),
                      _buildQuickChip('4.0°C Standard', 4.0, true),
                      const SizedBox(width: 6),
                      _buildQuickChip('8.0°C Root', 8.0, true),
                      const SizedBox(width: 6),
                      _buildQuickChip('12.0°C Warm', 12.0, true),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // 2. Target Humidity Regulation Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.water_drop_rounded,
                            size: 15, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Target Humidity',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '${_targetHumidity.toStringAsFixed(0)}% RH',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(Live: ${reading.humidity.toStringAsFixed(0)}%, ΔRH ${humidityDiff >= 0 ? "+" : ""}${humidityDiff.toStringAsFixed(0)}%)',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.border,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withValues(alpha: 0.15),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _targetHumidity,
                    min: 50.0,
                    max: 98.0,
                    divisions: 48,
                    onChanged: (val) {
                      setState(() {
                        _targetHumidity = val.roundToDouble();
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
                // Quick Humidity Presets
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickChip('95% High RH', 95.0, false),
                      const SizedBox(width: 6),
                      _buildQuickChip('90% Standard', 90.0, false),
                      const SizedBox(width: 6),
                      _buildQuickChip('80% Moderate', 80.0, false),
                      const SizedBox(width: 6),
                      _buildQuickChip('65% Low Dry', 65.0, false),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // 3. Refrigeration Parameters: Hysteresis & Defrost
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Compressor Deadband',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '±${_hysteresis.toStringAsFixed(1)}°C',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _hysteresis,
                            min: 0.2,
                            max: 2.0,
                            divisions: 18,
                            activeColor: AppColors.primaryDark,
                            onChanged: (val) {
                              setState(() {
                                _hysteresis = (val * 10).round() / 10;
                                _hasChanges = true;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      children: [
                        const Text(
                          'Forced Defrost',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Switch(
                          value: _defrostActive,
                          activeThumbColor: AppColors.statusWarning,
                          onChanged: (val) {
                            setState(() {
                              _defrostActive = val;
                              _hasChanges = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 4. Apply Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _applyRegulationSetpoints,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(
                      _isSaving
                          ? 'Synchronizing Hardware...'
                          : (_hasChanges
                              ? 'Apply Hardware Regulation Setpoints'
                              : 'Regulation Setpoints Synchronized'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasChanges
                          ? AppColors.primaryDark
                          : AppColors.surface,
                      foregroundColor: _hasChanges
                          ? Colors.white
                          : AppColors.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: _hasChanges ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: _hasChanges
                              ? AppColors.primaryDark
                              : AppColors.border,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 1: Microcontroller & Telemetry Link
          _buildSubheader(Icons.memory_rounded, 'SYSTEM CONTROLLER & BUS LOGIC'),
          const SizedBox(height: 8),
          _buildSpecGrid([
            _SpecItem('Controller SoC', 'Espressif ESP32-WROVER-E (Dual-Core 240MHz)'),
            _SpecItem('Firmware Version', health.controllerFirmware),
            _SpecItem('Modem / Uplink', '${health.connectivityType} (Quectel EC200U-CN)'),
            _SpecItem('Cellular RSSI', '${health.networkSignalRssi} dBm (CSQ: 24/31 Excellent)'),
            _SpecItem('Bus Error Frames', '${health.busErrorCount} CRC faults / 24h'),
            _SpecItem('Last Factory Cal', health.lastCalibrationDate),
          ]),

          const SizedBox(height: 16),

          // Section 2: Temperature Sensor Probe
          _buildSubheader(Icons.thermostat_rounded, 'TEMPERATURE SENSING SUBSYSTEM'),
          const SizedBox(height: 8),
          _buildSpecGrid([
            _SpecItem('Component Model', health.tempSensorModel),
            _SpecItem('Interface Protocol', health.tempBusInterface),
            _SpecItem('Raw ADC Voltage', '${health.tempRawVoltage.toStringAsFixed(3)} V'),
            _SpecItem('Probe Resistance', '${health.tempResistanceOhms.toStringAsFixed(0)} Ω'),
            _SpecItem('Calibrated Offset', '${health.tempCalibrationOffset >= 0 ? "+" : ""}${health.tempCalibrationOffset.toStringAsFixed(2)}°C'),
            _SpecItem(
              'Probe Loop Health',
              reading.hasTemperatureFault
                  ? 'FAULT: ${reading.temperatureFaultReason ?? "Disconnected"}'
                  : 'NORMAL (Low Noise)',
              highlight: reading.hasTemperatureFault,
              highlightColor: AppColors.statusCritical,
            ),
          ]),

          const SizedBox(height: 16),

          // Section 3: Humidity Sensor Probe
          _buildSubheader(Icons.water_drop_rounded, 'HUMIDITY SENSING SUBSYSTEM'),
          const SizedBox(height: 8),
          _buildSpecGrid([
            _SpecItem('Component Model', health.humiditySensorModel),
            _SpecItem('Bus Architecture', '${health.humidityBusInterface} (Addr: 0x${health.humidityI2cAddress.toRadixString(16).toUpperCase()})'),
            _SpecItem('Capacitive Accuracy', '±1.5% RH (0 to 100% Condensing)'),
            _SpecItem('Filter Membrane', 'PTFE IP67 Dust & Aerosol Shield'),
            _SpecItem(
              'I2C Comms Status',
              reading.hasHumidityFault
                  ? 'FAULT: ${reading.humidityFaultReason ?? "NACK Error"}'
                  : 'ACK OK (No Bus Contention)',
              highlight: reading.hasHumidityFault,
              highlightColor: AppColors.statusCritical,
            ),
          ]),

          const SizedBox(height: 16),

          // Section 4: Compressor & Refrigeration Loop
          _buildSubheader(Icons.compress_rounded, 'COMPRESSOR & COOLING LOOP DYNAMICS'),
          const SizedBox(height: 8),
          _buildSpecGrid([
            _SpecItem('Compressor Unit', health.compressorModel),
            _SpecItem('Inverter Drive Freq', '${health.compressorFrequencyHz.toStringAsFixed(1)} Hz (PID Modulation)'),
            _SpecItem('Refrigerant Charge', health.refrigerantType),
            _SpecItem('Suction Pressure', '${health.suctionPressurePsi.toStringAsFixed(1)} PSI (Evap: -4.2°C)'),
            _SpecItem('Discharge Pressure', '${health.dischargePressurePsi.toStringAsFixed(1)} PSI (Cond: +38.5°C)'),
            _SpecItem('Operating Run Time', '${health.compressorHoursRun} cumulative hours'),
          ]),

          const SizedBox(height: 16),

          // Section 5: Field Servicing Requirements & Parts Checklist
          _buildSubheader(Icons.checklist_rounded, 'FIELD SERVICING PARTS & HARDWARE REQUIREMENTS'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommended Field Spares & Maintenance Items:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                for (final part in health.requiredServiceParts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_box_outlined,
                            size: 15, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            part,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'STANDARD PART',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Toolbar for Technician
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Bus test initiated. Scanning I2C addresses 0x44, 0x48... OK.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Run Bus Test',
                      style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primaryDark,
                    side: const BorderSide(color: AppColors.primaryDark),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Diagnostic report exported to /sdcard/cryoroot_report.json'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Export Report',
                      style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, double value, bool isTemp) {
    final isSelected = isTemp ? (_targetTemp == value) : (_targetHumidity == value);

    return InkWell(
      onTap: () {
        setState(() {
          if (isTemp) {
            _targetTemp = value;
          } else {
            _targetHumidity = value;
          }
          _hasChanges = true;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isTemp ? AppColors.secondary : AppColors.primary)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? (isTemp ? AppColors.secondary : AppColors.primary)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSubheader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primaryDark),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecGrid(List<_SpecItem> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    items[i].label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: Text(
                    items[i].value,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: items[i].highlight
                          ? (items[i].highlightColor ?? AppColors.primaryDark)
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SpecItem {
  final String label;
  final String value;
  final bool highlight;
  final Color? highlightColor;

  _SpecItem(this.label, this.value,
      {this.highlight = false, this.highlightColor});
}
