import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/cold_storage_unit.dart';
import '../../../state/storage_providers.dart';

class ChamberSetpointControlCard extends ConsumerStatefulWidget {
  final ColdStorageUnit unit;
  final bool isTechnicianMode;

  const ChamberSetpointControlCard({
    super.key,
    required this.unit,
    this.isTechnicianMode = false,
  });

  @override
  ConsumerState<ChamberSetpointControlCard> createState() =>
      _ChamberSetpointControlCardState();
}

class _ChamberSetpointControlCardState
    extends ConsumerState<ChamberSetpointControlCard> {
  late double _targetTemp;
  late double _targetHumidity;
  late double _hysteresis;
  late bool _defrostActive;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initFromUnit();
  }

  @override
  void didUpdateWidget(covariant ChamberSetpointControlCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unit.id != widget.unit.id ||
        (!_hasChanges &&
            (oldWidget.unit.targetTemperature != widget.unit.targetTemperature ||
                oldWidget.unit.targetHumidity != widget.unit.targetHumidity ||
                oldWidget.unit.tempHysteresis != widget.unit.tempHysteresis ||
                oldWidget.unit.isDefrostActive != widget.unit.isDefrostActive))) {
      _initFromUnit();
    }
  }

  void _initFromUnit() {
    _targetTemp = widget.unit.targetTemperature;
    _targetHumidity = widget.unit.targetHumidity;
    _hysteresis = widget.unit.tempHysteresis;
    _defrostActive = widget.unit.isDefrostActive;
    _hasChanges = false;
  }

  void _applyCropPreset(String name, double temp, double humidity) {
    setState(() {
      _targetTemp = temp;
      _targetHumidity = humidity;
      _hasChanges = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Applied $name preset: ${temp.toStringAsFixed(0)}°C / ${humidity.toStringAsFixed(0)}% RH',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveSetpoints() async {
    setState(() {
      _isSaving = true;
    });

    await Future.delayed(const Duration(milliseconds: 350));

    ref.read(storageUnitsProvider.notifier).updateUnitSetpoints(
          widget.unit.id,
          targetTemperature: _targetTemp,
          targetHumidity: _targetHumidity,
          tempHysteresis: _hysteresis,
          isDefrostActive: _defrostActive,
        );

    if (mounted) {
      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Setpoints saved for ${widget.unit.name}: ${_targetTemp.toStringAsFixed(1)}°C, ${_targetHumidity.toStringAsFixed(0)}% RH',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.statusGood,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reading = widget.unit.reading;
    final tempDiff = (reading.temperature - _targetTemp).abs();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasChanges ? AppColors.secondary : AppColors.border,
          width: _hasChanges ? 1.5 : 1.0,
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
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CHAMBER CONTROLS & SETPOINTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        widget.isTechnicianMode
                            ? 'Technician Precision Calibration'
                            : 'Farmer Climate Control',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_hasChanges)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.statusAttentionBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.statusAttentionBorder),
                  ),
                  child: const Text(
                    'UNSAVED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.statusAttention,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Produce Presets (For Farmers)
          const Text(
            'QUICK PRODUCE PRESETS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCropPresetChip('🍅 Tomato', 10.0, 90.0),
                const SizedBox(width: 6),
                _buildCropPresetChip('🥔 Potato', 8.0, 95.0),
                const SizedBox(width: 6),
                _buildCropPresetChip('🥬 Greens', 2.0, 95.0),
                const SizedBox(width: 6),
                _buildCropPresetChip('🍎 Apple', 1.0, 90.0),
                const SizedBox(width: 6),
                _buildCropPresetChip('🌶️ Chilli', 8.0, 85.0),
                const SizedBox(width: 6),
                _buildCropPresetChip('🥕 Carrot', 1.0, 95.0),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 1. Target Temperature Control
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
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
                        Icon(Icons.thermostat_rounded,
                            size: 18, color: AppColors.secondary),
                        SizedBox(width: 6),
                        Text(
                          'Target Temperature',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_targetTemp.toStringAsFixed(1)}°C',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Chamber: ${reading.displayTemperature}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      tempDiff < 0.5
                          ? 'On target'
                          : '${tempDiff.toStringAsFixed(1)}°C from target',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: tempDiff < 0.5
                            ? AppColors.statusGood
                            : AppColors.statusAttention,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.secondary,
                    inactiveTrackColor: AppColors.secondary.withValues(alpha: 0.2),
                    thumbColor: AppColors.secondary,
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _targetTemp,
                    min: -2.0,
                    max: 15.0,
                    divisions: 34, // 0.5 step
                    onChanged: (val) {
                      setState(() {
                        _targetTemp = (val * 2).round() / 2;
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('-2°C (Deep Freeze)',
                        style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                    Text('+15°C (Tropical)',
                        style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. Target Humidity Control
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
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
                        Icon(Icons.water_drop_rounded,
                            size: 18, color: Color(0xFF0284C7)),
                        SizedBox(width: 6),
                        Text(
                          'Target Humidity (RH)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_targetHumidity.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Chamber: ${reading.displayHumidity}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      (reading.humidity - _targetHumidity).abs() < 5
                          ? 'Optimal moisture'
                          : '${(reading.humidity - _targetHumidity).abs().toStringAsFixed(0)}% gap',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (reading.humidity - _targetHumidity).abs() < 5
                            ? AppColors.statusGood
                            : AppColors.statusAttention,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF0284C7),
                    inactiveTrackColor:
                        const Color(0xFF0284C7).withValues(alpha: 0.2),
                    thumbColor: const Color(0xFF0284C7),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _targetHumidity,
                    min: 60.0,
                    max: 98.0,
                    divisions: 38, // 1% step
                    onChanged: (val) {
                      setState(() {
                        _targetHumidity = val.roundToDouble();
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('60% (Dry Produce)',
                        style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                    Text('98% (Leafy / High Moisture)',
                        style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                  ],
                ),
              ],
            ),
          ),

          // Technician Advanced Section
          if (widget.isTechnicianMode) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primaryDark.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.build_circle_outlined,
                          size: 16, color: AppColors.primaryDark),
                      SizedBox(width: 6),
                      Text(
                        'TECHNICIAN CALIBRATION OVERRIDES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Hysteresis Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Compressor Deadband (Hysteresis)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Temp swing before inverter cycles on/off',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Text(
                        '±${_hysteresis.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
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

                  const Divider(height: 16),

                  // Defrost Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Forced Coil Defrost Cycle',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Melts evaporator ice accumulation',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Switch(
                        value: _defrostActive,
                        activeThumbColor: AppColors.solarGold,
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
            ),
          ],

          const SizedBox(height: 16),

          // Save / Apply Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: (_hasChanges && !_isSaving) ? _saveSetpoints : null,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(
                _isSaving
                    ? 'Updating Hardware...'
                    : (_hasChanges
                        ? 'Apply & Send Setpoints to Chamber'
                        : 'Setpoints Synchronized'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _hasChanges ? AppColors.primary : AppColors.background,
                foregroundColor:
                    _hasChanges ? Colors.white : AppColors.textTertiary,
                elevation: _hasChanges ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _hasChanges ? AppColors.primary : AppColors.border,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropPresetChip(String label, double temp, double humidity) {
    final isSelected = (_targetTemp == temp && _targetHumidity == humidity);

    return InkWell(
      onTap: () => _applyCropPreset(label, temp, humidity),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
