import 'dart:async';
import 'dart:io' show Platform;

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/service/tts/base_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SystemTts extends BaseTts {
  static final SystemTts _instance = SystemTts._internal();

  factory SystemTts() {
    return _instance;
  }

  SystemTts._internal();

  final FlutterTts flutterTts = FlutterTts();

  String? _currentVoiceText;

  String? _prevVoiceText;

  late Function getHereFunction;
  late Function getNextTextFunction;
  late Function getPrevTextFunction;

  @override
  final ValueNotifier<TtsStateEnum> ttsStateNotifier =
      ValueNotifier<TtsStateEnum>(TtsStateEnum.stopped);

  @override
  void updateTtsState(TtsStateEnum newState) {
    ttsStateNotifier.value = newState;
  }

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;

  @override
  double get volume => Prefs().ttsVolume;

  @override
  set volume(double volume) {
    restart();
    Prefs().ttsVolume = volume;
  }

  @override
  double get pitch => Prefs().ttsPitch;

  @override
  set pitch(double pitch) {
    restart();
    Prefs().ttsPitch = pitch;
  }

  @override
  double get rate => Prefs().ttsRate;

  @override
  set rate(double rate) {
    restart();
    Prefs().ttsRate = rate;
  }

  @override
  bool get isPlaying => ttsStateNotifier.value == TtsStateEnum.playing;

  @override
  String? get currentVoiceText => _currentVoiceText;

  @override
  Future<void> init(Function getCurrentText, Function getNextText,
      Function getPrevText) async {
    getHereFunction = getCurrentText;
    getNextTextFunction = getNextText;
    getPrevTextFunction = getPrevText;

    await setAwaitOptions();

    if (isAndroid) {
      await getDefaultEngine();
      await getDefaultVoice();
    }

    flutterTts.setStartHandler(() async {
      updateTtsState(TtsStateEnum.playing);
      if (isWindows) {
        return;
      }
      _prevVoiceText = _currentVoiceText;
      _currentVoiceText = await getCurrentText();

      if (_currentVoiceText?.isNotEmpty ?? false) {
        await flutterTts.speak(_currentVoiceText!);
      }
    });

    flutterTts.setCompletionHandler(() async {
      updateTtsState(TtsStateEnum.playing);
      if (isWindows) {
        return;
      }
      if (_currentVoiceText?.isEmpty ?? true) {
        _currentVoiceText = await getNextText();
        await speak();
      } else {
        await getNextText();
      }
    });
  }

  Future<void> setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
    if (isAndroid) {
      await flutterTts.awaitSynthCompletion(true);
      await flutterTts.setQueueMode(1);
    }
  }

  Future<void> getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {}
  }

  Future<void> getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {}
  }

  @override
  Future<void> speak({String? content}) async {
    await setAwaitOptions();
    if (content != null) {
      _currentVoiceText = content;
    }
    _currentVoiceText ??= await getHereFunction();
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    await flutterTts.speak(_currentVoiceText!);
    if (isWindows && ttsStateNotifier.value == TtsStateEnum.playing) {
      _currentVoiceText = await getNextTextFunction();
      speak();
    }
  }

  @override
  Future<dynamic> stop() async {
    final result = await flutterTts.stop();
    _currentVoiceText = null;
    updateTtsState(TtsStateEnum.stopped);
    return result;
  }

  @override
  Future<void> pause() async {
    final result = await flutterTts.pause();
    if (result == 1) {
      updateTtsState(TtsStateEnum.paused);
    }
  }

  @override
  Future<void> resume() async {
    final result = await flutterTts.speak(_currentVoiceText!);
    if (result == 1) {
      updateTtsState(TtsStateEnum.playing);
    }
  }

  @override
  Future<void> prev() async {
    await stop();
    _currentVoiceText = await getPrevTextFunction();
    await speak();
  }

  @override
  Future<void> next() async {
    await stop();
    _currentVoiceText = await getNextTextFunction();
    await speak();
  }

  @override
  Future<void> restart() async {
    await stop();
    await speak();
  }

  @override
  Future<void> dispose() async {
    await flutterTts.stop();
  }
}
