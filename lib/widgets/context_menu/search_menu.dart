import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/search/search_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class SearchMenu extends StatefulWidget {
  const SearchMenu({
    super.key,
    required this.query,
    required this.decoration,
    required this.axis,
  });

  final String query;
  final BoxDecoration decoration;
  final Axis axis;

  @override
  State<SearchMenu> createState() => _SearchMenuState();
}

class _SearchMenuState extends State<SearchMenu> {
  late final String _url;
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    final engine = Prefs().selectedSearchEngine;
    _url = engine.buildUrl(widget.query);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Container(
          height: widget.axis == Axis.vertical ? double.infinity : 350,
          width: widget.axis == Axis.vertical ? 300 : double.infinity,
          decoration: widget.decoration,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${L10n.of(context).contextMenuSearch}: ${widget.query}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: () {
                      _webViewController?.loadUrl(
                        urlRequest: URLRequest(url: WebUri(_url)),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(_url)),
                    initialSettings: InAppWebViewSettings(
                      isInspectable: kDebugMode,
                      mediaPlaybackRequiresUserGesture: false,
                      allowsInlineMediaPlayback: true,
                    ),
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
