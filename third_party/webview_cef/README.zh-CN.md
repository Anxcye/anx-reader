# WebView CEF

<a href="https://pub.dev/packages/webview_cef"><img src="https://img.shields.io/pub/likes/webview_cef?logo=dart" alt="Pub.dev likes"/></a> <a href="https://pub.dev/packages/webview_cef" alt="Pub.dev popularity"><img src="https://img.shields.io/pub/popularity/webview_cef?logo=dart"/></a> <a href="https://pub.dev/packages/webview_cef"><img src="https://img.shields.io/pub/points/webview_cef?logo=dart" alt="Pub.dev points"/></a> <a href="https://pub.dev/packages/webview_cef"><img src="https://img.shields.io/pub/v/webview_cef.svg" alt="latest version"/></a> <a href="https://pub.dev/packages/webview_cef"><img src="https://img.shields.io/badge/macOS%20%7C%20Windows%20%7C%20Linux-blue?logo=flutter" alt="Platform"/></a>

[English](README.md) · **简体中文**

基于 [CEF](https://bitbucket.org/chromiumembedded/cef)（Chromium Embedded Framework）的 Flutter **桌面端** WebView。它以离屏方式渲染一个完整的 Chromium 浏览器，并将画面呈现在 Flutter 的 `Texture` 上，因此网页内容能与你的 Flutter UI 在 Windows、macOS、Linux 上原生地合成在一起。

> 基于 **CEF 149（Chromium 149）**。

---

## 特性

- 🌐 **完整 Chromium 引擎** —— 现代 Web 标准、WebGL、HTML5 视频等。
- ⚡ **GPU 零拷贝渲染**（Windows 与 macOS）—— 帧直接从 Chromium 的 GPU 输出经共享纹理交给 Flutter（Windows 用 D3D11 纹理，macOS 用 IOSurface），每帧不再做 CPU 端换色，也不再做 CPU→GPU 上传。Linux 仍走软件路径。
- 🎞️ **自适应帧率**（Windows 与 macOS）—— 由显示器的垂直消隐（vblank）驱动产帧（Windows 用 `IDXGIOutput::WaitForVBlank`，macOS 用 `CVDisplayLink`），因此 webview 跟随显示器真实刷新率（如 120/144Hz），不再被限制在 60fps；静态内容则保持空闲不产帧。
- ⌨️ **中日韩输入法实时上屏** —— 原生输入法合成管线，拼音预编辑实时显示、选词正确上屏。
- 🔌 **JavaScript 桥** —— JS 调用 Dart，Dart 执行 JS。
- 🍪 **Cookie 管理** —— 读取、设置、删除 Cookie。
- 🪟 **多实例** —— 同时运行多个独立 webview。
- 📜 **用户脚本注入** —— 在文档开始/结束时注入 JS/CSS。
- 🛠️ **DevTools**、鼠标与触控板输入、导航以及加载/标题/URL 事件。

## 平台支持

| 平台 | 最低版本 | 架构 |
| --- | --- | --- |
| Windows | Windows 10 | x64 |
| macOS | macOS 12.0 | arm64 或 x86_64（仅本机架构，非 Universal） |
| Linux | — | x64、arm64 |

## 环境要求

- Flutter **>= 3.27.0**、Dart **>= 3.6.0**（已在最新稳定版 Flutter 3.44.x 上测试）。
- 原生侧需要 C++20 工具链（CEF 149 要求）—— 较新的 MSVC / Clang / GCC。

---

## 从 ≤ 0.2.2 升级

0.5.0 是一次大版本升级（Flutter 3.44 + CEF 149），在所有平台上都有破坏性变更。若你从旧版本升级，请按以下步骤操作：

- **工具链** —— 升级到 Flutter **≥ 3.27.0** / Dart **≥ 3.6.0**（原为 2.5.0 / 2.17.1）。原生构建现在需要 **C++20**（CEF 149）；请确保你的工程没有把插件 target 强制设为更低的 C++ 标准。
- **移除的 Dart API** —— `WebviewCefPlatform`、`MethodChannelWebviewCef`、`getPlatformVersion()` 已移除（同时移除了 `plugin_platform_interface` 依赖）。它们本就不是对外 API，且无替代（`getPlatformVersion` 仅返回演示值）。请只 import `package:webview_cef/webview_cef.dart`，使用 `WebviewManager` / `WebViewController`。
- **Windows** —— `initCEFProcesses` 签名变更。请更新 `windows/runner/main.cpp`：它现在接收 `HINSTANCE` 并返回子进程退出码，且必须作为 `wWinMain` 的第一条语句立即返回（见下方 Windows 安装片段）。最低系统现为 **Windows 10**。
- **macOS** —— 把部署目标提升到 **12.0**：在 `macos/Podfile` 设置 `platform :osx, '12.0'`，并在 Xcode 中把 Runner target 的 macOS Deployment Target 也设为 12.0（CEF 149 的 framework 以 12.0 构建）。要启用多进程渲染，请在 `macos/Podfile` 的 `post_install` 中加入一行钩子（见 macOS 安装一节）。构建现在**仅针对本机架构**（arm64 *或* x86_64）—— 不再生成 Universal 包。

---

## 安装

### Windows

1. 添加依赖：

   ```bash
   flutter pub add webview_cef
   ```

2. 修改 `windows/runner/main.cpp`。由于 Chromium 的多进程架构，以及需要把输入/输入法和 method channel 调用路由到 Flutter 引擎线程，需要加两处钩子：

   ```cpp
   #include "webview_cef/webview_cef_plugin_c_api.h"

   int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                         _In_ wchar_t *command_line, _In_ int show_command) {
     // 启动 CEF 子进程，必须放在 wWinMain 最前面。
     int exit_code = initCEFProcesses(instance);
     if (exit_code >= 0) {
       return exit_code;
     }
     // ……原有 runner 初始化……
   ```

   在消息循环里把消息转发给 CEF（启用键盘输入，并让 CEF 能向 Flutter 引擎线程投递消息）：

   ```cpp
   ::MSG msg;
   while (::GetMessage(&msg, nullptr, 0, 0)) {
     ::TranslateMessage(&msg);
     ::DispatchMessage(&msg);
     handleWndProcForCEF(msg.hwnd, msg.message, msg.wParam, msg.lParam);
   }
   ```

   > 输入法由插件自动接管，runner 无需额外代码。

首次构建时会自动从 <https://cef-builds.spotifycdn.com> 下载官方 CEF *Standard Distribution*（约 330MB）到 `third/cef`，并从源码编译 `libcef_dll_wrapper`，因此第一次构建会明显较慢。

### macOS

> **要求 macOS 12.0 及以上** —— CEF 149 的 framework 以 12.0 为部署目标,所以你 App 的 macOS 部署目标必须 **≥ 12.0**(在 `macos/Podfile` 设 `platform :osx, '12.0'`,并同步 Runner target)。更低的版本无法干净链接。

1. 添加依赖：

   ```bash
   flutter pub add webview_cef
   ```

2. 启用多进程(推荐):在 `macos/Podfile` 已有的 `post_install` 里加上 helper 钩子:

   ```ruby
   post_install do |installer|
     installer.pods_project.targets.each do |target|
       flutter_additional_macos_build_settings(target)
     end
     # webview_cef: 嵌入 CEF helper 子进程 app(多进程)。
     require File.expand_path(
       'Flutter/ephemeral/.symlinks/plugins/webview_cef/macos/embed_cef_helpers.rb', __dir__)
     WebviewCEF.install_helper_phase(installer)
   end
   ```

   然后 `pod install`(`flutter run` 会自动跑)。它会装一个 "Embed CEF Helpers" 构建阶段,把预编译的 helper 克隆成 5 个 CEF 子进程 `.app` 嵌进你的 App —— 无需手动加 Xcode target。**不加这个钩子插件也能用,但会回退单进程**(Chromium 不支持的模式:无崩溃隔离、V8 proxy resolver 被禁等)。

macOS 走 CocoaPods，不跑 CMake 的下载流程。改由 podspec 的 `prepare_command` 在 `pod install` 时运行 [`macos/scripts/download_cef.sh`](macos/scripts/download_cef.sh)，逻辑与 Windows/Linux 对齐：下载与本机架构匹配的官方 CEF *Standard Distribution*（来自 <https://cef-builds.spotifycdn.com>，版本由 [`third/download.cmake`](third/download.cmake) 的 `CEF_VERSION` 固定），从源码编译 `libcef_dll_wrapper`，把 framework 整理成 versioned macOS bundle，并安装进（已 git-ignore 的）`macos/third/cef`。所以首次 `pod install` 会明显变慢；之后只要版本未变即为 no-op。

要求：`PATH` 上需有 `cmake`（以及 `ninja`，否则退回 `make`）来编译 wrapper —— `brew install cmake ninja`。

> wrapper 默认编 `Debug`，以匹配 `flutter run` / `flutter build macos --debug`。如需 release 构建，在 `pod install` 前设置 `CEF_WRAPPER_BUILD_TYPE=Release`（debug 与 release 需要对应配置编译的 wrapper —— `#if DCHECK_IS_ON()` 会改变其 ABI）。

> 脚本只为本机架构编译（arm64 **或** x86_64）。如需 Universal（arm64 + x86_64）App，用 `lipo` 合并 wrapper 并使用 universal framework，详见 [#30](/../../issues/30)。**`[征集帮助]`** 更优雅的二进制分发方式。

### Linux

```bash
flutter pub add webview_cef
```

首次构建时自动下载 CEF（支持 x64 与 arm64）。请确保已安装 Flutter Linux 桌面工具链（`clang`、`cmake`、`ninja-build`、`libgtk-3-dev`、`pkg-config`）。

---

## 快速开始

```dart
import 'package:flutter/material.dart';
import 'package:webview_cef/webview_cef.dart';

class MyWebView extends StatefulWidget {
  const MyWebView({super.key});
  @override
  State<MyWebView> createState() => _MyWebViewState();
}

class _MyWebViewState extends State<MyWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebviewManager().createWebView(
      loading: const Center(child: CircularProgressIndicator()),
    );
    _init();
  }

  Future<void> _init() async {
    await WebviewManager().initialize(); // 整个 App 调用一次
    _controller.setWebviewListener(WebviewEventsListener(
      onUrlChanged: (url) => debugPrint('url => $url'),
      onLoadEnd: (controller, url) => debugPrint('loaded => $url'),
    ));
    await _controller.initialize('https://flutter.dev');
  }

  @override
  void dispose() {
    _controller.dispose();
    WebviewManager().quit(); // 仅在整个 App 退出时调用
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _controller,
      builder: (_, ready, __) =>
          ready ? _controller.webviewWidget : _controller.loadingWidget,
    );
  }
}
```

完整示例（地址栏、Cookie、JS 桥、DevTools）见 [`example/`](example/)。

---

## 用法

### 生命周期

```dart
await WebviewManager().initialize(userAgent: 'my-app/1.0'); // 每个 App 一次
final controller = WebviewManager().createWebView(loading: const Text('…'));
await controller.initialize('https://example.com');
// …
controller.dispose();
WebviewManager().quit(); // App 关闭时
```

### 导航

```dart
controller.loadUrl('https://example.com');
controller.reload();
controller.goBack();
controller.goForward();
controller.openDevTools();
```

### 事件

```dart
controller.setWebviewListener(WebviewEventsListener(
  onTitleChanged: (title) {},
  onUrlChanged: (url) {},
  onLoadStart: (controller, url) {},
  onLoadEnd: (controller, url) {},
  onConsoleMessage: (level, message, source, line) {},
));
```

### JavaScript 桥

```dart
// Dart -> JS
controller.executeJavaScript("document.title = 'set from Dart'");
final result = await controller.evaluateJavascript("1 + 1"); // "2"

// JS -> Dart
controller.setJavaScriptChannels({
  JavascriptChannel(
    name: 'Print',
    onMessageReceived: (msg) {
      debugPrint(msg.message);
      controller.sendJavaScriptChannelCallBack(
          false, "{'code':'200'}", msg.callbackId, msg.frameId);
    },
  ),
});
```

### Cookie

```dart
await WebviewManager().setCookie('example.com', 'key', 'value');
await WebviewManager().deleteCookie('example.com', 'key');
final all = await WebviewManager().visitAllCookies();
final some = await WebviewManager().visitUrlCookies('example.com', false);
```

### 用户脚本注入

```dart
final scripts = InjectUserScripts()
  ..add(UserScript("console.log('at document start')", ScriptInjectTime.LOAD_START))
  ..add(UserScript("console.log('at document end')", ScriptInjectTime.LOAD_END));

final controller = WebviewManager().createWebView(injectUserScripts: scripts);
```

---

## Windows 构建选项

以下 CMake 选项可设置在插件目标上（括号内为默认值）：

| 选项 | 默认 | 作用 |
| --- | --- | --- |
| `WEBVIEW_CEF_GPU_TEXTURE` | `ON` | GPU 零拷贝渲染（CEF `OnAcceleratedPaint` → Flutter GPU 纹理）。设为 `OFF` 回退到软件像素缓冲路径。 |
| `WEBVIEW_CEF_USE_DEBUG_CEF` | `OFF` | 即使在 Debug 构建中也链接/打包 CEF 的 **Debug** 二进制。默认情况下 Debug 构建使用 Release 的 CEF 二进制，因为 CEF 的 Debug DCHECK 会在输入法过程中使离屏渲染崩溃。仅当你需要单步调试 CEF 自身时才打开。 |

## 升级 CEF

CEF/Chromium 版本只在一处管理 —— [`third/download.cmake`](third/download.cmake) 里的 `CEF_VERSION`。修改它即可升级三端的 CEF：Windows 与 Linux 自动下载，macOS 也读取同一个 `CEF_VERSION`（通过 podspec `prepare_command` 运行的 [`macos/scripts/download_cef.sh`](macos/scripts/download_cef.sh)），在下次 `pod install` 时重新下载，无需手动放置。唯一的额外步骤是同步 [`.github/workflows/test_macos.yaml`](.github/workflows/test_macos.yaml) 里硬编码的 `CEF_VERSION`。

---

## 演示

<kbd>![demo](https://user-images.githubusercontent.com/7610615/190432410-c53ef1c4-33c2-461b-af29-b0ecab983579.gif)</kbd>

### 截图

| Windows | macOS | Linux |
| --- | --- | --- |
| <img src="https://user-images.githubusercontent.com/7610615/190431027-6824fac1-015d-4091-b034-dd58f79adbcb.png" width="400" /> | <img src="https://user-images.githubusercontent.com/7610615/190911381-db88cf33-70a2-4abc-9916-e563e54eb3f9.png" width="400" /> | <img src ="https://github.com/hlwhl/webview_cef/assets/49640121/50a4c2f6-1f24-4d10-9913-ad274d76cf3f" width="400" /> |
| <img src="https://user-images.githubusercontent.com/7610615/190431037-62ba0ea7-f7d1-4fca-8ce1-596a0a508f93.png" width="400" /> | <img src="https://user-images.githubusercontent.com/7610615/190911410-bd01e912-5482-4f9e-9dae-858874e5aaed.png" width="400" /> | <img src="https://github.com/hlwhl/webview_cef/assets/49640121/10a693d5-4ee0-4389-a1e8-1b0355f7c0a6" width="400" /> |

---

## 路线图

- [x] Windows / macOS / Linux 支持
- [x] 多实例
- [x] JavaScript 桥与 Cookie 管理
- [x] 输入法支持（Windows / macOS / Linux；已用中文输入法测试）
- [x] 鼠标与触控板输入
- [x] DevTools
- [x] GPU 零拷贝渲染与自适应帧率（Windows 与 macOS）
- [x] 更简单的 macOS 多进程 helper bundle 集成（一行 Podfile 钩子）
- [ ] macOS Universal（arm64 + x86_64）构建（需要 lipo 合并的 CEF）
- [ ] Windows 上无撕裂的 GPU 同步（keyed-mutex）

欢迎提交 PR。每个 PR 都会在 Windows、macOS、Linux 上运行构建 + `flutter analyze` CI。

## 致谢

灵感来自 [**`flutter_webview_windows`**](https://github.com/jnschulze/flutter-webview-windows)。

## 许可证

[Apache License 2.0](LICENSE)。
