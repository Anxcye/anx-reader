import 'dart:async';
import 'dart:typed_data';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/service/tts/edge_tts_api.dart';
import 'package:anx_reader/service/tts/base_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class EdgeTts extends BaseTts {
  static final EdgeTts _instance = EdgeTts._internal();

  factory EdgeTts() {
    return _instance;
  }

  EdgeTts._internal();

  AudioPlayer? player;

  String? _currentVoiceText;

  String? _nextVoiceText;

  Uint8List? _nextAudio;

  Uint8List? audioToPlay;

  bool _isLoadingNextAudio = false;

  late Function getHereFunction;
  late Function getNextTextFunction;
  late Function getPrevTextFunction;

  bool isInit = false;

  @override
  final ValueNotifier<TtsStateEnum> ttsStateNotifier =
      ValueNotifier<TtsStateEnum>(TtsStateEnum.stopped);

  @override
  void updateTtsState(TtsStateEnum newState) {
    ttsStateNotifier.value = newState;
  }

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
    if (isInit) return;

    getHereFunction = getCurrentText;
    getNextTextFunction = getNextText;
    getPrevTextFunction = getPrevText;

    isInit = true;
  }

  Future<void> _preloadNextAudio() async {
    if (_isLoadingNextAudio) return;

    _isLoadingNextAudio = true;
    try {
      String prepareText = await getNextTextFunction();
      if (prepareText.isNotEmpty) {
        _nextVoiceText = prepareText;
        _nextAudio = await EdgeTTSApi.getAudio(_nextVoiceText!);
      }
    } finally {
      _isLoadingNextAudio = false;
    }
  }

  @override
  Future<void> speak({String? content}) async {
    player ??= AudioPlayer();
    player!.onPlayerComplete.listen((_) async {
      String temp = await getNextTextFunction();

      if (ttsStateNotifier.value == TtsStateEnum.playing) {
        if (_nextVoiceText != null && _nextAudio != null) {
          _currentVoiceText = _nextVoiceText;
          _nextVoiceText = null;
          audioToPlay = _nextAudio;
          _nextAudio = null;

          await player!.play(BytesSource(audioToPlay!, mimeType: 'audio/mp3'));
          _preloadNextAudio();
        } else {
          await stop();
          _currentVoiceText = temp;
          speak();
        }
      }
    });

    if (content != null) {
      _currentVoiceText = content;
    }
    _currentVoiceText ??= await getHereFunction();

    EdgeTTSApi.pitch = pitch;
    EdgeTTSApi.rate = rate;
    EdgeTTSApi.volume = volume;

    await player!.setVolume(volume);

    audioToPlay = await EdgeTTSApi.getAudio(_currentVoiceText!);

    await player!.play(BytesSource(audioToPlay!, mimeType: 'audio/mp3'));

    updateTtsState(TtsStateEnum.playing);
    _preloadNextAudio();
  }

  @override
  Future<dynamic> stop() async {
    await player?.stop();
    player?.dispose();
    player = null;
    _nextAudio = null;
    _nextVoiceText = null;
    _isLoadingNextAudio = false;
    _currentVoiceText = null;
    updateTtsState(TtsStateEnum.stopped);
    return 1;
  }

  @override
  Future<void> pause() async {
    await player?.pause();
    updateTtsState(TtsStateEnum.paused);
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
    await player?.stop();
    player?.dispose();
    player = null;
    _nextAudio = null;
    _nextVoiceText = null;
    _isLoadingNextAudio = false;
    _currentVoiceText = null;
    isInit = false;
  }
}
