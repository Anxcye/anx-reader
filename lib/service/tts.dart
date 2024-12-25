import 'dart:async';
import 'dart:io' show Platform;

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audio_session/audio_session.dart';

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

  @override
  Future<void> stop() async {
    playbackState.add(playbackState.value.copyWith(
      controls: [],
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
    stopStatic();
    isInit = false;
    _currentVoiceText = null;
    epubPlayerKey.currentState?.ttsStop();
    updateTtsState(TtsStateEnum.stopped);
  }

  @override
  Future<void> pause() async {
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.play, MediaControl.stop],
      processingState: AudioProcessingState.ready,
      playing: false,
    ));

    await stopStatic();
    updateTtsState(TtsStateEnum.paused);
  }

  @override
  Future<void> play() async {
    final session = await AudioSession.instance;
    // flutter_tts doesn't activate the session, so we do it here. This
    // allows the app to stop other apps from playing audio while we are
    // playing audio.
    if (await session.setActive(true)) {
      // If we successfully activated the session, set the state to playing
      // and resume playback.
      playbackState.add(playbackState.value.copyWith(
        controls: [MediaControl.pause, MediaControl.stop],
        processingState: AudioProcessingState.ready,
        playing: true,
      ));
    }

    mediaItem.add(MediaItem(
      id: epubPlayerKey.currentState!.chapterTitle,
      title: epubPlayerKey.currentState!.chapterTitle,
      album: epubPlayerKey.currentState!.book.title,
      artist: epubPlayerKey.currentState!.book.author,
      artUri: Uri.tryParse(
          'file://${epubPlayerKey.currentState!.book.coverFullPath}'),
    ));

    if (isAndroid && ttsStateNotifier.value == TtsStateEnum.paused) {
      _currentVoiceText = _prevVoiceText;
    }
    await speak();
    updateTtsState(TtsStateEnum.playing);
  }

  Tts() {
    _initTts();
  }

  Future<void> _initTts() async {
    final session = await AudioSession.instance;
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        if (isPlaying) {
          pause();
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.pause:
          case AudioInterruptionType.duck:
            if (!isPlaying) {
              play();
            }
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });
    session.becomingNoisyEventStream.listen((_) {
      if (isPlaying) pause();
    });
  }
}
