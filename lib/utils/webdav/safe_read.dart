import 'package:dio/dio.dart';
import 'package:webdav_client/webdav_client.dart';

Future<File?> safeReadProps(String path, Client client) async {
  File? file;
  try {
    file = await client.readProps(path);
  } catch (e) {
    if (e is DioException && e.response == null) {
      rethrow;
    }
    if (e is DioException && e.response!.statusCode == 404) {
      return null;
    }
  }
  return file;
}
