import 'status_level.dart';

class HistoricalDataPoint {
  final DateTime time;
  final double value;
  final String label;

  const HistoricalDataPoint({
    required this.time,
    required this.value,
    required this.label,
  });
}

class StorageAnalytics {
  final String unitId;
  final List<HistoricalDataPoint> temperatureHistory;
  final List<HistoricalDataPoint> batteryHistory;
  final List<HistoricalDataPoint> solarHistory;
  final List<HistoricalDataPoint> pcmHistory;
  final double minTemp;
  final double maxTemp;
  final double avgTemp;
  final double minBattery;
  final double maxBattery;
  final double avgBattery;
  final double peakSolarWatts;
  final double totalSolarGeneratedKwh;
  final int doorOpenCountToday;
  final double doorOpenDurationMinutes;
  final double pcmDrainRatePerHour; // e.g. 0.8 hours/hr
  final DeviceHealthStatus deviceHealth;

  const StorageAnalytics({
    required this.unitId,
    required this.temperatureHistory,
    required this.batteryHistory,
    required this.solarHistory,
    required this.pcmHistory,
    required this.minTemp,
    required this.maxTemp,
    required this.avgTemp,
    required this.minBattery,
    required this.maxBattery,
    required this.avgBattery,
    required this.peakSolarWatts,
    required this.totalSolarGeneratedKwh,
    required this.doorOpenCountToday,
    required this.doorOpenDurationMinutes,
    required this.pcmDrainRatePerHour,
    required this.deviceHealth,
  });
}

class DeviceHealthStatus {
  final StatusLevel controllerStatus; // ESP32 / Gateway
  final String controllerFirmware;
  final StatusLevel compressorStatus;
  final int compressorHoursRun;
  final StatusLevel tempSensorStatus;
  final StatusLevel humiditySensorStatus;
  final StatusLevel solarInverterStatus;
  final int networkSignalRssi; // dBm e.g. -68
  final String connectivityType; // "4G LTE / GSM" or "WiFi Gateway"

  // Technician Hardware & Diagnostic Telemetry
  final String tempSensorModel;
  final String tempBusInterface;
  final double tempRawVoltage;
  final double tempResistanceOhms;
  final double tempCalibrationOffset;
  final String humiditySensorModel;
  final String humidityBusInterface;
  final int humidityI2cAddress;
  final String compressorModel;
  final double compressorFrequencyHz;
  final double suctionPressurePsi;
  final double dischargePressurePsi;
  final String refrigerantType;
  final List<String> requiredServiceParts;
  final String lastCalibrationDate;
  final int busErrorCount;

  const DeviceHealthStatus({
    required this.controllerStatus,
    required this.controllerFirmware,
    required this.compressorStatus,
    required this.compressorHoursRun,
    required this.tempSensorStatus,
    required this.humiditySensorStatus,
    required this.solarInverterStatus,
    required this.networkSignalRssi,
    required this.connectivityType,
    this.tempSensorModel = 'NTC 10K 3950 (Class A, IP68)',
    this.tempBusInterface = '1-Wire (GPIO 4)',
    this.tempRawVoltage = 1.654,
    this.tempResistanceOhms = 10240.0,
    this.tempCalibrationOffset = 0.04,
    this.humiditySensorModel = 'Sensirion SHT31-DIS (Dual Probe)',
    this.humidityBusInterface = 'I2C Bus (SDA 21, SCL 22)',
    this.humidityI2cAddress = 0x44,
    this.compressorModel = 'Embraco VEMZ9C BLDC Inverter',
    this.compressorFrequencyHz = 48.0,
    this.suctionPressurePsi = 28.4,
    this.dischargePressurePsi = 184.2,
    this.refrigerantType = 'R134a Eco Grade (280g)',
    this.requiredServiceParts = const [
      'Spare NTC 10K Waterproof Probe (Part #NTC-10K-SS)',
      'Sensirion SHT31 Module (Part #SHT31-MOD)',
      '10A In-line DC Fast-Blow Fuse (Part #FUSE-10A-DC)',
      'High-Conductivity Thermal Grease (5g Syringe)',
      'Silicone Gasket Seal Strip (2.5m)',
    ],
    this.lastCalibrationDate = '15 Feb 2026',
    this.busErrorCount = 0,
  });

  bool get isAllHealthy =>
      controllerStatus == StatusLevel.good &&
      compressorStatus == StatusLevel.good &&
      tempSensorStatus == StatusLevel.good &&
      humiditySensorStatus == StatusLevel.good &&
      solarInverterStatus == StatusLevel.good;
}
