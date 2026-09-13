import 'package:flutter_test/flutter_test.dart';
import 'package:cryoroots/core/localization/voice_language.dart';
import 'package:cryoroots/models/produce_batch.dart';
import 'package:cryoroots/services/audio/natural_voice_generator.dart';
import 'package:cryoroots/services/mock/mock_storage_data.dart';
import 'package:cryoroots/services/mock/crop_profiles_data.dart';
import 'package:cryoroots/services/rules/alert_rule_engine.dart';

void main() {
  group('Natural Voice Generator Multilingual Tests', () {
    final testUnit = MockStorageData.getUnits().first;

    test('Generates English overview speech correctly', () {
      final speech = NaturalVoiceGenerator.generateUnitOverview(
        unit: testUnit,
        language: VoiceLanguage.english,
      );

      expect(speech, contains('Cold Storage 1'));
      expect(speech, contains('4.2 degrees'));
      expect(speech, contains('90 percent'));
      expect(speech, contains('produce is safe'));
    });

    test('Generates Assamese overview speech correctly', () {
      final speech = NaturalVoiceGenerator.generateUnitOverview(
        unit: testUnit,
        language: VoiceLanguage.assamese,
      );

      expect(speech, contains('নমস্কাৰ'));
      expect(speech, contains('Cold Storage 1'));
      expect(speech, contains('ডিগ্ৰী'));
      expect(speech, contains('শস্য'));
    });

    test('Generates Hindi overview speech correctly', () {
      final speech = NaturalVoiceGenerator.generateUnitOverview(
        unit: testUnit,
        language: VoiceLanguage.hindi,
      );

      expect(speech, contains('नमस्ते'));
      expect(speech, contains('Cold Storage 1'));
      expect(speech, contains('डिग्री'));
      expect(speech, contains('फसल'));
    });

    test('Generates Khasi overview speech correctly', () {
      final speech = NaturalVoiceGenerator.generateUnitOverview(
        unit: testUnit,
        language: VoiceLanguage.khasi,
      );

      expect(speech, contains('Khublei'));
      expect(speech, contains('Cold Storage 1'));
      expect(speech, contains('4.2 degree'));
      expect(speech, contains('mar rep'));
    });

    test('Generates Manipuri overview speech correctly', () {
      final speech = NaturalVoiceGenerator.generateUnitOverview(
        unit: testUnit,
        language: VoiceLanguage.manipuri,
      );

      expect(speech, contains('Khurumjari'));
      expect(speech, contains('Cold Storage 1'));
      expect(speech, contains('4.2 degree'));
      expect(speech, contains('potthok'));
    });

    test('Generates Multilingual Detailed Diagnostics Speech', () {
      final analytics = MockStorageData.getAnalyticsForUnit(testUnit.id);

      for (final lang in VoiceLanguage.values) {
        final text = NaturalVoiceGenerator.generateDetailedDiagnostics(
          unit: testUnit,
          analytics: analytics,
          language: lang,
        );
        expect(text.isNotEmpty, isTrue);
      }
    });

    test('Generates Multilingual Crop Produce Reports', () {
      final tomato = CropProfilesData.getProfiles().first;
      final batch = ProduceBatch(
        batchId: 'AC-2026-00125',
        unitId: testUnit.id,
        unitName: testUnit.name,
        cropProfile: tomato,
        quantityKg: 1200,
        entryDate: DateTime.now().subtract(const Duration(days: 4)),
      );

      for (final lang in VoiceLanguage.values) {
        final text = NaturalVoiceGenerator.generateProduceReport(
          batch: batch,
          currentTemp: 4.2,
          remainingDays: 24,
          language: lang,
        );
        expect(text.isNotEmpty, isTrue);
      }
    });

    test('Generates Multilingual Alert Speeches', () {
      final alerts =
          AlertRuleEngine.evaluateAllUnits(MockStorageData.getUnits());
      expect(alerts.isNotEmpty, isTrue);
      final alert = alerts.first;

      for (final lang in VoiceLanguage.values) {
        final text = NaturalVoiceGenerator.generateAlertSpeech(
          alert: alert,
          language: lang,
        );
        expect(text.isNotEmpty, isTrue);
      }
    });
  });
}
