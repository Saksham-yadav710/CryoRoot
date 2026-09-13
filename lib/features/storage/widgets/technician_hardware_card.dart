import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/cold_storage_unit.dart';
import '../../../models/storage_analytics.dart';

class TechnicianHardwareCard extends StatelessWidget {
  final ColdStorageUnit unit;
  final DeviceHealthStatus health;

  const TechnicianHardwareCard({
    super.key,
    required this.unit,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
    final reading = unit.reading;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryDark.withValues(alpha: 0.3)),
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
          // Header Row
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HARDWARE & FIELD SERVICING SPEC',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Technician Diagnostics Mode',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'TECH ACCESS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

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
            _SpecItem('Bus Architecture', '${health.humidityBusInterface} (Addr: ${health.humidityI2cAddress})'),
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

          // Technician Actions Bar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Executing I2C/1-Wire probe loop diagnostic test... All buses ACKed in 12ms.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Run Bus Test'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    side: const BorderSide(color: AppColors.primaryDark),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Exported hardware diagnostic profile for ${unit.id} to technician clipboard.',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.primaryDark,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Export Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubheader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primaryDark),
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
