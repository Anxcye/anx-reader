import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/service/tts/base_tts.dart';
import 'package:anx_reader/service/tts/tts_factory.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';

class TtsHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final TtsFactory _ttsFactory = TtsFactory();

  TtsHandler() {
    _initAudioSession();
  }

  BaseTts get tts => _ttsFactory.current;

  Future<void> init(Function getCurrentText, Function getNextText,
      Function getPrevText) async {
    await tts.init(getCurrentText, getNextText, getPrevText);
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;

    final allowMix = Prefs().allowMixWithOtherAudio;

    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: allowMix
          ? AVAudioSessionCategoryOptions.mixWithOthers
          : AVAudioSessionCategoryOptions.none,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
    ));
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        // if (tts.isPlaying) {
        //   pause();
        // }
      } else {
        switch (event.type) {
          case AudioInterruptionType.pause:
          case AudioInterruptionType.duck:
            if (!tts.isPlaying) {
              play();
            }
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });
    session.becomingNoisyEventStream.listen((_) {
      if (tts.isPlaying) pause();
    });
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
    if (tts.ttsStateNotifier.value == TtsStateEnum.paused) {
      tts.updateTtsState(TtsStateEnum.playing);
      await tts.resume();
    } else {
      tts.updateTtsState(TtsStateEnum.playing);
      await tts.speak();
    }
  }

  @override
  Future<void> pause() async {
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.play, MediaControl.stop],
      processingState: AudioProcessingState.ready,
      playing: false,
    ));

    await tts.pause();
    tts.updateTtsState(TtsStateEnum.paused);
  }

  @override
  Future<void> stop() async {
    playbackState.add(playbackState.value.copyWith(
      controls: [],
      processingState: AudioProcessingState.idle,
      playing: false,
    ));

    tts.updateTtsState(TtsStateEnum.stopped);
    await tts.stop();
    epubPlayerKey.currentState?.ttsStop();
  }

  Future<void> playPrevious() async {
    await tts.prev();
  }

  Future<void> playNext() async {
    await tts.next();
  }

  Future<void> switchTtsType(bool useSystemTts) async {
    await _ttsFactory.switchTtsType(useSystemTts);
  }

  ValueNotifier<TtsStateEnum> get ttsStateNotifier => tts.ttsStateNotifier;

  bool get isPlaying => tts.isPlaying;

  set volume(double volume) {
    tts.volume = volume;
  }

  double get volume => tts.volume;

  set pitch(double pitch) {
    tts.pitch = pitch;
  }

  double get pitch => tts.pitch;

  set rate(double rate) {
    tts.rate = rate;
  }

  double get rate => tts.rate;
}
