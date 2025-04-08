import 'dart:async';
import 'package:flutter/material.dart';

enum TtsStateEnum { playing, stopped, paused, continued }

abstract class BaseTts {
  double get volume;
  set volume(double volume);

  double get pitch;
  set pitch(double pitch);

  double get rate;
  set rate(double rate);

  ValueNotifier<TtsStateEnum> get ttsStateNotifier;
  void updateTtsState(TtsStateEnum newState);

  Future<void> init(
      Function getCurrentText, Function getNextText, Function getPrevText);

  Future<void> speak({String? content});

  Future<dynamic> stop();

  Future<void> pause();

  Future<void> resume();

  Future<void> prev();

  Future<void> next();

  Future<void> restart();

  Future<void> dispose();

  bool get isPlaying;

  String? get currentVoiceText;
}
