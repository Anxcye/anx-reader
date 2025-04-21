import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:anx_reader/providers/fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';

class FontsSettingPage extends ConsumerWidget {
  const FontsSettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontList = ref.watch(fontsProvider);

    return Scaffold(
      body: fontList.when(
        data: (fonts) {
          if (fonts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView.builder(
            itemCount: fonts.length,
            itemBuilder: (context, index) {
              final font = fonts[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (font.preview.isNotEmpty)
                      CachedNetworkImage(
                        color: Theme.of(context).colorScheme.onSurface,
                        imageUrl: 'https://fonts.anxcye.com/${font.preview}',
                        width: MediaQuery.of(context).size.width,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                      Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            font.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(font.desc),

                          const SizedBox(height: 8),

                          // 官方网站链接
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            spacing: 5,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  launchUrlString(
                                    font.official,
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                                icon: const Icon(Icons.link),
                                label: Text(
                                  '官方网站',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),

                              ),

                              TextButton.icon(
                                onPressed: () {
                                  launchUrlString(
                                    font.license.url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                },
                                icon: const Icon(Icons.link),
                                label: Text(
                                  font.license.name,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _buildDownloadButton(
                              context, ref, font),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error to load fonts: $error'),
        ),
      ),
    );
  }

  Widget _buildDownloadButton(
    BuildContext context,
    WidgetRef ref,
    RemoteFontModel font,
  ) {
    final downloadState = ref.watch(fontDownloadsProvider)[font.id];
    final fontDownloads = ref.read(fontDownloadsProvider.notifier);
    final isAllFilesDownloaded =
        font.files.every((file) => fontDownloads.isDownloaded(font.id, file));

    if (isAllFilesDownloaded) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check),
        label: const Text('已安装')
      );
    }

    if (downloadState != null) {
      switch (downloadState.status) {
        case DownloadStatus.downloading:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: downloadState.progress),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                      '下载中 ${(downloadState.progress * 100).toStringAsFixed(1)}%'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => ref
                        .read(fontDownloadsProvider.notifier)
                        .pauseDownload(font.id),
                    icon: const Icon(Icons.pause),
                    label: const Text('暂停'),
                  ),
                  TextButton.icon(
                    onPressed: () => ref
                        .read(fontDownloadsProvider.notifier)
                        .cancelDownload(font.id),
                    icon: const Icon(Icons.cancel),
                    label: const Text('取消'),
                  ),
                ],
              ),
            ],
          );

        case DownloadStatus.paused:
          return Row(
            children: [
              Text('已暂停 ${(downloadState.progress * 100).toStringAsFixed(1)}%'),
              const Spacer(),
              TextButton.icon(
                onPressed: () => ref
                    .read(fontDownloadsProvider.notifier)
                    .resumeDownload(font),
                icon: const Icon(Icons.play_arrow),
                label: const Text('继续'),
              ),
              TextButton.icon(
                onPressed: () => ref
                    .read(fontDownloadsProvider.notifier)
                    .cancelDownload(font.id),
                icon: const Icon(Icons.cancel),
                label: const Text('取消'),
              ),
            ],
          );

        case DownloadStatus.failed:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('下载失败: ${downloadState.error}',
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => ref
                    .read(fontDownloadsProvider.notifier)
                    .startDownload(font),
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          );

        default:
          break;
      }
    }

    return ElevatedButton.icon(
      onPressed: () =>
          ref.read(fontDownloadsProvider.notifier).startDownload(font),
      icon: const Icon(Icons.download),
      label: const Text('下载'),
    );
  }
}
