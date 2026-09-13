import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crop_profile.dart';
import '../models/produce_batch.dart';
import '../services/mock/crop_profiles_data.dart';

// 1. Available Crop Profiles Provider
final cropProfilesProvider = Provider<List<CropProfile>>((ref) {
  return CropProfilesData.getProfiles();
});

// 2. Active Produce Batches State Provider
final produceBatchesProvider =
    StateNotifierProvider<ProduceBatchesNotifier, List<ProduceBatch>>((ref) {
  return ProduceBatchesNotifier(ref);
});

class ProduceBatchesNotifier extends StateNotifier<List<ProduceBatch>> {
  final Ref ref;
  static int _batchCounter = 129; // starts after the 4 seeded batches (125-128)

  ProduceBatchesNotifier(this.ref) : super(_getInitialBatches());

  static List<ProduceBatch> _getInitialBatches() {
    final profiles = CropProfilesData.getProfiles();
    final now = DateTime.now();

    final tomato = profiles.firstWhere((c) => c.id == 'CROP-TOMATO');
    final chilli = profiles.firstWhere((c) => c.id == 'CROP-CHILLI');
    final cabbage = profiles.firstWhere((c) => c.id == 'CROP-CABBAGE');
    final orange = profiles.firstWhere((c) => c.id == 'CROP-ORANGE');

    return [
      ProduceBatch(
        batchId: 'AC-2026-00125',
        cropProfile: tomato,
        quantityKg: 2000,
        unitId: 'AC-NER-001',
        unitName: 'Cold Storage 1',
        entryDate: now.subtract(const Duration(days: 4)),
        targetSellingDate: now.add(const Duration(days: 10)),
        notes: 'Harvested from Plot 4B (Avinash-2 Variety). High grade.',
      ),
      ProduceBatch(
        batchId: 'AC-2026-00126',
        cropProfile: chilli,
        quantityKg: 1450,
        unitId: 'AC-NER-001',
        unitName: 'Cold Storage 1',
        entryDate: now.subtract(const Duration(days: 3)),
        targetSellingDate: now.add(const Duration(days: 12)),
        notes: 'Teja Hot Variety. Pre-cooled before loading.',
      ),
      ProduceBatch(
        batchId: 'AC-2026-00127',
        cropProfile: cabbage,
        quantityKg: 2100,
        unitId: 'AC-NER-002',
        unitName: 'Cold Storage 2',
        entryDate: now.subtract(const Duration(days: 8)),
        targetSellingDate: now.add(const Duration(days: 20)),
        notes: 'Stored during local harvest glut. Excellent firm heads.',
      ),
      ProduceBatch(
        batchId: 'AC-2026-00128',
        cropProfile: orange,
        quantityKg: 1800,
        unitId: 'AC-NER-003',
        unitName: 'Cold Storage 3',
        entryDate: now.subtract(const Duration(days: 2)),
        targetSellingDate: now.add(const Duration(days: 15)),
        notes: 'Khasi Mandarin from Sonitpur orchard.',
      ),
    ];
  }

  String generateNextBatchId() {
    final id = 'AC-2026-${_batchCounter.toString().padLeft(5, '0')}';
    _batchCounter++;
    return id;
  }

  void addBatch(ProduceBatch batch) {
    state = [batch, ...state];
  }

  void dispatchBatch(String batchId) {
    state = state.where((b) => b.batchId != batchId).toList();
  }
}

// 3. Filter & Search State Providers
final produceFilterUnitIdProvider = StateProvider<String?>((ref) => null);
final produceSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredProduceBatchesProvider = Provider<List<ProduceBatch>>((ref) {
  final batches = ref.watch(produceBatchesProvider);
  final filterUnitId = ref.watch(produceFilterUnitIdProvider);
  final query = ref.watch(produceSearchQueryProvider).toLowerCase().trim();

  return batches.where((batch) {
    if (filterUnitId != null && batch.unitId != filterUnitId) {
      return false;
    }
    if (query.isNotEmpty) {
      final nameMatches = batch.cropProfile.name.toLowerCase().contains(query);
      final batchMatches = batch.batchId.toLowerCase().contains(query);
      final unitMatches = batch.unitName.toLowerCase().contains(query);
      if (!nameMatches && !batchMatches && !unitMatches) {
        return false;
      }
    }
    return true;
  }).toList();
});

// 4. Total Produce Farm Metrics Provider
class FarmProduceMetrics {
  final double totalKg;
  final double totalEstimatedValuation;
  final int totalBatches;

  const FarmProduceMetrics({
    required this.totalKg,
    required this.totalEstimatedValuation,
    required this.totalBatches,
  });
}

final farmProduceMetricsProvider = Provider<FarmProduceMetrics>((ref) {
  final batches = ref.watch(produceBatchesProvider);
  double totalKg = 0;
  double totalValuation = 0;

  for (final b in batches) {
    totalKg += b.quantityKg;
    totalValuation += b.estimatedMarketValue;
  }

  return FarmProduceMetrics(
    totalKg: totalKg,
    totalEstimatedValuation: totalValuation,
    totalBatches: batches.length,
  );
});
