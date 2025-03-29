import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'webview_status.g.dart';

@riverpod
class WebviewStatus extends _$WebviewStatus {
  @override
  bool build() => false;

  void show() {
    state = true;
  }

  void hide() {
    state = false;
  }
}
