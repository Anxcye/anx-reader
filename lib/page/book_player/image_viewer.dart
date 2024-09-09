import 'dart:convert';
import 'dart:typed_data';

import 'package:anx_reader/utils/download_util.dart';
import 'package:anx_reader/utils/get_path/cache_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/save_image_to_path.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

class ImageViewer extends StatelessWidget {
  final String image;
  final String bookName;

  const ImageViewer({
    super.key,
    required this.image,
    required this.bookName,
  });

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    String? imgType;

    try {
      final List<String> parts = image.split(',');
      String base64 = parts[1];
      imageBytes = base64Decode(base64);
      imgType = parts[0].split('/')[1].split(';')[0];
    } catch (e) {
      AnxLog.severe('Error decoding image: $e');
      return const Center(child: Text('Error'));
    }

    return Stack(
      children: [
        PhotoView(
          imageProvider: MemoryImage(imageBytes),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (context, event) => const Center(
            child: CircularProgressIndicator(),
          ),
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 3,

        ),
        Positioned.fill(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {
                          DownloadUtil.downloadImg(
                              imageBytes!, imgType!, bookName);
                        },
                        icon: const Icon(Icons.download, color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () async {
                          final path = await saveImageToPath(
                            image,
                            (await getAnxCacheDir()).path,
                            "AnxReader_$bookName",
                          );

                          Share.shareXFiles([XFile(path)]);
                        },
                        icon: const Icon(Icons.share, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
