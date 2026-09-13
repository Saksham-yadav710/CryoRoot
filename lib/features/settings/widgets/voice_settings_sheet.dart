import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/voice_language.dart';
import '../../../state/audio_providers.dart';

class VoiceSettingsSheet extends ConsumerWidget {
  const VoiceSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLanguage = ref.watch(selectedVoiceLanguageProvider);
    final speechRate = ref.watch(voiceSpeechRateProvider);
    final audioController = ref.watch(enhancedAudioControllerProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.record_voice_over_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice & Language Settings',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Audio spoken in regional North-East languages',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Regional Voice Selection Header
          const Text(
            'SELECT AUDIO LANGUAGE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // 5 Regional Languages Radio List
          ...VoiceLanguage.values.map((lang) {
            final isSelected = lang == selectedLanguage;
            return InkWell(
              onTap: () {
                ref.read(selectedVoiceLanguageProvider.notifier).state = lang;
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryContainer.withValues(alpha: 0.5)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textTertiary,
                          width: 2,
                        ),
                        color: isSelected ? AppColors.primary : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Center(
                              child: Icon(
                                Icons.circle,
                                size: 10,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${lang.nativeName} (${lang.displayName})',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            lang.region,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Speech Pace / Speed Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Speech Speed (Clarity)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              Text(
                speechRate <= 0.38
                    ? 'Slow (Clear)'
                    : speechRate <= 0.52
                        ? 'Normal'
                        : 'Fast',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          Slider(
            value: speechRate,
            min: 0.30,
            max: 0.70,
            divisions: 4,
            activeColor: AppColors.primary,
            onChanged: (val) {
              ref.read(voiceSpeechRateProvider.notifier).state = val;
            },
          ),

          const SizedBox(height: 14),

          // Bottom Action Row (Test Voice + Save)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final sample = switch (selectedLanguage) {
                      VoiceLanguage.assamese =>
                        'নমস্কাৰ কৃষক বন্ধু। এগ্ৰিকুললৈ স্বাগতম। আপোনাৰ শস্য সম্পূর্ণ নিৰাপদ।',
                      VoiceLanguage.hindi =>
                        'नमस्ते किसान भाई। एग्रीकूल में आपका स्वागत है। आपकी फसल सुरक्षित है।',
                      VoiceLanguage.khasi =>
                        'Khublei. Ka mar rep jong phi ka shngain ha AgriCool.',
                      VoiceLanguage.manipuri =>
                        'Khurumjari. AgriCool da nahakki potthok kanna lei.',
                      VoiceLanguage.english =>
                        'Welcome to AgriCool NER. Your cold storage produce is safe.',
                    };
                    audioController.service.setLanguage(selectedLanguage);
                    audioController.service.setSpeechRate(speechRate);
                    audioController.service.speak(sample);
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('TEST VOICE'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('SAVE SETTINGS'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
