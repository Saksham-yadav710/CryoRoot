import 'package:flutter_test/flutter_test.dart';
import 'package:agricool_ner/models/produce_batch.dart';
import 'package:agricool_ner/models/status_level.dart';
import 'package:agricool_ner/core/localization/voice_language.dart';
import 'package:agricool_ner/services/mock/mock_storage_data.dart';
import 'package:agricool_ner/services/mock/crop_profiles_data.dart';
import 'package:agricool_ner/services/mock/market_data.dart';
import 'package:agricool_ner/services/rules/alert_rule_engine.dart';
import 'package:agricool_ner/services/decision/market_decision_engine.dart';
import 'package:agricool_ner/services/audio/natural_voice_generator.dart';
import 'package:agricool_ner/services/offline/offline_sync_service.dart';
import 'package:agricool_ner/state/connectivity_provider.dart';

void main() {
  group('🚀 CryoRoot Performance & Micro-Benchmark Suite', () {
    final testUnit = MockStorageData.getUnits().first;

    test('Benchmark: AlertRuleEngine High-Throughput Diagnostics', () {
      const iterations = 10000;
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < iterations; i++) {
        final alerts = AlertRuleEngine.evaluateUnit(testUnit);
        expect(alerts, isNotNull);
      }

      stopwatch.stop();
      final totalMs = stopwatch.elapsedMilliseconds;
      final perOpUs =
          (stopwatch.elapsedMicroseconds / iterations).toStringAsFixed(2);

      // ignore: avoid_print
      print(
          '\n[BENCHMARK] AlertRuleEngine: $iterations evaluations in ${totalMs}ms ($perOpUs µs/op)');
      expect(totalMs, lessThan(1000),
          reason: 'Must complete 10k evaluations in under 1 second');
    });

    test('Benchmark: Thermal Shelf-Life & Kinetic Degradation Engine', () {
      final tomato = CropProfilesData.getProfiles()
          .firstWhere((c) => c.id == 'CROP-TOMATO');
      final batch = ProduceBatch(
        batchId: 'BENCH-001',
        cropProfile: tomato,
        quantityKg: 2000,
        unitId: 'AC-NER-001',
        unitName: 'Cold Storage 1',
        entryDate: DateTime.now().subtract(const Duration(days: 4)),
      );

      const iterations = 20000;
      final stopwatch = Stopwatch()..start();

      int sumDays = 0;
      for (int i = 0; i < iterations; i++) {
        final temp = 2.0 + (i % 14);
        final safeDays = batch.estimatedRemainingDays(temp);
        final condition = batch.condition(temp, 90.0);
        sumDays += safeDays + (condition == StatusLevel.good ? 1 : 0);
      }

      stopwatch.stop();
      final totalMs = stopwatch.elapsedMilliseconds;
      final perOpUs =
          (stopwatch.elapsedMicroseconds / iterations).toStringAsFixed(2);

      // ignore: avoid_print
      print(
          '[BENCHMARK] Thermal Degradation Engine: $iterations calculations in ${totalMs}ms ($perOpUs µs/op)');
      expect(sumDays, greaterThan(0));
      expect(totalMs, lessThan(500),
          reason: 'Must complete 20k calculations in under 500ms');
    });

    test('Benchmark: APMC Market Decision & EVA Profit Optimization', () {
      final batch = ProduceBatch(
        batchId: 'BENCH-MANDARIN',
        cropProfile: CropProfilesData.khasiMandarin,
        quantityKg: 2500,
        unitId: 'AC-NER-001',
        unitName: 'Cold Storage 1',
        entryDate: DateTime.now().subtract(const Duration(days: 5)),
      );

      const iterations = 5000;
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < iterations; i++) {
        final quotes = MarketDataService.getQuotesForCrop(
            CropProfilesData.khasiMandarin.id);
        final decision = MarketDecisionEngine.evaluateBatch(
          batch: batch,
          currentChamberTemp: 4.2,
        );
        expect(quotes.isNotEmpty, true);
        expect(decision.rationale.isNotEmpty, true);
      }

      stopwatch.stop();
      final totalMs = stopwatch.elapsedMilliseconds;
      final perOpUs =
          (stopwatch.elapsedMicroseconds / iterations).toStringAsFixed(2);

      // ignore: avoid_print
      print(
          '[BENCHMARK] APMC Decision & EVA Engine: $iterations evaluations in ${totalMs}ms ($perOpUs µs/op)');
      expect(totalMs, lessThan(800),
          reason: 'Must complete 5k evaluations in under 800ms');
    });

    test(
        'Benchmark: Multilingual Natural Voice Synthesis (5 Regional Dialects)',
        () {
      final languages = [
        VoiceLanguage.assamese,
        VoiceLanguage.khasi,
        VoiceLanguage.manipuri,
        VoiceLanguage.hindi,
        VoiceLanguage.english,
      ];

      const iterations = 1000; // 5000 total sentences
      final stopwatch = Stopwatch()..start();

      int charCount = 0;
      for (int i = 0; i < iterations; i++) {
        for (final lang in languages) {
          final speech = NaturalVoiceGenerator.generateUnitOverview(
            unit: testUnit,
            language: lang,
          );
          charCount += speech.length;
        }
      }

      stopwatch.stop();
      final totalMs = stopwatch.elapsedMilliseconds;
      final perSentenceUs =
          (stopwatch.elapsedMicroseconds / (iterations * languages.length))
              .toStringAsFixed(2);

      // ignore: avoid_print
      print(
          '[BENCHMARK] Voice Generator: ${iterations * languages.length} synthesized sentences in ${totalMs}ms ($perSentenceUs µs/sentence, Total chars: $charCount)');
      expect(totalMs, lessThan(1000),
          reason: 'Must synthesize 5,000 multi-dialect sentences in under 1s');
    });

    test('Benchmark: Offline Cache Queue & State Transactions', () {
      final notifier = OfflineCacheNotifier(
        OfflineStorageCache(
          lastCachedTime: DateTime.now(),
          cachedUnits: MockStorageData.getUnits(),
          cachedBatches: [],
          cachedAlerts: [],
        ),
      );

      const actionCount = 3000;
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < actionCount; i++) {
        notifier.queueAction(
          SyncActionType.addProduceBatch,
          {'batchId': 'BATCH-$i', 'temp': 4.2},
        );
      }

      expect(notifier.state.pendingQueueCount, actionCount);
      stopwatch.stop();

      final totalMs = stopwatch.elapsedMilliseconds;
      final perActionUs =
          (stopwatch.elapsedMicroseconds / actionCount).toStringAsFixed(2);

      // ignore: avoid_print
      print(
          '[BENCHMARK] Offline Cache Queue: $actionCount actions queued in ${totalMs}ms ($perActionUs µs/action)');
      expect(totalMs, lessThan(500));
    });
  });
}
