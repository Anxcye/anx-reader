# Anx Reader local patch of webview_cef 0.5.1

- Declares **linux only** in `pubspec.yaml` plugin platforms so Windows/macOS
  builds do not link or register CEF (those platforms use flutter_inappwebview).
- Upstream package also ships windows/macos trees; those were removed from this
  vendored copy to make the Linux-only intent obvious and avoid accidental
  registration if platforms are edited later.
- CEF binaries under `third/cef/` are downloaded at CMake configure time
  (gitignored). Symlink or run the plugin's download.cmake during Linux build.
