// import 'dart:async';
// import 'package:audio_service/audio_service.dart';
// import 'package:flutter/material.dart';
// import 'package:anx_reader/service/tts/base_tts.dart';
// import 'package:anx_reader/service/tts/tts_factory.dart';
// import 'package:anx_reader/service/tts/tts_handler.dart';

// export 'package:anx_reader/service/tts/base_tts.dart';
// export 'package:anx_reader/service/tts/tts_factory.dart';
// export 'package:anx_reader/service/tts/tts_handler.dart';

// class Tts extends BaseAudioHandler with QueueHandler, SeekHandler {
//   static TtsHandler? _ttsHandler;

//   static TtsHandler get _handler {
//     _ttsHandler ??= TtsHandler();
//     return _ttsHandler!;
//   }

//   static double get volume => _handler.volume;
//   static double get pitch => _handler.pitch;
//   static double get rate => _handler.rate;

//   static set volume(double volume) => _handler.volume = volume;
//   static set pitch(double pitch) => _handler.pitch = pitch;
//   static set rate(double rate) => _handler.rate = rate;

//   static ValueNotifier<TtsStateEnum> get ttsStateNotifier =>
//       _handler.ttsStateNotifier;

//   static bool get isPlaying => _handler.isPlaying;

//   static Future<void> init(Function here, Function next, Function prev) async {
//     await _handler.init(here, next, prev);
//   }

//   static Future<void> speak({String? content}) async {
//     await _handler.tts.speak(content: content);
//   }

//   static Future<void> stopStatic() async {
//     await _handler.stop();
//   }

//   static void pauseStatic() async {
//     await _handler.pause();
//   }

//   static void prev() async {
//     await _handler.playPrevious();
//   }

//   static void next() async {
//     await _handler.playNext();
//   }

//   static Future<void> restart() async {
//     await _handler.tts.restart();
//   }

//   @override
//   Future<void> stop() async {
//     await _handler.stop();
//   }

//   @override
//   Future<void> pause() async {
//     await _handler.pause();
//   }

//   @override
//   Future<void> play() async {
//     await _handler.play();
//   }

//   Tts() {}
// }

// Future<AudioHandler> initTtsService() async {
//   return await AudioService.init(
//     builder: () => TtsHandler(),
//     config: const AudioServiceConfig(
//       androidNotificationChannelId: 'com.anx.reader.tts.channel.audio',
//       androidNotificationChannelName: 'ANX Reader TTS',
//       androidNotificationOngoing: true,
//       androidStopForegroundOnPause: true,
//     ),
//   );
// }

// TtsFactory getTtsFactory() {
//   return TtsFactory();
// }

// bool isTtsPlaying(BuildContext context) {
//   return getTtsFactory().ttsStateNotifier.value == TtsStateEnum.playing;
// }

// ValueNotifier<TtsStateEnum> getTtsStateNotifier() {
//   return getTtsFactory().ttsStateNotifier;
// }
