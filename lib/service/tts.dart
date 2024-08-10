import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused, continued }

class Tts {
  static FlutterTts flutterTts = FlutterTts();
  static String? language;
  static String? engine;
  static double _volume = 0.5;
  static double _pitch = 1.0;
  static double _rate = 0.5;
  static bool isInit = false;

  static double get volume => _volume;

  static double get pitch => _pitch;

  static double get rate => _rate;

  static set volume(double volume) {
    restart();
    _volume = volume;
  }

  static set pitch(double pitch) {
    restart();
    _pitch = pitch;
  }

  static set rate(double rate) {
    restart();
    _rate = rate;
  }

  static bool isCurrentLanguageInstalled = false;

  static String? _currentVoiceText;

  static TtsState ttsState = TtsState.stopped;

  static bool get isPlaying => ttsState == TtsState.playing;

  static bool get isStopped => ttsState == TtsState.stopped;

  static bool get isPaused => ttsState == TtsState.paused;

  static bool get isContinued => ttsState == TtsState.continued;

  static bool get isIOS => !kIsWeb && Platform.isIOS;

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  static bool get isWindows => !kIsWeb && Platform.isWindows;

  static bool get isWeb => kIsWeb;

  static Function getNextVoiceText = () => '';

  static Function getPrevVoiceText = () => '';

  static void init(Function next, Function prev) {
    isInit = true;
    getNextVoiceText = next;
    getPrevVoiceText = prev;

    _currentVoiceText = getNextVoiceText();

    setAwaitOptions();

    if (isAndroid) {
      getDefaultEngine();
      getDefaultVoice();
    }

    flutterTts.setStartHandler(() {
      ttsState = TtsState.playing;
    });

    flutterTts.setCompletionHandler(() {
      ttsState = TtsState.stopped;
    });

    flutterTts.setCancelHandler(() {
      ttsState = TtsState.stopped;
    });

    flutterTts.setPauseHandler(() {
      ttsState = TtsState.paused;
    });

    flutterTts.setContinueHandler(() {
      ttsState = TtsState.playing;
    });

    flutterTts.setErrorHandler((msg) {
      ttsState = TtsState.stopped;
    });
  }

  static Future<dynamic> getLanguages() async => await flutterTts.getLanguages;

  static Future<dynamic> getEngines() async => await flutterTts.getEngines;

  static Future<void> getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
    }
  }

  static Future<void> getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {}
  }

  static void toggle() {
    if (isPlaying) {
      stop();
    } else {
      speak();
    }
  }

  static Future<void> speak() async {
    while (_currentVoiceText != null) {
      await flutterTts.setVolume(volume);
      await flutterTts.setSpeechRate(rate);
      await flutterTts.setPitch(pitch);

      await flutterTts.speak(_currentVoiceText!);
      if (!isPlaying) break;
      _currentVoiceText = getNextVoiceText();
    }
  }

  static Future<void> setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.awaitSynthCompletion(true);
  }

  static Future<void> stop() async {
    var result = await flutterTts.stop();
    if (result == 1) ttsState = TtsState.stopped;
  }

  static Future<void> pause() async {
    var result = await flutterTts.pause();
    if (result == 1) ttsState = TtsState.paused;
  }

  static Future<void> prev() async {
    await stop();
    _currentVoiceText = getPrevVoiceText();
    await speak();
  }

  static Future<void> next() async {
    await stop();
    _currentVoiceText = getNextVoiceText();
    await speak();
  }

  static Future<void> restart() async {
    await stop();
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
