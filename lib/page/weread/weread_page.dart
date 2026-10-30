import 'dart:async';
import 'dart:collection';

import 'package:anx_reader/page/weread/weread_injection.dart';
import 'package:anx_reader/utils/platform_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

/// 微信读书网页版增强阅读页。
///
/// 复用 anx-reader 已有的 flutter_inappwebview（Windows 上为 WebView2 后端），
/// 加载 weread.qq.com 并注入 CSS/JS，提供：
/// - 左右边缘点击翻页、空格翻页；
/// - 沉浸模式（隐藏 AppBar + 网页顶栏/工具栏）；
/// - 登录态由 WebView 的 cookie 持久化，无需重复扫码。
class WeReadPage extends StatefulWidget {
  const WeReadPage({super.key, this.initialUrl = 'https://weread.qq.com/'});

  final String initialUrl;

  @override
  State<WeReadPage> createState() => _WeReadPageState();
}

class _WeReadPageState extends State<WeReadPage> {
  InAppWebViewController? _controller;
  late final WebUri _homeUri = WebUri(widget.initialUrl);

  double _progress = 0;
  bool _immersive = false;
  String? _errorMessage;

  /// 桌面端伪装成普通 Chrome，避免被网页判定为嵌入式浏览器。
  String? get _userAgent {
    if (AnxPlatform.isWindows) {
      return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
          'AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/126.0.0.0 Safari/537.36';
    }
    if (AnxPlatform.isMacOS) {
      return 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
          'AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/126.0.0.0 Safari/537.36';
    }
    return null;
  }

  InAppWebViewSettings get _settings => InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        supportZoom: false,
        useShouldOverrideUrlLoading: true,
        isInspectable: kDebugMode,
        userAgent: _userAgent,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Linux 桌面走 vendored webview_cef，未接入本页的注入逻辑，先做降级提示。
    if (AnxPlatform.isLinux) {
      return Scaffold(
        appBar: AppBar(title: const Text('微信读书')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '微信读书增强阅读暂未适配 Linux 桌面端。\n'
              '可以先用系统浏览器打开 weread.qq.com，或使用 Windows / 移动端。',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _immersive
          ? null
          : AppBar(
              titleSpacing: 0,
              title: const Row(
                children: [
                  Icon(Icons.menu_book_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('微信读书'),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: '沉浸模式',
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () => _setImmersive(true),
                ),
                IconButton(
                  tooltip: '回到首页',
                  icon: const Icon(Icons.home_outlined),
                  onPressed: _goHome,
                ),
                IconButton(
                  tooltip: '刷新',
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _controller?.reload(),
                ),
              ],
            ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (_immersive) {
            await _setImmersive(false);
            return;
          }
          final controller = _controller;
          if (controller != null && await controller.canGoBack()) {
            await controller.goBack();
            return;
          }
          if (mounted) Navigator.of(context).pop();
        },
        child: Stack(
          children: [
            Positioned.fill(child: _buildWebView()),
            if (_errorMessage != null) Positioned.fill(child: _buildError()),
            if (_progress > 0 && _progress < 1 && _errorMessage == null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 2,
                ),
              ),
            if (_immersive)
              Positioned(
                top: 12,
                right: 12,
                child: _ImmersiveExitButton(
                  onPressed: () => _setImmersive(false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: _homeUri),
      initialSettings: _settings,
      initialUserScripts: UnmodifiableListView<UserScript>([
        UserScript(
          source: WeReadInjection.js(),
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
          forMainFrameOnly: true,
        ),
      ]),
      onWebViewCreated: (controller) => _controller = controller,
      onLoadStart: (controller, url) {
        if (mounted) {
          setState(() {
            _progress = 0;
            _errorMessage = null;
          });
        }
      },
      onProgressChanged: (controller, progress) {
        if (!mounted) return;
        setState(() => _progress = progress / 100);
      },
      onLoadStop: (controller, url) async {
        if (!mounted) return;
        setState(() => _progress = 1);
        await _inject(controller);
        // 微信读书是 SPA，路由切换后 DOM 会重建，稍后再补一次注入
        Future.delayed(const Duration(milliseconds: 1200), () async {
          if (mounted) await _inject(controller);
        });
      },
      onReceivedError: (controller, request, error) {
        if (!mounted) return;
        if (!request.isForMainFrame!) return;
        setState(() => _errorMessage = error.description);
      },
      shouldOverrideUrlLoading: (controller, navigationAction) async {
        final uri = navigationAction.request.url;
        if (uri == null) return NavigationActionPolicy.ALLOW;
        final host = uri.host;
        if (host.isEmpty || host.endsWith('weread.qq.com') ||
            host.endsWith('qq.com')) {
          return NavigationActionPolicy.ALLOW;
        }
        // 站外链接交给系统浏览器
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        return NavigationActionPolicy.CANCEL;
      },
    );
  }

  Widget _buildError() {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48),
            const SizedBox(height: 12),
            Text('页面加载失败：$_errorMessage',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() => _errorMessage = null);
                _controller?.reload();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _inject(InAppWebViewController controller) async {
    try {
      await controller.evaluateJavascript(source: WeReadInjection.js());
      if (_immersive) {
        await controller.evaluateJavascript(
          source: "document.documentElement.classList.add('anx-immersive');",
        );
      }
    } catch (e) {
      debugPrint('[anx-weread] inject failed: $e');
    }
  }

  Future<void> _setImmersive(bool value) async {
    if (!mounted) return;
    setState(() => _immersive = value);
    try {
      await _controller?.evaluateJavascript(
        source: "document.documentElement.classList.toggle('anx-immersive', $value);",
      );
    } catch (e) {
      debugPrint('[anx-weread] toggle immersive failed: $e');
    }
  }

  void _goHome() {
    _controller?.loadUrl(urlRequest: URLRequest(url: _homeUri));
  }
}

class _ImmersiveExitButton extends StatelessWidget {
  const _ImmersiveExitButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.35,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: '退出沉浸模式',
          icon: const Icon(Icons.fullscreen_exit, size: 20),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
