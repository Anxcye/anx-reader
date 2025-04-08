import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/service/tts/base_tts.dart';
import 'package:anx_reader/service/tts/edge_tts.dart';
import 'package:anx_reader/service/tts/system_tts.dart';
import 'package:flutter/material.dart';

class TtsFactory {
  static final TtsFactory _instance = TtsFactory._internal();

  factory TtsFactory() {
    return _instance;
  }

  TtsFactory._internal();

  BaseTts? _currentTts;

  BaseTts get current {
    _currentTts ??= createTts();
    return _currentTts!;
  }

  BaseTts createTts() {
    final bool isSystemTts = Prefs().isSystemTts;
    return isSystemTts ? SystemTts() : EdgeTts();
  }

  Future<void> switchTtsType(bool useSystemTts) async {
    if (Prefs().isSystemTts == useSystemTts) return;

    if (_currentTts != null) {
      await _currentTts!.stop();
      await _currentTts!.dispose();
      _currentTts = null;
    }

    Prefs().isSystemTts = useSystemTts;
    _currentTts = createTts();
  }

  Future<void> dispose() async {
    if (_currentTts != null) {
      await _currentTts!.stop();
      await _currentTts!.dispose();
      _currentTts = null;
    }
  }

  ValueNotifier<TtsStateEnum> get ttsStateNotifier {
    return current.ttsStateNotifier;
  }
}
