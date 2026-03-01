import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/tts/models/tts_voice.dart';
import 'package:anx_reader/service/tts/tts_service.dart';
import 'package:anx_reader/service/tts/tts_service_provider.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter/widgets.dart';

class EdgeTtsProvider extends TtsServiceProvider {
  static final EdgeTtsProvider _instance = EdgeTtsProvider._internal();

  factory EdgeTtsProvider() {
    return _instance;
  }

  EdgeTtsProvider._internal();

  static const String _defaultUrl = 'http://localhost:8080';
  static const String _defaultVoice = 'en-US-GuyNeural';

  @override
  TtsService get service => TtsService.edge;

  @override
  String getLabel(BuildContext context) => L10n.of(context).settingsNarrateEdgeTts;

  @override
  List<ConfigItem> getConfigItems(BuildContext context) {
    return [
      ConfigItem(
        key: 'tip',
        label: L10n.of(context).translateTip,
        type: ConfigItemType.tip,
        defaultValue: L10n.of(context).settingsNarrateEdgeHelpText,
        link: 'https://anx.anxcye.com/docs/tts/edge',
      ),
      ConfigItem(
        key: 'url',
        label: 'URL',
        description: L10n.of(context).settingsNarrateEdgeUrlDescription,
        type: ConfigItemType.text,
        defaultValue: _defaultUrl,
      ),
      ConfigItem(
        key: 'voice',
        label: 'Voice',
        description: L10n.of(context).settingsNarrateEdgeVoiceDescription,
        type: ConfigItemType.text,
        defaultValue: _defaultVoice,
      ),
    ];
  }

  @override
  Map<String, dynamic> getConfig() {
    final config = Prefs().getOnlineTtsConfig(serviceId);
    if (config.isEmpty) {
      return {
        'url': _defaultUrl,
        'voice': _defaultVoice,
      };
    }
    return {
      'url': config['url'] ?? _defaultUrl,
      'voice': config['voice'] ?? _defaultVoice,
    };
  }

  @override
  void saveConfig(Map<String, dynamic> config) {
    Prefs().saveOnlineTtsConfig(serviceId, config);
  }

  @override
  Future<Uint8List> speak(String text, String? voice, double rate, double pitch) async {
    final config = getConfig();
    final String url = config['url']?.toString().trim() ?? _defaultUrl;
    final String resolvedVoice = resolveVoice(voice);

    if (url.isEmpty) {
      throw Exception('Edge TTS config missing (url)');
    }

    // Ensure URL ends with /tts/stream
    final String apiUrl = url.endsWith('/tts/stream') ? url : '$url/tts/stream';

    // Create HttpClient with NO PROXY
    final client = HttpClient()
      ..findProxy = (uri) {
        // Return DIRECT to bypass all proxies
        if (uri.host == 'localhost' ||
            uri.host == '127.0.0.1' ||
            uri.host.startsWith('192.168.') ||
            uri.host.startsWith('10.') ||
            uri.host == '::1' ||
            uri.host.toLowerCase().startsWith('fe80:')) {
          return 'DIRECT';
        }
        return HttpClient.findProxyFromEnvironment(uri);
      }
      ..connectionTimeout = const Duration(seconds: 10);

    try {
      // Try minimal request body first (like curl command)
      final requestBody = {
        'text': text,
        'voice': resolvedVoice,
        'rate': _formatRate(rate),
      };

      AnxLog.info('Edge TTS request to: $apiUrl');
      AnxLog.info('Edge TTS request body: ${jsonEncode(requestBody)}');
      AnxLog.info('Edge TTS proxy bypass: DIRECT');

      final uri = Uri.parse(apiUrl);
      final request = await client.postUrl(uri);

      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(requestBody));

      final response = await request.close().timeout(
            const Duration(seconds: 60),
          );

      // Read response body
      final List<int> bodyBytes = [];
      await for (final chunk in response) {
        bodyBytes.addAll(chunk);
      }

      if (response.statusCode == 200) {
        return Uint8List.fromList(bodyBytes);
      }

      // Handle specific error codes
      final errorBody = bodyBytes.isNotEmpty ? utf8.decode(bodyBytes) : 'Empty response';

      if (response.statusCode == 502) {
        throw Exception(
          'Edge TTS server error (502 Bad Gateway).\n\n'
          'This usually means:\n'
          '1. The Edge-TTS server is not running at: $url\n'
          '2. The server URL is incorrect\n'
          '3. There is a proxy/gateway misconfiguration\n\n'
          'Please check:\n'
          '- Is your Edge-TTS server running?\n'
          '- Is the URL correct? Current: $url\n'
          '- Can you access $apiUrl from this device?',
        );
      } else if (response.statusCode == 404) {
        throw Exception(
          'Edge TTS endpoint not found (404).\n\n'
          'Please check:\n'
          '- The server URL is correct\n'
          '- The /tts/stream endpoint is available\n'
          'Current URL: $apiUrl',
        );
      } else if (response.statusCode >= 500) {
        throw Exception(
          'Edge TTS server error (${response.statusCode}): $errorBody\n\n'
          'Server URL: $apiUrl',
        );
      } else {
        throw Exception(
          'Edge TTS failed: ${response.statusCode} $errorBody\n\n'
          'Server URL: $apiUrl',
        );
      }
    } on SocketException catch (e) {
      throw Exception(
        'Edge TTS connection failed (SocketException).\n\n'
        'Error: ${e.message}\n\n'
        'Please check:\n'
        '- Is your Edge-TTS server running at: $url?\n'
        '- Is the server URL correct?\n'
        '- Is there a network connection to the server?\n'
        '- Is a proxy blocking the connection?',
      );
    } on TimeoutException catch (e) {
      throw Exception(
        'Edge TTS connection timed out.\n\n'
        'Error: ${e.message}\n\n'
        'Please check:\n'
        '- Is your Edge-TTS server running at: $url?\n'
        '- Is the network connection stable?',
      );
    } catch (e) {
      throw Exception('Edge TTS error: $e');
    } finally {
      client.close();
    }
  }

  /// Convert rate (0.2 ~ 3.0) to percentage string format
  String _formatRate(double rate) {
    int ratePercent = ((rate - 1.0) * 100).toInt();
    if (ratePercent >= 0) {
      return '+$ratePercent%';
    } else {
      return '$ratePercent%';
    }
  }

  /// Convert pitch (0.5 ~ 2.0) to Hz format
  // String _formatPitch(double pitch) {
  //   int pitchHz = ((pitch - 1.0) * 100).toInt();
  //   if (pitchHz >= 0) {
  //     return '+${pitchHz}Hz';
  //   } else {
  //     return '${pitchHz}Hz';
  //   }
  // }

  @override
  Future<List<TtsVoice>> getVoices() async {
    return const [
      TtsVoice(shortName: 'en-US-GuyNeural', name: 'Guy (US)', locale: 'en-US'),
      TtsVoice(shortName: 'en-US-JennyNeural', name: 'Jenny (US)', locale: 'en-US'),
      TtsVoice(shortName: 'en-GB-RyanNeural', name: 'Ryan (UK)', locale: 'en-GB'),
      TtsVoice(shortName: 'en-GB-SoniaNeural', name: 'Sonia (UK)', locale: 'en-GB'),
      TtsVoice(shortName: 'zh-CN-XiaoxiaoNeural', name: '晓晓 (中文)', locale: 'zh-CN'),
      TtsVoice(shortName: 'zh-CN-YunxiNeural', name: '云希 (中文)', locale: 'zh-CN'),
      TtsVoice(shortName: 'zh-CN-YunjianNeural', name: '云健 (中文)', locale: 'zh-CN'),
      TtsVoice(shortName: 'ja-JP-KeitaNeural', name: 'Keita (Japanese)', locale: 'ja-JP'),
      TtsVoice(shortName: 'ja-JP-NanamiNeural', name: 'Nanami (Japanese)', locale: 'ja-JP'),
      TtsVoice(shortName: 'de-DE-KatjaNeural', name: 'Katja (German)', locale: 'de-DE'),
      TtsVoice(shortName: 'de-DE-ConradNeural', name: 'Conrad (German)', locale: 'de-DE'),
      TtsVoice(shortName: 'fr-FR-DeniseNeural', name: 'Denise (French)', locale: 'fr-FR'),
      TtsVoice(shortName: 'fr-FR-HenriNeural', name: 'Henri (French)', locale: 'fr-FR'),
      TtsVoice(shortName: 'es-ES-ElviraNeural', name: 'Elvira (Spanish)', locale: 'es-ES'),
      TtsVoice(shortName: 'es-ES-AlvaroNeural', name: 'Alvaro (Spanish)', locale: 'es-ES'),
    ];
  }

  @override
  TtsVoice convertVoiceModel(dynamic voiceData) {
    if (voiceData is TtsVoice) return voiceData;
    if (voiceData is Map<String, dynamic>) {
      return TtsVoice.fromMap(voiceData);
    }
    return const TtsVoice(shortName: '', name: '', locale: '');
  }

  @override
  String getSelectedVoice() {
    final config = getConfig();
    final voice = config['voice']?.toString() ?? '';
    if (voice.isNotEmpty) return voice;
    return _defaultVoice;
  }

  @override
  void setSelectedVoice(String voice) {
    final config = getConfig();
    config['voice'] = voice;
    saveConfig(config);
  }
}
