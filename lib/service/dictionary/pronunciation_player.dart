import 'package:anx_reader/service/tts/system_tts.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:audioplayers/audioplayers.dart';

class PronunciationPlayer {
  PronunciationPlayer._internal();

  static final PronunciationPlayer _instance = PronunciationPlayer._internal();

  factory PronunciationPlayer() => _instance;

  AudioPlayer? _player;

  Future<void> play({
    required String text,
    String? audioUrl,
  }) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      throw ArgumentError('text must not be empty');
    }

    await _stopTtsFallback();

    final normalizedAudioUrl = audioUrl?.trim();
    if (normalizedAudioUrl != null && normalizedAudioUrl.isNotEmpty) {
      try {
        final player = await _ensurePlayer();
        await player.stop();
        await player.play(UrlSource(normalizedAudioUrl));
        return;
      } catch (e) {
        AnxLog.warning(
          'Pronunciation audio playback failed for "$normalizedText": $e',
        );
      }
    }

    await _stopAudioPlayer();
    await SystemTts().speak(content: normalizedText);
  }

  Future<AudioPlayer> _ensurePlayer() async {
    final existingPlayer = _player;
    if (existingPlayer != null) {
      return existingPlayer;
    }

    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setPlayerMode(PlayerMode.mediaPlayer);
    _player = player;
    return player;
  }

  Future<void> _stopAudioPlayer() async {
    try {
      await _player?.stop();
    } catch (e) {
      AnxLog.warning('Failed to stop pronunciation audio player: $e');
    }
  }

  Future<void> _stopTtsFallback() async {
    try {
      await SystemTts().stop();
    } catch (e) {
      AnxLog.warning('Failed to stop pronunciation TTS fallback: $e');
    }
  }
}
