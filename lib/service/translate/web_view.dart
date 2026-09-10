import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/service/translate/index.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:url_launcher/url_launcher.dart';

/// Base class for WebView-based translation providers.
abstract class WebViewTranslateProvider extends TranslateServiceProvider {
  /// Constructs the URL for the translation service.
  String getUrl(String text, LangListEnum from, LangListEnum to);

  @override
  Widget translate(
    String text,
    LangListEnum from,
    LangListEnum to, {
    String? contextText,
    bool isFullText = false,
  }) {
    final url = getUrl(text, from, to);
    return SizedBox(
      height: 400,
      child: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(url)),
            initialSettings: InAppWebViewSettings(
              isInspectable: kDebugMode,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              iframeAllowFullscreen: true,
            ),
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
          ),
          Positioned(
            right: 10,
            top: 10,
            child: Builder(
              builder: (context) {
                return Material(
                  color: Theme.of(context).cardColor.withAlpha(200),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.open_in_new, size: 20),
                    onPressed: () {
                      launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Stream<String> translateStream(
    String text,
    LangListEnum from,
    LangListEnum to, {
    String? contextText,
    bool isFullText = false,
  }) async* {
    // WebView providers do not support stream translation
    yield "...";
  }

  @override
  Future<String> translateTextOnly(
    String text,
    LangListEnum from,
    LangListEnum to, {
    String? contextText,
    bool isFullText = false,
  }) async {
    // WebView providers do not support text-only translation
    return "";
  }
}

class BingWebTranslateProvider extends WebViewTranslateProvider {
  @override
  TranslateService get service => TranslateService.bingWeb;

  @override
  String getLabel(BuildContext context) => L10n.of(context).translateBingWeb;

  /// Bing uses 'auto-detect' for auto language detection.
  @override
  String mapLanguageCode(LangListEnum lang) {
    if (lang == LangListEnum.auto) return 'auto-detect';
    return lang.code;
  }

  @override
  String getUrl(String text, LangListEnum from, LangListEnum to) {
    return 'https://www.bing.com/translator?from=${mapLanguageCode(from)}&to=${mapLanguageCode(to)}&text=${Uri.encodeComponent(text)}';
  }
}

class GoogleWebTranslateProvider extends WebViewTranslateProvider {
  @override
  TranslateService get service => TranslateService.googleWeb;

  @override
  String getLabel(BuildContext context) => L10n.of(context).translateGoogleWeb;

  /// Google uses 'auto' for auto language detection.
  @override
  String mapLanguageCode(LangListEnum lang) {
    if (lang == LangListEnum.auto) return 'auto';
    return lang.code;
  }

  @override
  String getUrl(String text, LangListEnum from, LangListEnum to) {
    return 'https://translate.google.com/?sl=${mapLanguageCode(from)}&tl=${mapLanguageCode(to)}&text=${Uri.encodeComponent(text)}&op=translate';
  }
}
