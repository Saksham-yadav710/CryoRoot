import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transit_manifest.dart';
import '../models/produce_batch.dart';
import '../services/mock/crop_profiles_data.dart';
import 'produce_providers.dart';

final transitManifestsProvider =
    StateNotifierProvider<TransitManifestsNotifier, List<TransitManifest>>((ref) {
  return TransitManifestsNotifier(ref);
});

class TransitManifestsNotifier extends StateNotifier<List<TransitManifest>> {
  final Ref ref;
  static int _manifestCounter = 83; // starts after the 2 seeded manifests (0081, 0082)

  TransitManifestsNotifier(this.ref) : super(_getInitialManifests());

  static List<TransitManifest> _getInitialManifests() {
    final profiles = CropProfilesData.getProfiles();
    final orange = profiles.firstWhere((c) => c.id == 'CROP-ORANGE');
    final tomato = profiles.firstWhere((c) => c.id == 'CROP-TOMATO');
    final now = DateTime.now();

    return [
      TransitManifest(
        manifestId: 'TR-NER-2026-0081',
        batchId: 'AC-2026-00120',
        cropProfile: orange,
        quantityKg: 1500,
        originUnitId: 'AC-NER-003',
        originUnitName: 'Cold Storage 3 (Sonitpur)',
        destinationMandi: 'Guwahati APMC Mandi (Pamohi)',
        transitMode: TransitMode.solarReeferVan,
        status: TransitStatus.inTransit,
        departureTime: now.subtract(const Duration(hours: 2, minutes: 15)),
        estimatedArrivalTime: now.add(const Duration(hours: 1, minutes: 45)),
        currentTemp: 5.8,
        currentHumidity: 88.0,
        batteryOrPcmHours: 7.5,
        vehicleNumber: 'AS-01-ET-9024',
        driverName: 'Biren Barman',
        driverPhone: '+91 94350 12849',
        buyerNotes: 'Premium Khasi Mandarin consignment for wholesale auction.',
        telemetryLogs: [
          TransitDataPoint(
            timestamp: now.subtract(const Duration(hours: 2)),
            temperature: 5.2,
            humidity: 90.0,
          ),
          TransitDataPoint(
            timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
            temperature: 5.5,
            humidity: 89.0,
          ),
          TransitDataPoint(
            timestamp: now.subtract(const Duration(hours: 1)),
            temperature: 5.6,
            humidity: 88.5,
          ),
          TransitDataPoint(
            timestamp: now.subtract(const Duration(minutes: 30)),
            temperature: 5.8,
            humidity: 88.0,
          ),
        ],
      ),
      TransitManifest(
        manifestId: 'TR-NER-2026-0082',
        batchId: 'AC-2026-00119',
        cropProfile: tomato,
        quantityKg: 800,
        originUnitId: 'AC-NER-001',
        originUnitName: 'Cold Storage 1 (Sonapur)',
        destinationMandi: 'Shillong Iewduh Market',
        transitMode: TransitMode.insulatedPcmCrate,
        status: TransitStatus.arrivingSoon,
        departureTime: now.subtract(const Duration(hours: 3)),
        estimatedArrivalTime: now.add(const Duration(minutes: 20)),
        currentTemp: 9.4,
        currentHumidity: 86.0,
        batteryOrPcmHours: 4.2,
        vehicleNumber: 'ML-05-D-4311',
        driverName: 'Kitdor Wahlang',
        driverPhone: '+91 98620 48192',
        buyerNotes: 'Pre-cooled Avinash tomato crates in sealed PCM insulation.',
        telemetryLogs: [
          TransitDataPoint(
            timestamp: now.subtract(const Duration(hours: 3)),
            temperature: 8.5,
            humidity: 88.0,
          ),
          TransitDataPoint(
            timestamp: now.subtract(const Duration(hours: 2)),
            temperature: 8.9,
            humidity: 87.0,
          ),
          TransitDataPoint(
            timestamp: now.subtract(const Duration(hours: 1)),
            temperature: 9.2,
            humidity: 86.5,
          ),
        ],
      ),
    ];
  }

  String generateManifestId() {
    final id = 'TR-NER-2026-${_manifestCounter.toString().padLeft(4, '0')}';
    _manifestCounter++;
    return id;
  }

  void dispatchBatchToTransit({
    required ProduceBatch batch,
    required String destinationMandi,
    required TransitMode transitMode,
    required String vehicleNumber,
    required String driverName,
    required String driverPhone,
    required int estimatedTransitHours,
    String notes = '',
  }) {
    final now = DateTime.now();
    final newManifest = TransitManifest(
      manifestId: generateManifestId(),
      batchId: batch.batchId,
      cropProfile: batch.cropProfile,
      quantityKg: batch.quantityKg,
      originUnitId: batch.unitId,
      originUnitName: batch.unitName,
      destinationMandi: destinationMandi,
      transitMode: transitMode,
      status: TransitStatus.inTransit,
      departureTime: now,
      estimatedArrivalTime: now.add(Duration(hours: estimatedTransitHours)),
      currentTemp: batch.cropProfile.optimalTempMin + 0.5,
      currentHumidity: batch.cropProfile.optimalHumidityMin + 2.0,
      batteryOrPcmHours: transitMode == TransitMode.solarReeferVan ? 8.0 : 10.0,
      vehicleNumber: vehicleNumber,
      driverName: driverName,
      driverPhone: driverPhone,
      buyerNotes: notes,
      telemetryLogs: [
        TransitDataPoint(
          timestamp: now,
          temperature: batch.cropProfile.optimalTempMin + 0.5,
          humidity: batch.cropProfile.optimalHumidityMin + 2.0,
        ),
      ],
    );

    // Add to active transits
    state = [newManifest, ...state];

    // Remove from storage batch inventory
    ref.read(produceBatchesProvider.notifier).dispatchBatch(batch.batchId);
  }

  void markDelivered(String manifestId) {
    state = state.map((m) {
      if (m.manifestId == manifestId) {
        return m.copyWith(status: TransitStatus.delivered);
      }
      return m;
    }).toList();
  }

  void updateTransitTemp(String manifestId, double temp) {
    state = state.map((m) {
      if (m.manifestId == manifestId) {
        final newLogs = [
          ...m.telemetryLogs,
          TransitDataPoint(
            timestamp: DateTime.now(),
            temperature: temp,
            humidity: m.currentHumidity,
          ),
        ];
        return m.copyWith(
          currentTemp: temp,
          telemetryLogs: newLogs,
          status: temp > m.cropProfile.optimalTempMax + 2.0
              ? TransitStatus.temperatureWarning
              : m.status,
        );
      }
      return m;
    }).toList();
  }
}

// Active in-transit filter provider
final activeTransitsProvider = Provider<List<TransitManifest>>((ref) {
  final all = ref.watch(transitManifestsProvider);
  return all.where((m) => m.status != TransitStatus.delivered).toList();
});
