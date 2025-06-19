import 'package:webdav_client/webdav_client.dart' as webdav show File;

class RemoteFile {
  String? path;
  bool? isDir;
  String? name;
  String? mimeType;
  int? size;
  String? eTag;
  DateTime? cTime;
  DateTime? mTime;

  RemoteFile({
    this.path,
    this.isDir,
    this.name,
    this.mimeType,
    this.size,
    this.eTag,
    this.cTime,
    this.mTime,
  });
}


extension WebdavFileExtension on webdav.File {
  RemoteFile toRemoteFile() {
    return RemoteFile(
      path: path,
      isDir: isDir,
      name: name,
      mimeType: mimeType,
      size: size,
      eTag: eTag,
      cTime: cTime,
      mTime: mTime,
    );
  }
}
