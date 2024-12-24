import 'dart:async';
import 'dart:io' show Platform;

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsStateEnum { playing, stopped, paused, continued }

class Tts extends BaseAudioHandler with QueueHandler, SeekHandler {
  static FlutterTts flutterTts = FlutterTts();
  static String? language;
  static String? engine;

  static bool isInit = false;

  static double get volume => Prefs().ttsVolume;

  static double get pitch => Prefs().ttsPitch;

  static double get rate => Prefs().ttsRate;

  static set volume(double volume) {
    restart();
    Prefs().ttsVolume = volume;
  }

  static set pitch(double pitch) {
    restart();
    Prefs().ttsPitch = pitch;
  }

  static set rate(double rate) {
    restart();
    Prefs().ttsRate = rate;
  }

  static ValueNotifier<TtsStateEnum> ttsStateNotifier =
      ValueNotifier<TtsStateEnum>(TtsStateEnum.stopped);

  static void updateTtsState(TtsStateEnum newState) {
    ttsStateNotifier.value = newState;
  }

  static bool isCurrentLanguageInstalled = false;

  static String? _currentVoiceText;

  static String? _prevVoiceText;

  static bool get isPlaying => ttsStateNotifier.value == TtsStateEnum.playing;

  static bool get isIOS => !kIsWeb && Platform.isIOS;

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  static bool get isWindows => !kIsWeb && Platform.isWindows;

  static bool get isWeb => kIsWeb;

  static Function getNextVoiceText = () => '';

  static Function getPrevVoiceText = () => '';

  static Function getHere = () => '';

  static Future<void> init(Function here, Function next, Function prev) async {
    if (isInit) return;
    getHere = here;
    isInit = true;
    getNextVoiceText = next;
    getPrevVoiceText = prev;

    setAwaitOptions();

    if (isAndroid) {
      getDefaultEngine();
      getDefaultVoice();
    }

    flutterTts.setStartHandler(() async {
      updateTtsState(TtsStateEnum.playing);
      if (isWindows) {
        return;
      }
      _prevVoiceText = _currentVoiceText;
      _currentVoiceText = await epubPlayerKey.currentState!.ttsPrepare();

      if (_currentVoiceText?.isNotEmpty ?? false) {
        flutterTts.speak(_currentVoiceText!);
      }
    });

    flutterTts.setCompletionHandler(() async {
      updateTtsState(TtsStateEnum.playing);
      if (isWindows) {
        return;
      }
      if (_currentVoiceText?.isEmpty ?? true) {
        _currentVoiceText = await getNextVoiceText();
        speak();
      } else {
        getNextVoiceText();
      }
    });
  }

  static Future<dynamic> getLanguages() async => await flutterTts.getLanguages;

  static Future<dynamic> getEngines() async => await flutterTts.getEngines;

  static Future<void> getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {}
  }

  static Future<void> getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {}
  }

  static Future<void> speak({String? content}) async {
    await setAwaitOptions();
    if (content != null) {
      _currentVoiceText = content;
    }
    _currentVoiceText ??= await getHere();
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    // at speak begin, ttsStartHandler will be called,
    // a new voice text will be set there and begin synthesize

    // at speak complete, ttsCompletionHandler will be called,
    // a new voice text will be set there and begin synthesize
    await flutterTts.speak(_currentVoiceText!);
    if (isWindows && ttsStateNotifier.value == TtsStateEnum.playing) {
      _currentVoiceText = await getNextVoiceText();
      speak();
    }
  }

  static Future<void> setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
    if (isAndroid) {
      await flutterTts.awaitSynthCompletion(true);
      await flutterTts.setQueueMode(1);
    }
  }

  @override
  Future<void> stop() async {
    stopStatic();
    isInit = false;
    _currentVoiceText = null;
    epubPlayerKey.currentState!.ttsStop();
    updateTtsState(TtsStateEnum.stopped);
  }

  @override
  Future<void> pause() async {
    await stopStatic();
    updateTtsState(TtsStateEnum.paused);
  }

  @override
  Future<void> play() async {
    if (isAndroid && ttsStateNotifier.value == TtsStateEnum.paused) {
      _currentVoiceText = _prevVoiceText;
    }
    await speak();
    updateTtsState(TtsStateEnum.playing);
  }

  static Future<int> stopStatic() async {
    return await flutterTts.stop();
  }

  static Future<void> pauseStatic() async {
    var result = await flutterTts.pause();
    if (result == 1) {
      updateTtsState(TtsStateEnum.paused);
    }
  }

  static Future<void> prev() async {
    await stopStatic();
    _currentVoiceText = await getPrevVoiceText();
    speak();
  }

  static Future<void> next() async {
    await stopStatic();
    _currentVoiceText = await getNextVoiceText();
    speak();
  }

  static Future<void> restart() async {
    await stopStatic();
    await speak();
  }

  static List<DropdownMenuItem<String>> getEnginesDropDownMenuItems(
      List<dynamic> engines) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in engines) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text((type as String))));
    }
    return items;
  }

  static void changedEnginesDropDownItem(String? selectedEngine) async {
    await flutterTts.setEngine(selectedEngine!);
    language = null;
    engine = selectedEngine;
  }

  static List<DropdownMenuItem<String>> getLanguageDropDownMenuItems(
      List<dynamic> languages) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in languages) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text((type as String))));
    }
    return items;
  }

  static void changedLanguageDropDownItem(String? selectedType) {
    language = selectedType;
    flutterTts.setLanguage(language!);
    if (isAndroid) {
      flutterTts
          .isLanguageInstalled(language!)
          .then((value) => isCurrentLanguageInstalled = (value as bool));
    }
  }
}
