import 'package:dio/dio.dart';

class AiDio {
  late Dio dio;
  static final AiDio instance = AiDio._();

  static const Duration defaultConnectTimeout = Duration(seconds: 30);
  static const Duration defaultReceiveTimeout = Duration(seconds: 60);
  static const Duration defaultSendTimeout = Duration(seconds: 30);

  AiDio._() {
    _initDio();
  }

  void _initDio() {
    dio = Dio(BaseOptions(
      connectTimeout: defaultConnectTimeout,
      receiveTimeout: defaultReceiveTimeout,
      sendTimeout: defaultSendTimeout,
    ));
  }

  void newDio({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) {
    dio = Dio(BaseOptions(
      connectTimeout: connectTimeout ?? defaultConnectTimeout,
      receiveTimeout: receiveTimeout ?? defaultReceiveTimeout,
      sendTimeout: sendTimeout ?? defaultSendTimeout,
    ));
  }

  void cancel() {
    dio.close(force: true);
    _initDio();
  }
}
