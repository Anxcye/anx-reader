import 'dart:async';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/service/tts/base_tts.dart';
import 'package:anx_reader/service/tts/tts_service.dart';
import 'package:anx_reader/service/tts/tts_service_provider.dart';
import 'package:anx_reader/service/tts/models/tts_segment.dart';
import 'package:anx_reader/service/tts/models/tts_sentence.dart';
import 'package:anx_reader/service/tts/models/tts_voice.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class OnlineTts extends BaseTts {
  static final OnlineTts _instance = OnlineTts._internal();

  factory OnlineTts() {
    return _instance;
  }

  OnlineTts._internal();

  // ============ Configuration ============
  static const int _bufferCapacity = 10;
  static const int _batchSize = 5; // Max concurrent fetches
  static const int _fetchTimeoutSeconds = 10;
  static const int _maxRetries = 2;

  // ============ Audio Player ============
  AudioPlayer? _player;
  StreamSubscription<void>? _playerCompleteSubscription;

  // ============ Ordered Buffer ============
  // Segments are added in order; audio is fetched in background
  final List<TtsSegment> _buffer = [];
  final Set<String> _bufferKeys = {};
  TtsSegment? _currentSegment;
  String? _currentVoiceText;
  int _audioFetchVersion = 0; // Version counter for audio fetches
  // ============ Prefetcher State ============
  bool _isPrefetcherRunning = false;
  Completer<void>? _prefetcherCompleter;

  // ============ Player State ============
  bool _isPlayerRunning = false;
  Completer<void>? _playerCompleter;
  Completer<void>? _playbackCompleter;

  // ============ Lifecycle ============
  late Function getHereFunction;
  late Function getNextTextFunction;
  late Function getPrevTextFunction;
  bool isInit = false;
  bool _shouldStop = false;

  // ============ Backend ============
  TtsServiceProvider? _currentBackend;

  TtsServiceProvider get backend {
    TtsService service = getTtsService(Prefs().ttsService);
    if (_currentBackend?.service != service) {
      _currentBackend = service.provider;
    }
    return _currentBackend!;
  }

  // ============ TtsStateNotifier ============
  @override
  final ValueNotifier<TtsStateEnum> ttsStateNotifier =
      ValueNotifier<TtsStateEnum>(TtsStateEnum.stopped);

  @override
  void updateTtsState(TtsStateEnum newState) {
    ttsStateNotifier.value = newState;
  }

  // ============ Properties ============
  @override
  double get volume => Prefs().ttsVolume;

  @override
  set volume(double volume) {
    Prefs().ttsVolume = volume;
    _player?.setVolume(volume);
  }

  @override
  double get pitch => Prefs().ttsPitch;

  @override
  set pitch(double pitch) {
    Prefs().ttsPitch = pitch;
    // Clear pending audio so it will be re-fetched with new pitch
    _clearPendingAudio();
  }

  @override
  set rate(double rate) {
    Prefs().ttsRate = rate;
    // Clear pending audio so it will be re-fetched with new rate
    _clearPendingAudio();
  }
  @override
  double get rate => Prefs().ttsRate;

  @override

  @override
  bool get isPlaying => ttsStateNotifier.value == TtsStateEnum.playing;

  @override
  String? get currentVoiceText => _currentVoiceText;

  @override
  Future<List<TtsVoice>> getVoices() async {
    return await backend.getVoices();
  }

  // ============ Initialization ============
  @override
  Future<void> init(Function getCurrentText, Function getNextText,
      Function getPrevText) async {
    getHereFunction = getCurrentText;
    getNextTextFunction = getNextText;
    getPrevTextFunction = getPrevText;
    isInit = true;
  }

  // ============ Audio Player Management ============
  Future<AudioPlayer> _ensurePlayer() async {
    if (_player != null) return _player!;

    _player = AudioPlayer();
    await _player!.setReleaseMode(ReleaseMode.stop);
    await _player!.setPlayerMode(PlayerMode.mediaPlayer);
    await _player!.setVolume(volume);

    _playerCompleteSubscription = _player!.onPlayerComplete.listen((_) {
      _playbackCompleter?.complete();
    });

    return _player!;
  }

  Future<void> _disposePlayer() async {
    await _player?.stop();
    await _playerCompleteSubscription?.cancel();
    _playerCompleteSubscription = null;
    await _player?.dispose();
    _player = null;
  }

  // ============ Buffer Management ============
  String _segmentKey(TtsSentence sentence) {
    if (sentence.cfi != null && sentence.cfi!.isNotEmpty) {
      return sentence.cfi!;
    }
    return '${sentence.text.hashCode}';
  }

  void _resetBuffer() {
    _buffer.clear();
    _bufferKeys.clear();
    _currentSegment = null;
    _currentVoiceText = null;
  }

  /// Clear audio for all pending segments (not currently playing)
  /// so they will be re-fetched with new settings
  void _clearPendingAudio() {
    _audioFetchVersion++; // Increment version to invalidate in-flight fetches
    for (final segment in _buffer) {
      // Clear audio so it will be re-fetched
      segment.audio = null;
      segment.isSilent = false;
      segment.fetchVersion = _audioFetchVersion; // Mark with current version
    }
    AnxLog.info('Cleared pending audio buffer - will re-fetch with new settings (version: $_audioFetchVersion)');
  }

  // ============ Producer: Prefetcher Loop ============
  Future<void> _startPrefetcher() async {
    if (_isPrefetcherRunning) return;
    _isPrefetcherRunning = true;
    _prefetcherCompleter = Completer<void>();

    try {
      while (!_shouldStop) {
        // Check for segments that need audio re-fetch (after settings change)
        final segmentsNeedingAudio = _buffer
            .where((s) => !s.isReady && !s.isSilent)
            .toList();
        
        if (segmentsNeedingAudio.isNotEmpty) {
          // Re-fetch audio for segments that were cleared
          for (var i = 0; i < segmentsNeedingAudio.length; i += _batchSize) {
            if (_shouldStop) break;
            final batch = segmentsNeedingAudio.skip(i).take(_batchSize).toList();
            final futures = batch.map((segment) => _fetchAudioForSegment(segment));
            await Future.wait(futures);
          }
        }

        final neededCount = _bufferCapacity - _buffer.length;

        if (neededCount <= 0) {
          await Future.delayed(const Duration(milliseconds: 50));
          continue;
        }

        // Collect sentences from the reader
        final sentences = await _collectSentences(neededCount);

        if (sentences.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 100));
          continue;
        }

        // Create placeholder segments in ORDER first
        final newSegments = <TtsSegment>[];
        for (final sentence in sentences) {
          if (_shouldStop) break;
          final key = _segmentKey(sentence);
          if (_bufferKeys.contains(key)) continue;

          _bufferKeys.add(key);
          final segment = TtsSegment(sentence: sentence);
          newSegments.add(segment);
          _buffer.add(segment); // Add in order!
        }

        // Now fetch audio in batches to limit concurrency
        for (var i = 0; i < newSegments.length; i += _batchSize) {
          if (_shouldStop) break;
          final batch = newSegments.skip(i).take(_batchSize).toList();
          final futures =
              batch.map((segment) => _fetchAudioForSegment(segment));
          await Future.wait(futures);
        }
      }
    } catch (e) {
      AnxLog.severe('Prefetcher error: $e');
    } finally {
      _isPrefetcherRunning = false;
      _prefetcherCompleter?.complete();
      _prefetcherCompleter = null;
    }
  }

  Future<List<TtsSentence>> _collectSentences(int count) async {
    final state = epubPlayerKey.currentState;
    if (state == null) return [];

    try {
      final sentences = await state.ttsCollectDetails(
        count: count,
        includeCurrent: _buffer.isEmpty && _currentSegment == null,
      );

      // Filter out already buffered sentences
      final newSentences = <TtsSentence>[];
      for (final s in sentences) {
        final key = _segmentKey(s);
        if (!_bufferKeys.contains(key)) {
          newSentences.add(s);
        }
      }

      // Note: We do NOT call getNextTextFunction here.
      // Advancing the reader position should only happen in the player loop
      // after playback completes, to avoid interfering with highlighting.

      return newSentences;
    } catch (e) {
      AnxLog.severe('Collect sentences error: $e');
      return [];
    }
  }

  Future<void> _fetchAudioForSegment(TtsSegment segment) async {
    if (_shouldStop) return;
    if (segment.isReady) return;

    // Capture the version at the start of fetching
    final targetVersion = segment.fetchVersion;

    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      if (_shouldStop) return;
      if (segment.isReady) return;

      try {
        final bytes = await backend
            .speak(
          segment.sentence.text,
          null,
          rate,
          pitch,
        )
            .timeout(Duration(seconds: _fetchTimeoutSeconds));

        // Check if version is still valid (settings haven't changed during fetch)
        if (segment.fetchVersion != targetVersion) {
          AnxLog.info('Audio fetch completed but version changed - discarding (segment version: ${segment.fetchVersion}, target: $targetVersion)');
          return;
        }

        if (bytes.isEmpty) {
          segment.isSilent = true;
        } else {
          segment.audio = bytes;
        }
        return; // Success, exit retry loop
      } on TimeoutException {
        AnxLog.severe(
            'Fetch timeout (attempt ${attempt + 1}/$_maxRetries): "${segment.sentence.text.substring(0, segment.sentence.text.length.clamp(0, 20))}..."');
        if (attempt == _maxRetries) {
          // Check version before marking as silent
          if (segment.fetchVersion == targetVersion) {
            segment.isSilent = true;
          }
        }
      } catch (e) {
        AnxLog.severe('Fetch error (attempt ${attempt + 1}): $e');
        if (attempt == _maxRetries) {
          // Check version before marking as silent
          if (segment.fetchVersion == targetVersion) {
            segment.isSilent = true;
          }
        }
      }
    }
  }

  // ============ Consumer: Player Loop ============
  Future<void> _startPlayer() async {
    if (_isPlayerRunning) return;
    _isPlayerRunning = true;
    _playerCompleter = Completer<void>();

    final audioPlayer = await _ensurePlayer();

    try {
      while (!_shouldStop) {
        // Wait for buffer to have a segment
        while (_buffer.isEmpty && !_shouldStop) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        if (_shouldStop) break;

        // Get the FIRST segment (preserving order)
        final segment = _buffer.first;

        // Wait for this segment's audio to be ready
        while (!segment.isReady && !_shouldStop) {
          await Future.delayed(const Duration(milliseconds: 30));
        }
        if (_shouldStop) break;

        // Now remove it from buffer
        _buffer.removeAt(0);
        _currentSegment = segment;
        _currentVoiceText = segment.sentence.text;

        // Highlight current sentence
        await _highlightSegment(segment);

        // Handle silent segment
        if (segment.isSilent) {
          await Future.delayed(const Duration(milliseconds: 100));
          await getNextTextFunction();
          _currentSegment = null;
          continue;
        }

        // Play audio
        _playbackCompleter = Completer<void>();
        final source = BytesSource(segment.audio!, mimeType: 'audio/mp3');

        try {
          await audioPlayer.play(source);
          await _playbackCompleter!.future;
        } catch (e) {
          AnxLog.severe('Playback error: $e');
        }

        _playbackCompleter = null;
        _currentSegment = null;

        // Advance reader position
        if (!_shouldStop) {
          await getNextTextFunction();
        }
      }
    } catch (e) {
      AnxLog.severe('Player loop error: $e');
    } finally {
      _isPlayerRunning = false;
      _playerCompleter?.complete();
      _playerCompleter = null;
    }
  }

  Future<void> _highlightSegment(TtsSegment segment) async {
    final state = epubPlayerKey.currentState;
    final cfi = segment.sentence.cfi;
    if (state == null || cfi == null || cfi.isEmpty) return;
    try {
      await state.ttsHighlightByCfi(cfi);
    } catch (_) {}
  }

  // ============ Public API ============
  @override
  Future<void> speak({String? content}) async {
    _shouldStop = false;
    updateTtsState(TtsStateEnum.playing);

    // Sync to current location first
    try {
      await getHereFunction();
    } catch (_) {}

    // Start both loops
    unawaited(_startPrefetcher());
    await _startPlayer();
  }

  @override
  Future<void> stop() async {
    _shouldStop = true;
    updateTtsState(TtsStateEnum.stopped);

    // Complete any pending playback
    _playbackCompleter?.complete();

    // Wait for loops to finish
    await _prefetcherCompleter?.future;
    await _playerCompleter?.future;

    // Cleanup
    await _disposePlayer();
    _resetBuffer();
  }

  @override
  Future<void> pause() async {
    await _player?.pause();
    updateTtsState(TtsStateEnum.paused);
  }

  @override
  Future<void> resume() async {
    await _player?.resume();
    updateTtsState(TtsStateEnum.playing);
  }

  @override
  Future<void> prev() async {
    await stop();
    await getPrevTextFunction();
    await speak();
  }

  @override
  Future<void> next() async {
    await stop();
    await getNextTextFunction();
    await speak();
  }

  @override
  Future<void> restart() async {
    await stop();
    await speak();
  }

  /// For testing a specific voice in settings
  Future<void> speakWithVoice(String content, String voice) async {
    await stop();
    final audioPlayer = await _ensurePlayer();

    final bytes = await backend.speak(content, voice, rate, pitch);
    if (bytes.isNotEmpty) {
      final source = BytesSource(bytes, mimeType: 'audio/mp3');
      await audioPlayer.play(source);
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    isInit = false;
  }
}
