import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

const String baseUrl =
    "speech.platform.bing.com/consumer/speech/synthesize/readaloud";
const String trustedClientToken = "6A5AA1D4EAFF4E9FB37E23D68491D6F4";
const String wssUrl =
    "wss://$baseUrl/edge/v1?TrustedClientToken=$trustedClientToken";
const String voiceListUrl =
    "https://$baseUrl/voices/list?trustedclienttoken=$trustedClientToken";
const String chromiumFullVersion = "130.0.2849.68";
const String secMsGecVersion = "1-$chromiumFullVersion";

class EdgeTTSApi {
  static String text = "";
  static String voice = Prefs().ttsVoiceModel;
  static double rate = 0;
  static double volume = 0;
  static double pitch = 0;

// Constants

// Headers for requests
  static Map<String, String> wssHeaders = {
    "Pragma": "no-cache",
    "Cache-Control": "no-cache",
    "Origin": "chrome-extension://jdiccldimpdaibmpdkjnbmckianbfold",
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36 Edg/130.0.0.0",
    "Accept-Encoding": "gzip, deflate, br",
    "Accept-Language": "en-US,en;q=0.9",
  };

// DRM mechanism to generate security token
  static String generateSecMsGec() {
    // Windows epoch (January 1st, 1601) in seconds since Unix epoch
    const int winEpoch = 11644473600;
    const double sToNs = 1e9;

    // Get current time and adjust to Windows file time format
    double ticks = DateTime.now().millisecondsSinceEpoch / 1000.0;
    ticks += winEpoch;

    // Round down to nearest 5 minutes (300 seconds)
    ticks -= ticks % 300;

    // Convert to Windows file time format (100-nanosecond intervals)
    ticks *= sToNs / 100;

    // Create string to hash
    String strToHash = "${ticks.toInt()}$trustedClientToken";

    // Return SHA256 hash in uppercase hex
    return sha256.convert(ascii.encode(strToHash)).toString().toUpperCase();
  }

  static Future<List<Map<String, dynamic>>> listVoices({String? proxy}) async {
    var response = await http.get(Uri.parse(voiceListUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load voices: ${response.statusCode}');
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  static String generateConnectId() {
    return const Uuid().v4().replaceAll("-", "");
  }

  static String escapeXml(String text) {
    return text
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll("\"", "&quot;")
        .replaceAll("'", "&apos;");
  }

  static Map<String, String> getHeadersFromBinaryData(
      Uint8List data, int headerLength) {
    String headerStr = utf8.decode(data.sublist(0, headerLength));
    Map<String, String> headers = {};

    for (String line in headerStr.split('\r\n')) {
      if (line.contains(':')) {
        List<String> parts = line.split(':');
        if (parts.length > 2) {
          parts = [parts[0], parts.sublist(1).join(':')];
        }
        headers[parts[0]] = parts[1];
      }
    }

    return headers;
  }

  static String createSsml() {
    String escapedText = escapeXml(text);
    int pitchValue = ((pitch - 1) * 100).toInt();
    int rateValue = (rate * 100).toInt();
    int volumeValue = (volume * 100).toInt();

    String pitchStr =
        pitchValue > 0 ? '+${pitchValue}Hz' : '-${pitchValue.abs()}Hz';

    return """
<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='en-US'>
<voice name='$voice'>
<prosody pitch='$pitchStr' rate='+$rateValue%' volume='+$volumeValue%'>
$escapedText
</prosody>
</voice>
</speak>""";
  }

  static Stream<Map<String, dynamic>> stream() async* {
    String connectId = generateConnectId();
    String ssml = createSsml();

    // Prepare request payload
    String configRequest = """
X-Timestamp:2023-10-29T12:00:00.000Z\r
Content-Type:application/json; charset=utf-8\r
Path:speech.config\r
\r
{"context":{"synthesis":{"audio":{"metadataoptions":{"sentenceBoundaryEnabled":"false","wordBoundaryEnabled":"true"},"outputFormat":"audio-24khz-48kbitrate-mono-mp3"}}}}
""";

    String ssmlRequest = """
X-RequestId:$connectId\r
Content-Type:application/ssml+xml\r
X-Timestamp:2023-10-29T12:00:00.000Z\r
Path:ssml\r
\r
$ssml
""";

    // Connect to the service with required security tokens
    final uri = Uri.parse("$wssUrl&Sec-MS-GEC=${generateSecMsGec()}"
        "&Sec-MS-GEC-Version=$secMsGecVersion"
        "&ConnectionId=$connectId");

    final channel = IOWebSocketChannel.connect(
      uri,
      headers: wssHeaders,
    );

    // Send configuration request
    channel.sink.add(configRequest);

    // Send SSML request
    channel.sink.add(ssmlRequest);

    bool audioReceived = false;

    await for (dynamic message in channel.stream) {
      if (message is String) {
        // Process metadata
        Uint8List encodedData = utf8.encode(message);
        int headerEnd = utf8.decode(encodedData).indexOf('\r\n\r\n');
        Map<String, String> parameters =
            getHeadersFromBinaryData(encodedData, headerEnd);
        String path = parameters['Path'] ?? '';
        if (path == 'turn.end') {
          break;
        }
      } else if (message is List<int>) {
        // Process audio data
        Uint8List binaryData = Uint8List.fromList(message);

        if (binaryData.length < 2) continue;

        int headerLength = binaryData[0] << 8 | binaryData[1];
        Map<String, String> parameters = getHeadersFromBinaryData(
            binaryData.sublist(2, headerLength + 2), headerLength);

        Uint8List audioData = binaryData.sublist(headerLength + 2);

        if (parameters['Path'] == 'audio' &&
            parameters['Content-Type'] == 'audio/mpeg') {
          audioReceived = true;
          yield {'type': 'audio', 'data': audioData};
        }
      }
    }

    channel.sink.close();

    if (!audioReceived) {
      throw Exception('No audio received. Please check your parameters.');
    }
  }

  static Future<void> saveToFile(String filename) async {
    final file = File(filename);
    final sink = file.openWrite();

    try {
      await for (final chunk in stream()) {
        if (chunk['type'] == 'audio') {
          sink.add(chunk['data'] as List<int>);
        }
      }
    } finally {
      await sink.close();
    }
  }

  static Future<Uint8List> getAudio(String text) async {
    debugPrint(text);
    EdgeTTSApi.voice = Prefs().ttsVoiceModel;
    EdgeTTSApi.text = text;
    List<int> audioData = [];

    int maxRetries = 10;
    int currentRetry = 1;

    while (currentRetry < maxRetries) {
      try {
        await for (final chunk in stream()) {
          if (chunk['type'] == 'audio') {
            audioData.addAll(chunk['data'] as List<int>);
          }
        }
        // If we get here, the request was successful
        return Uint8List.fromList(audioData);
      } catch (e) {
        if (e.toString().contains(
            "No audio received. Please check your parameters.")) {
          return Uint8List.fromList([]);
        }
        currentRetry++;
        AnxLog.warning('Error on attempt $currentRetry/$maxRetries: $e');
        if (currentRetry >= maxRetries) {
          rethrow;
        }
        // Wait before retrying, with exponential backoff
        await Future.delayed(
            Duration(milliseconds: currentRetry * currentRetry * 50));
      }
    }

    return Uint8List.fromList(audioData);
  }
}
