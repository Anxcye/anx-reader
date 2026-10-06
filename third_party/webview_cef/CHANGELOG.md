## 0.5.1
- Docs: fixed a stale version reference in the Chinese README (the upgrade-guide intro still said 0.2.3 instead of 0.5.0). No code changes.

## 0.5.0
- **Upgrading from ≤ 0.2.2?** This release has breaking changes (toolchain, removed API, platform minimums, Windows `initCEFProcesses` signature). See the "Upgrading from ≤ 0.2.2" section in the README.
- Adapted to the latest stable Flutter (tested on 3.44.x).
- Raised minimum supported Flutter to 3.27.0 / Dart 3.6.0.
- Migrated deprecated APIs (`Color.withOpacity` -> `withValues`, `Overlay.of` non-null, generic typedef, `print` -> `debugPrint`, `TextInputClient.onFocusReceived`) and bumped `flutter_lints` to ^5.
- Raised minimum Windows to 10 and minimum macOS deployment target to 12.0 (CEF 149's framework is built for 12.0); refreshed example desktop runner templates.
- Upgraded CEF to 149 (Chromium 149) on all platforms, unified in `third/download.cmake`.
- Windows now consumes the official CEF Standard Distribution and builds `libcef_dll_wrapper` from source (no more custom prebuilt package); plugin builds as C++20 (required by CEF 149).
- macOS now fetches CEF on demand like Windows/Linux instead of committing headers: the podspec `prepare_command` runs `macos/scripts/download_cef.sh`, which downloads the pinned Standard Distribution, builds `libcef_dll_wrapper` from source, lays the framework out as a versioned bundle, and builds the helper executable — all into the git-ignored `macos/third/cef`.
- macOS now runs CEF multi-process (was hardcoded to the unsupported single-process mode). Add `WebviewCEF.install_helper_phase(installer)` to your `macos/Podfile` `post_install` (see README) and the bundled CEF helper sub-process apps are embedded automatically — no Xcode target changes. Falls back to single-process when the hook/helper is absent, so existing integrations keep working.
- macOS now builds for the host architecture only (CEF's prebuilt framework is single-arch): the podspec sets `EXCLUDED_ARCHS[sdk=macosx*]` on the plugin pod and the consuming app target, so `flutter build macos` produces an arm64-only (or x86_64-only) app. Universal (arm64 + x86_64) macOS builds are no longer produced (they would need a lipo'd CEF).
- macOS: full CJK/IME support in the off-screen webview. Text keys are now routed to the OS input method while a web input is focused (previously the global key monitor forwarded raw keys to CEF, so composition never formed); the IME candidate window now tracks the caret (it was pinned to the screen's bottom-left); and IME focus/composing state is tracked per browser, so composing in one webview no longer mis-routes keys in another.
- macOS: fixed keyboard input being completely ignored on Apple Silicon. `encode_flvalue_to_wvalue` detected booleans via `@encode(BOOL)` (which is `"B"` on arm64), so it never matched a boxed Dart bool (`"c"`) and every `true` from Dart decoded as `false` — `setClientFocus(true)` arrived as `focus=0` and the off-screen browser never received `SetFocus(true)`. Bools are now detected with `CFBooleanGetTypeID()` (architecture-independent), and 64-bit ints are read with `longLongValue`.
- macOS: fixed the webview not accepting keyboard input on launch until the window was unfocused and refocused. Under external-begin-frame the initial `SetFocus(true)` could land before the browser was input-ready and be dropped; the requested focus is now re-asserted once on the first produced frame.
- Injected user scripts are now tracked per browser instead of a single plugin-wide value, so each webview applies its own document-start/end scripts (previously the most-recently-created webview's scripts were applied to every instance).
- Windows/example: fixed spawning multiple instances of the host app (and handling CEF's early return on a secondary-process launch); the Windows plugin C-API entry point is now `int initCEFProcesses(HINSTANCE)` returning a sub-process exit code, with the example runner updated to match.
- Fixed CEF API drift: `OnBeforePopup` popup_id, `CefFrame::GetIdentifier()` -> string, and a C++20 `EncodableValue(nullptr)`/variant crash on Windows.
- Fixed a per-event memory leak in the Windows native→Dart message dispatch.
- Fixed command-line switch typos (`no-sanbox` -> `no-sandbox`, stray space in `renderer-process-limit`).
- Removed the unused federated platform-interface scaffolding (`WebviewCefPlatform` / `MethodChannelWebviewCef` / `getPlatformVersion`) and the `plugin_platform_interface` dependency; the public API is `WebviewManager` / `WebViewController`.
- Housekeeping: stopped tracking the downloaded CEF headers in git, added Windows/macOS CI, and cleaned up dead example code.
- Fixed real-time CJK IME composition ("上屏") in the off-screen webview. Windows now uses a native WM_IME pipeline (a window subclass that intercepts WM_IME_* before DefWindowProc and drives CefBrowserHost ImeSetComposition/ImeCommitText on the CEF UI thread), fixing live pinyin preedit and candidate commit. macOS/Linux: the Flutter text-input connection is now shown, the composing caret rect carries a real height, committed/replacement text is delivered, and the composition selection range is corrected.
- Windows: link and bundle the CEF *Release* binaries for every Flutter configuration (including Debug). CEF's Debug binaries enable DCHECKs that crash OSR during IME (NOTIMPLEMENTED GetNativeView), so `flutter run` (Debug) builds previously crashed on CJK input; they now work. Set `WEBVIEW_CEF_USE_DEBUG_CEF=ON` to opt back into the Debug CEF binaries for stepping into CEF itself.
- Windows: zero-copy GPU rendering. The off-screen webview now uses CEF's GPU shared-texture path (`OnAcceleratedPaint`) instead of the software `OnPaint` CPU buffer: each frame's D3D11 shared texture is copied on the GPU into a DXGI-shared bridge texture and handed to Flutter/ANGLE as a GPU surface texture, eliminating the per-frame BGRA→RGBA CPU swizzle and CPU→GPU upload. The GPU is left enabled on Windows for this. Set `WEBVIEW_CEF_GPU_TEXTURE=OFF` to fall back to the software pixel-buffer path. macOS now uses the same accelerated path: CEF's `OnAcceleratedPaint` IOSurface is GPU-blitted (Metal) into a pooled `CVPixelBuffer` and handed to Flutter — no software CPU copy, and no tearing race (CEF's pool surface is copied into a client-owned buffer per its contract, not wrapped). Frame production is driven on the display vblank via a `CVDisplayLink`, so the webview follows the monitor's refresh rate (e.g. 120 Hz ProMotion) and idles when static. While the shared-texture path is active there is no software `OnPaint` fallback, so macOS requires a working GPU compositor; a one-time warning is logged if no GPU frame is produced within a few seconds (the symptom of a headless/VM/software-GL environment). Linux keeps the software path for now.
- Windows: adaptive frame rate. Frame production is driven by external BeginFrame ticked on each display vblank (`IDXGIOutput::WaitForVBlank`), so the webview renders at the monitor's actual refresh rate (e.g. 120/144 Hz) instead of being capped at CEF's 60 fps `windowless_frame_rate` limit. Static content stays idle (frames are only produced on damage).

## 0.2.0
- Linux support!
- Multiple instances support.
- js eval support.

## 0.1.0
- JS bridge support (Thanks to @SinyimZhi)
- Cookie manipulation support (Thanks to @SinyimZhi)
- [Windows] fix compile error after upgrade from a lower version

## 0.0.9

- [Windows] Fixed crash caused by frame buffer lock.
- [Windows] Fixed WebGL support.

## 0.0.8

- Added support to build macOS universal app.
- Refined scrolling for different platform.
- Added search bar features in example project.
- Added title & url change aware in UI.

## 0.0.7

- Basic characters input support.
- Added back, forward, reload APIs.
- Mouse move events support.
- HTML5 drag & drop support.

## 0.0.6

- Fixed macOS compile issue.

## 0.0.5

1. Initial support for macOS.
2. Touchpad support (based on flutter 3.3).
3. Hi-DPI display support.

## 0.0.3

- Fixed compile issue on non-utf8 machines.

## 0.0.1

- Webview CEF plugin for Flutter Desktop.
- Windows support only.
