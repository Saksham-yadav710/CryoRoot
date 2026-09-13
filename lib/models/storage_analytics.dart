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
  });

  bool get isAllHealthy =>
      controllerStatus == StatusLevel.good &&
      compressorStatus == StatusLevel.good &&
      tempSensorStatus == StatusLevel.good &&
      humiditySensorStatus == StatusLevel.good &&
      solarInverterStatus == StatusLevel.good;
}
