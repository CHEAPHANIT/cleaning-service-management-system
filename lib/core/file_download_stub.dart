import 'dart:typed_data';

void downloadBytesImpl({
  required String fileName,
  required String mimeType,
  required Uint8List bytes,
}) {
  throw UnsupportedError('File downloads are only available on web.');
}
