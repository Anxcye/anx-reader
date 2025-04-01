import 'dart:async';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/service/edge_tts.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audio_session/audio_session.dart';

enum TtsStateEnum { playing, stopped, paused, continued }

class Tts extends BaseAudioHandler with QueueHandler, SeekHandler {
  static String? language;
  static String? engine;

  static bool isInit = false;

  static double get volume => Prefs().ttsVolume;

  static double get pitch => Prefs().ttsPitch;

  static double get rate => Prefs().ttsRate;
  static AudioPlayer? player;
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
  static String? _nextVoiceText;
  static Uint8List? _nextAudio;
  static bool _isLoadingNextAudio = false;

  static bool get isPlaying => ttsStateNotifier.value == TtsStateEnum.playing;

  static Function getNextVoiceText = () => '';

  static Function getPrevVoiceText = () => '';

  static Function getHere = () => '';

  static Uint8List? audioToPlay;
  static Future<void> init(Function here, Function next, Function prev) async {
    if (isInit) return;
    getHere = here;
    isInit = true;
    getNextVoiceText = next;
    getPrevVoiceText = prev;
  }

  static Future<void> _preloadNextAudio() async {
    if (_isLoadingNextAudio) return;

    _isLoadingNextAudio = true;
    try {
      String prepareText = await epubPlayerKey.currentState!.ttsPrepare();
      if (prepareText.isNotEmpty) {
        _nextVoiceText = prepareText;
        _nextAudio = await EdgeTTS.getAudio(_nextVoiceText!);
      }
    } finally {
      _isLoadingNextAudio = false;
    }
  }

  static Future<void> speak({String? content}) async {
    player ??= AudioPlayer();
    player!.onPlayerComplete.listen((_) async {
      getNextVoiceText();

      if (ttsStateNotifier.value == TtsStateEnum.playing) {
        while (_nextVoiceText == null || _nextAudio == null) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        _currentVoiceText = _nextVoiceText;
        _nextVoiceText = null;
        audioToPlay = _nextAudio;
        _nextAudio = null;

        player!.play(BytesSource(audioToPlay!, mimeType: 'audio/mp3'));

        _preloadNextAudio();
      } else {
        _currentVoiceText = await getNextVoiceText();
        speak();
      }
    });

    if (content != null) {
      _currentVoiceText = content;
    }
    _currentVoiceText ??= await getHere();

    EdgeTTS.pitch = pitch;
    EdgeTTS.rate = rate;
    EdgeTTS.volume = volume;

    player!.setVolume(volume);

    audioToPlay = await EdgeTTS.getAudio(_currentVoiceText!);

    player!.play(BytesSource(audioToPlay!, mimeType: 'audio/mp3'));

    _preloadNextAudio();
  }

  static Future<void> stopStatic() async {
    await player?.stop();
    player?.dispose();
    player = null;
    _nextAudio = null;
    _nextVoiceText = null;
    _isLoadingNextAudio = false;
  }

  static void pauseStatic() async {
    await player?.pause();
  }

  static void prev() async {
    stopStatic();
    _currentVoiceText = await getPrevVoiceText();
    speak();
  }

  static void next() async {
    stopStatic();
    _currentVoiceText = await getNextVoiceText();
    speak();
  }

  static Future<void> restart() async {
    await stopStatic();
    speak();
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
    _nextVoiceText = null;
    _nextAudio = null;
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

    pauseStatic();
    updateTtsState(TtsStateEnum.paused);
  }

  @override
  Future<void> play() async {
    final session = await AudioSession.instance;
    if (await session.setActive(true)) {
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

    if (ttsStateNotifier.value == TtsStateEnum.paused) {
      await player?.resume();
    } else {
      await speak();
    }

    updateTtsState(TtsStateEnum.playing);
  }

  Tts() {
    _initTts();
  }

  Future<void> _initTts() async {
    final session = await AudioSession.instance;
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        // if (isPlaying) {
        //   pause();
        // }
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
