import 'dart:convert';
import 'dart:io';

import 'package:anx_reader/providers/font_list.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/get_path/get_temp_dir.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;

part 'fonts.g.dart';
part 'fonts.freezed.dart';

const String fontBaseUrl = 'https://fonts.anxcye.com/';
const String fontManifestUrl = '${fontBaseUrl}fonts-manifest.json';

@freezed
abstract class LicenseModel with _$LicenseModel {
  const factory LicenseModel({
    required String name,
    required String url,
  }) = _LicenseModel;

  factory LicenseModel.fromJson(Map<String, dynamic> json) =>
      _$LicenseModelFromJson(json);
}

@freezed
abstract class RemoteFontModel with _$RemoteFontModel {
  const factory RemoteFontModel({
    required String id,
    required String name,
    required List<String> files,
    required String preview,
    required String desc,
    required String official,
    required LicenseModel license,
  }) = _RemoteFontModel;

  factory RemoteFontModel.fromJson(Map<String, dynamic> json) =>
      _$RemoteFontModelFromJson(json);
}

enum DownloadStatus {
  none,
  downloading,
  paused,
  completed,
  failed,
}

@freezed
abstract class FontDownloadState with _$FontDownloadState {
  const factory FontDownloadState({
    required String fontId,
    required String filePath,
    required DownloadStatus status,
    @Default(0.0) double progress,
    String? error,
    CancelToken? cancelToken,
  }) = _FontDownloadState;
}

@Riverpod(keepAlive: true)
class Fonts extends _$Fonts {
  final Dio dio = Dio();

  @override
  Future<List<RemoteFontModel>> build() async {
    final response = await http.get(Uri.parse(fontManifestUrl));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => RemoteFontModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load fonts manifest');
    }
  }
}

@Riverpod(keepAlive: true)
class FontDownloads extends _$FontDownloads {
  @override
  Map<String, FontDownloadState> build() {
    return {};
  }

  Future<void> startDownload(RemoteFontModel font) async {
    final fontId = font.id;
    final tempDir = await getAnxTempDir();
    final fontDir = getFontDir();
    final dio = Dio();

    if (!fontDir.existsSync()) {
      fontDir.createSync(recursive: true);
    }

    for (final filePath in font.files) {
      final fileName = filePath.split('/').last;
      final tempFilePath = '${tempDir.path}/$fileName';
      final finalFilePath = '${fontDir.path}${Platform.pathSeparator}$fileName';

      final cancelToken = CancelToken();

      state = {
        ...state,
        fontId: FontDownloadState(
          fontId: fontId,
          filePath: filePath,
          status: DownloadStatus.downloading,
          progress: 0.0,
          cancelToken: cancelToken,
        )
      };

      try {
        await dio.download(
          '$fontBaseUrl$filePath',
          tempFilePath,
          cancelToken: cancelToken,
          options: Options(
            headers: {
              HttpHeaders.acceptEncodingHeader: '*',
            },
          ),
          lengthHeader: 'Content-Length',
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = received / total;
              state = {
                ...state,
                fontId: state[fontId]!.copyWith(progress: progress)
              };
            }
          },
        );

        final tempFile = File(tempFilePath);
        if (await tempFile.exists()) {
          final finalFile = File(finalFilePath);
          if (await finalFile.exists()) {
            await finalFile.delete();
          }

          final finalDirectory = Directory(finalFilePath.substring(
              0, finalFilePath.lastIndexOf(Platform.pathSeparator)));
          if (!await finalDirectory.exists()) {
            await finalDirectory.create(recursive: true);
          }

          await tempFile.copy(finalFilePath);
          await tempFile.delete();

          state = {
            ...state,
            fontId: state[fontId]!.copyWith(
              status: DownloadStatus.completed,
              progress: 1.0,
            )
          };
        }
      } catch (e) {
        if (e is DioException && e.type == DioExceptionType.cancel) {
          return;
        }

        state = {
          ...state,
          fontId: state[fontId]!.copyWith(
            status: DownloadStatus.failed,
            error: e.toString(),
          )
        };
      } finally {
        // refresh font list
        ref.watch(fontListProvider.notifier).refresh();
      }
    }
  }

  void pauseDownload(String fontId) {
    final download = state[fontId];
    if (download != null && download.status == DownloadStatus.downloading) {
      download.cancelToken?.cancel('Download paused');
      state = {
        ...state,
        fontId: download.copyWith(status: DownloadStatus.paused)
      };
    }
  }

  void resumeDownload(RemoteFontModel font) {
    final fontId = font.id;
    final download = state[fontId];
    if (download != null && download.status == DownloadStatus.paused) {
      startDownload(font);
    }
  }

  void cancelDownload(String fontId) {
    final download = state[fontId];
    if (download != null && download.status == DownloadStatus.downloading) {
      download.cancelToken?.cancel('Download canceled');
      state = {
        ...state,
        fontId: download.copyWith(status: DownloadStatus.none, progress: 0.0)
      };
    }
  }

  bool isDownloaded(String fontId, String filePath) {
    final fontDir = getFontDir();
    final fileName = filePath.split('/').last;
    final finalFilePath = '${fontDir.path}${Platform.pathSeparator}$fileName';
    return File(finalFilePath).existsSync();
  }
}
