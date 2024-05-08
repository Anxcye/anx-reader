import 'package:anx_reader/utils/webdav/common.dart';
import 'package:dio/dio.dart';
import 'package:webdav_client/webdav_client.dart';

Future<File?> safeReadProps(String path) async {
  File? file;
  try {
    file = await AnxWebdav.client.readProps(path);
  } catch (e) {
    if (e is DioException && e.response!.statusCode == 404) {
      return null;
    }
  }
  return file;
}
