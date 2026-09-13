import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryoroots/models/transit_manifest.dart';
import 'package:cryoroots/state/produce_providers.dart';
import 'package:cryoroots/state/transit_providers.dart';

void main() {
  group('Cold Chain Transit & Dispatch Tests', () {
    test('Initializes with active transits', () {
      final container = ProviderContainer();
      final transits = container.read(transitManifestsProvider);
      final active = container.read(activeTransitsProvider);

      expect(transits.length, greaterThanOrEqualTo(2));
      expect(active.length, greaterThanOrEqualTo(2));
      expect(transits.first.manifestId, contains('TR-NER-2026'));
      expect(transits.first.transitMode, equals(TransitMode.solarReeferVan));
      expect(transits.first.verifiedQualityGrade, contains('Grade A'));
    });

    test('Dispatches a batch from produce into cold chain transit', () {
      final container = ProviderContainer();
      final initialBatches = container.read(produceBatchesProvider);
      final initialTransits = container.read(transitManifestsProvider);

      final batchToDispatch = initialBatches.first;

      container.read(transitManifestsProvider.notifier).dispatchBatchToTransit(
            batch: batchToDispatch,
            destinationMandi: 'Guwahati APMC Mandi (Pamohi)',
            transitMode: TransitMode.solarReeferVan,
            vehicleNumber: 'AS-01-EE-4455',
            driverName: 'Ramen Kalita',
            driverPhone: '+91 94350 99881',
            estimatedTransitHours: 4,
            notes: 'High priority cold chain transfer',
          );

      final updatedBatches = container.read(produceBatchesProvider);
      final updatedTransits = container.read(transitManifestsProvider);

      // Batch should be removed from in-storage batches
      expect(updatedBatches.any((b) => b.batchId == batchToDispatch.batchId),
          isFalse);
      // New transit manifest should be created
      expect(updatedTransits.length, equals(initialTransits.length + 1));
      expect(updatedTransits.first.batchId, equals(batchToDispatch.batchId));
      expect(updatedTransits.first.driverName, equals('Ramen Kalita'));
      expect(updatedTransits.first.status, equals(TransitStatus.inTransit));
    });

    test('Marks transit consignment as delivered', () {
      final container = ProviderContainer();
      final initialActive = container.read(activeTransitsProvider);
      final targetManifest = initialActive.first;

      container
          .read(transitManifestsProvider.notifier)
          .markDelivered(targetManifest.manifestId);

      final updatedTransits = container.read(transitManifestsProvider);
      final delivered = updatedTransits
          .firstWhere((m) => m.manifestId == targetManifest.manifestId);

      expect(delivered.status, equals(TransitStatus.delivered));
    });

    test(
        'Triggers thermal warning when transit temperature exceeds safe limits',
        () {
      final container = ProviderContainer();
      final manifest = container.read(transitManifestsProvider).first;

      // Update temperature to high value above optimal range
      container
          .read(transitManifestsProvider.notifier)
          .updateTransitTemp(manifest.manifestId, 16.0);

      final updated = container
          .read(transitManifestsProvider)
          .firstWhere((m) => m.manifestId == manifest.manifestId);

      expect(updated.currentTemp, equals(16.0));
      expect(updated.status, equals(TransitStatus.temperatureWarning));
      expect(updated.telemetryLogs.length,
          equals(manifest.telemetryLogs.length + 1));
    });
  });
}
