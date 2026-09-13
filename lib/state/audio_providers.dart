import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/localization/voice_language.dart';
import '../models/cold_storage_unit.dart';
import '../models/storage_analytics.dart';
import '../models/produce_batch.dart';
import '../models/alert_item.dart';
import '../services/audio/audio_service.dart';
import '../services/audio/natural_voice_generator.dart';
import 'storage_providers.dart';

// 1. Voice Language Selection Provider
final selectedVoiceLanguageProvider =
    StateProvider<VoiceLanguage>((ref) => VoiceLanguage.english);

// 2. Speech Rate Provider (0.35 = Slow for clarity, 0.5 = Normal)
final voiceSpeechRateProvider = StateProvider<double>((ref) => 0.45);

// 3. Live Spoken Caption / Subtitle Text Provider
final liveSpokenCaptionProvider = StateProvider<String?>((ref) => null);

// 4. Enhanced Audio Controller Provider
final enhancedAudioControllerProvider = Provider((ref) {
  final service = AudioService();
  final language = ref.watch(selectedVoiceLanguageProvider);
  final rate = ref.watch(voiceSpeechRateProvider);

  return EnhancedAudioController(
    service: service,
    language: language,
    rate: rate,
    onSpeechStart: (text) {
      ref.read(liveSpokenCaptionProvider.notifier).state = text;
      ref.read(isAudioPlayingProvider.notifier).state = true;
    },
    onSpeechEnd: () {
      ref.read(liveSpokenCaptionProvider.notifier).state = null;
      ref.read(isAudioPlayingProvider.notifier).state = false;
    },
  );
});

class EnhancedAudioController {
  final AudioService service;
  final VoiceLanguage language;
  final double rate;
  final Function(String) onSpeechStart;
  final Function() onSpeechEnd;

  EnhancedAudioController({
    required this.service,
    required this.language,
    required this.rate,
    required this.onSpeechStart,
    required this.onSpeechEnd,
  });

  Future<void> speakUnitOverview(ColdStorageUnit unit) async {
    await service.setLanguage(language);
    await service.setSpeechRate(rate);

    final text = NaturalVoiceGenerator.generateUnitOverview(
      unit: unit,
      language: language,
    );

    onSpeechStart(text);
    await service.speak(text);
  }

  Future<void> speakDetailedAnalytics(
      ColdStorageUnit unit, StorageAnalytics analytics) async {
    await service.setLanguage(language);
    await service.setSpeechRate(rate);

    final text = NaturalVoiceGenerator.generateDetailedDiagnostics(
      unit: unit,
      analytics: analytics,
      language: language,
    );

    onSpeechStart(text);
    await service.speak(text);
  }

  Future<void> speakProduceReport({
    required ProduceBatch batch,
    required double currentTemp,
    required int remainingDays,
  }) async {
    await service.setLanguage(language);
    await service.setSpeechRate(rate);

    final text = NaturalVoiceGenerator.generateProduceReport(
      batch: batch,
      currentTemp: currentTemp,
      remainingDays: remainingDays,
      language: language,
    );

    onSpeechStart(text);
    await service.speak(text);
  }

  Future<void> speakAlert(AlertItem alert) async {
    await service.setLanguage(language);
    await service.setSpeechRate(rate);

    final text = NaturalVoiceGenerator.generateAlertSpeech(
      alert: alert,
      language: language,
    );

    onSpeechStart(text);
    await service.speak(text);
  }

  Future<void> speakMarketDecision({
    required String cropName,
    required String decisionLabel,
    required String mandiName,
    required double currentPrice,
    required double projectedPrice,
    required double expectedGain,
  }) async {
    await service.setLanguage(language);
    await service.setSpeechRate(rate);

    final text = NaturalVoiceGenerator.generateMarketDecisionSpeech(
      cropName: cropName,
      decisionLabel: decisionLabel,
      mandiName: mandiName,
      currentPrice: currentPrice,
      projectedPrice: projectedPrice,
      expectedGain: expectedGain,
      language: language,
    );

    onSpeechStart(text);
    await service.speak(text);
  }

  Future<void> speakTransitAdvisory({
    required String cropName,
    required String destinationMandi,
    required double currentTemp,
    required double batteryOrPcmHours,
    required String statusLabel,
  }) async {
    await service.setLanguage(language);
    await service.setSpeechRate(rate);

    final text = NaturalVoiceGenerator.generateTransitAdvisorySpeech(
      cropName: cropName,
      destinationMandi: destinationMandi,
      currentTemp: currentTemp,
      batteryOrPcmHours: batteryOrPcmHours,
      statusLabel: statusLabel,
      language: language,
    );

    onSpeechStart(text);
    await service.speak(text);
  }

  Future<void> speakText(String text) async {
    await service.setLanguage(language);
    await service.setSpeechRate(rate);
    onSpeechStart(text);
    await service.speak(text);
  }

  Future<void> stop() async {
    await service.stop();
    onSpeechEnd();
  }
}
