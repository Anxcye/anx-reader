import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';

class AnxHttpProxyOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) {
      final host = uri.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
        return 'DIRECT';
      }

      if (!Prefs().httpProxyEnabled) {
        return 'DIRECT';
      }

      final proxyHost = Prefs().httpProxyHost.trim();
      final proxyPort = Prefs().httpProxyPort;
      if (proxyHost.isEmpty || proxyPort <= 0) {
        return 'DIRECT';
      }

      return 'PROXY $proxyHost:$proxyPort; DIRECT';
    };

    // Opt-in: trust user-installed / custom CAs and self-signed certs.
    // Dart's BoringSSL store ignores Android user CA store (#719); default
    // remains strict verification when this pref is off.
    if (Prefs().trustUserCertificates) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    }
    return client;
  }

  static Future<bool> testProxy(String host, int port, String testUrl) async {
    try {
      final uri = Uri.parse(testUrl);
      final client = HttpClient();
      client.findProxy = (_) => 'PROXY $host:$port; DIRECT';
      client.connectionTimeout = const Duration(seconds: 8);

      final request = await client.getUrl(uri).timeout(
            const Duration(seconds: 8),
          );
      final response = await request.close().timeout(
            const Duration(seconds: 8),
          );
      await response.drain<void>();
      client.close();
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }
}
