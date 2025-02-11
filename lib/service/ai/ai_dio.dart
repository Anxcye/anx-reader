import 'package:dio/dio.dart';

class AiDio {
  Dio dio = Dio();
  static final instance = AiDio._();

  AiDio._();

  void cancel() {
    dio.close(force: true);
    dio = Dio();
  }
}
