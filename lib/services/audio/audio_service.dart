import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/localization/voice_language.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  FlutterTts? _flutterTts;
  bool _isPlaying = false;
  bool _isInitialized = false;
  VoiceLanguage _currentLanguage = VoiceLanguage.english;
  double _speechRate = 0.45;

  bool get isPlaying => _isPlaying;
  VoiceLanguage get currentLanguage => _currentLanguage;
  double get speechRate => _speechRate;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _flutterTts = FlutterTts();
      await _applyLanguageAndRate();

      _flutterTts?.setCompletionHandler(() {
        _isPlaying = false;
      });

      _flutterTts?.setCancelHandler(() {
        _isPlaying = false;
      });

      _flutterTts?.setErrorHandler((msg) {
        _isPlaying = false;
        debugPrint('TTS Error: $msg');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS Initialization Note: $e');
    }
  }

  Future<void> setLanguage(VoiceLanguage language) async {
    _currentLanguage = language;
    await _applyLanguageAndRate();
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _applyLanguageAndRate();
  }

  Future<void> _applyLanguageAndRate() async {
    try {
      if (_flutterTts == null) return;
      await _flutterTts?.setLanguage(_currentLanguage.code);
      await _flutterTts?.setSpeechRate(_speechRate);
      await _flutterTts?.setVolume(1.0);
      await _flutterTts?.setPitch(1.0);
    } catch (e) {
      debugPrint('TTS config note: $e');
    }
  }

  Future<void> speak(String text) async {
    try {
      if (!_isInitialized) {
        await init();
      }
      if (_isPlaying) {
        await stop();
      }
      _isPlaying = true;
      if (_flutterTts != null) {
        await _flutterTts?.speak(text);
      }
    } catch (e) {
      _isPlaying = false;
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      _isPlaying = false;
      await _flutterTts?.stop();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }
}
