import 'dart:typed_data';

import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart';

void downloadBytes({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) {
  downloadBytesImpl(fileName: fileName, mimeType: mimeType, bytes: bytes);
}
