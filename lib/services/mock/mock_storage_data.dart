import '../../models/cold_storage_unit.dart';
import '../../models/sensor_reading.dart';
import '../../models/alert_item.dart';
import '../../models/status_level.dart';
import '../../models/storage_analytics.dart';

class MockStorageData {
  static List<ColdStorageUnit> getUnits() {
    final now = DateTime.now();

    return [
      // Unit 1: Normal Safe Operating Condition
      ColdStorageUnit(
        id: 'AC-NER-001',
        name: 'Cold Storage 1',
        village: 'Village A',
        district: 'Sonitpur, Assam',
        capacityKg: 5000,
        currentOccupancyKg: 3450,
        primaryProduce: 'Tomato (2000kg), Green Chilli (1450kg)',
        recommendedAction: 'No action needed. Storage conditions are optimal.',
        hasActionRequired: false,
        reading: SensorReading(
          deviceId: 'AC-DEV-001',
          temperature: 4.2,
          humidity: 90.0,
          battery: 78,
          solarPower: 420,
          gridPower: true,
          doorOpen: false,
          pcmReserveHours: 41.5,
          waterLevel: 85,
          isOnline: true,
          timestamp: now.subtract(const Duration(minutes: 2)),
        ),
      ),

      // Unit 2: Power Outage / Running on PCM Backup
      ColdStorageUnit(
        id: 'AC-NER-002',
        name: 'Cold Storage 2',
        village: 'Village B',
        district: 'Kamrup, Assam',
        capacityKg: 3000,
        currentOccupancyKg: 2100,
        primaryProduce: 'Cabbage (1100kg), Ginger (1000kg)',
        recommendedAction:
            'Grid outage active. System is running securely on Solar & PCM backup.',
        hasActionRequired: false,
        reading: SensorReading(
          deviceId: 'AC-DEV-002',
          temperature: 5.4,
          humidity: 88.0,
          battery: 52,
          solarPower: 310,
          gridPower: false, // Power Outage
          doorOpen: false,
          pcmReserveHours: 28.2,
          waterLevel: 78,
          isOnline: true,
          timestamp: now.subtract(const Duration(minutes: 1)),
        ),
      ),

      // Unit 3: Door Open / Elevated Temperature Alert
      ColdStorageUnit(
        id: 'AC-NER-003',
        name: 'Cold Storage 3',
        village: 'Village C',
        district: 'Nagaon, Assam',
        capacityKg: 4000,
        currentOccupancyKg: 1800,
        primaryProduce: 'Orange (1200kg), Leafy Veg (600kg)',
        recommendedAction: 'Check and close the storage door immediately.',
        hasActionRequired: true,
        reading: SensorReading(
          deviceId: 'AC-DEV-003',
          temperature: 10.5, // High
          humidity: 78.0,
          battery: 68,
          solarPower: 440,
          gridPower: true,
          doorOpen: true, // Door is open!
          pcmReserveHours: 16.5,
          waterLevel: 62,
          isOnline: true,
          timestamp: now.subtract(const Duration(seconds: 45)),
        ),
      ),
    ];
  }

  static List<AlertItem> getInitialAlerts() {
    final now = DateTime.now();

    return [
      AlertItem(
        id: 'ALT-101',
        unitId: 'AC-NER-003',
        unitName: 'Cold Storage 3',
        title: 'Temperature Too High & Door Open',
        severity: StatusLevel.critical,
        currentValue: '10.5°C',
        expectedValue: '2.0°C - 8.0°C',
        duration: '12 minutes',
        possibleCause: 'Storage chamber door has been left open.',
        recommendedAction:
            'Check and close the storage door to prevent produce spoilage.',
        timestamp: now.subtract(const Duration(minutes: 12)),
      ),
      AlertItem(
        id: 'ALT-102',
        unitId: 'AC-NER-002',
        unitName: 'Cold Storage 2',
        title: 'Grid Power Outage',
        severity: StatusLevel.attention,
        currentValue: 'Grid: OFF',
        expectedValue: 'Grid: ON',
        duration: '1 hr 15 mins',
        possibleCause: 'Local electrical grid disruption in Village B.',
        recommendedAction:
            'PCM Cold backup is maintaining safe internal temperature (28h remaining).',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 15)),
      ),
    ];
  }

  static StorageAnalytics getAnalyticsForUnit(String unitId) {
    final now = DateTime.now();

    // 24-hour time points at 2-hour intervals
    final List<String> hoursLabels = [
      '00:00',
      '02:00',
      '04:00',
      '06:00',
      '08:00',
      '10:00',
      '12:00',
      '14:00',
      '16:00',
      '18:00',
      '20:00',
      '22:00',
      'Now'
    ];

    List<double> tempValues;
    List<double> batteryValues;
    List<double> solarValues;
    List<double> pcmValues;

    if (unitId == 'AC-NER-003') {
      // Unit 3: Temperature spike due to open door
      tempValues = [
        4.1,
        4.2,
        4.0,
        3.9,
        4.3,
        5.2,
        6.8,
        8.4,
        9.6,
        10.2,
        10.5,
        10.4,
        10.5
      ];
      batteryValues = [85, 82, 80, 78, 76, 80, 88, 92, 86, 78, 72, 70, 68];
      solarValues = [0, 0, 0, 40, 220, 380, 480, 520, 410, 150, 10, 0, 440];
      pcmValues = [
        24.0,
        23.5,
        23.0,
        22.5,
        22.0,
        21.0,
        20.0,
        19.0,
        18.2,
        17.5,
        17.0,
        16.8,
        16.5
      ];
    } else if (unitId == 'AC-NER-002') {
      // Unit 2: Outage in recent hours, PCM draining slowly
      tempValues = [
        3.8,
        3.9,
        4.0,
        4.2,
        4.3,
        4.6,
        4.9,
        5.1,
        5.2,
        5.3,
        5.4,
        5.4,
        5.4
      ];
      batteryValues = [90, 88, 85, 82, 80, 75, 70, 65, 60, 58, 55, 53, 52];
      solarValues = [0, 0, 0, 30, 180, 310, 420, 440, 360, 110, 0, 0, 310];
      pcmValues = [
        34.0,
        33.5,
        33.0,
        32.5,
        32.0,
        31.2,
        30.5,
        29.8,
        29.2,
        28.8,
        28.5,
        28.3,
        28.2
      ];
    } else {
      // Unit 1: Rock-solid stability (2°C - 8°C optimal range)
      tempValues = [
        4.3,
        4.2,
        4.1,
        4.0,
        4.1,
        4.3,
        4.5,
        4.6,
        4.4,
        4.3,
        4.2,
        4.2,
        4.2
      ];
      batteryValues = [88, 85, 82, 80, 79, 84, 91, 95, 92, 85, 82, 80, 78];
      solarValues = [0, 0, 0, 50, 260, 410, 490, 530, 450, 180, 15, 0, 420];
      pcmValues = [
        44.0,
        43.8,
        43.5,
        43.2,
        43.0,
        42.8,
        42.5,
        42.2,
        42.0,
        41.8,
        41.6,
        41.5,
        41.5
      ];
    }

    final tempHistory = <HistoricalDataPoint>[];
    final batteryHistory = <HistoricalDataPoint>[];
    final solarHistory = <HistoricalDataPoint>[];
    final pcmHistory = <HistoricalDataPoint>[];

    for (int i = 0; i < hoursLabels.length; i++) {
      final pointTime =
          now.subtract(Duration(hours: (hoursLabels.length - 1 - i) * 2));
      tempHistory.add(HistoricalDataPoint(
        time: pointTime,
        value: tempValues[i],
        label: hoursLabels[i],
      ));
      batteryHistory.add(HistoricalDataPoint(
        time: pointTime,
        value: batteryValues[i],
        label: hoursLabels[i],
      ));
      solarHistory.add(HistoricalDataPoint(
        time: pointTime,
        value: solarValues[i],
        label: hoursLabels[i],
      ));
      pcmHistory.add(HistoricalDataPoint(
        time: pointTime,
        value: pcmValues[i],
        label: hoursLabels[i],
      ));
    }

    final double minT = tempValues.reduce((a, b) => a < b ? a : b);
    final double maxT = tempValues.reduce((a, b) => a > b ? a : b);
    final double avgT = tempValues.reduce((a, b) => a + b) / tempValues.length;

    final double minB = batteryValues.reduce((a, b) => a < b ? a : b);
    final double maxB = batteryValues.reduce((a, b) => a > b ? a : b);
    final double avgB =
        batteryValues.reduce((a, b) => a + b) / batteryValues.length;

    return StorageAnalytics(
      unitId: unitId,
      temperatureHistory: tempHistory,
      batteryHistory: batteryHistory,
      solarHistory: solarHistory,
      pcmHistory: pcmHistory,
      minTemp: minT,
      maxTemp: maxT,
      avgTemp: avgT,
      minBattery: minB,
      maxBattery: maxB,
      avgBattery: avgB,
      peakSolarWatts: solarValues.reduce((a, b) => a > b ? a : b),
      totalSolarGeneratedKwh: 4.85,
      doorOpenCountToday: unitId == 'AC-NER-003' ? 8 : 2,
      doorOpenDurationMinutes: unitId == 'AC-NER-003' ? 34.0 : 4.5,
      pcmDrainRatePerHour: unitId == 'AC-NER-002' ? 0.45 : 0.05,
      deviceHealth: DeviceHealthStatus(
        controllerStatus: StatusLevel.good,
        controllerFirmware: 'v2.4.1-ner-esp32',
        compressorStatus:
            unitId == 'AC-NER-003' ? StatusLevel.attention : StatusLevel.good,
        compressorHoursRun: 1840,
        tempSensorStatus: StatusLevel.good,
        humiditySensorStatus: StatusLevel.good,
        solarInverterStatus: StatusLevel.good,
        networkSignalRssi: -64,
        connectivityType: '4G LTE (Airtel IoT SIM)',
      ),
    );
  }
}
