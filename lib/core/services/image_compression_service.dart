import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressionService {
  /// Compresses any image File to WebP format with an optimal balance of
  /// high romantic resolution (1200px max) and ultra-lightweight storage (~60-90 KB).
  static Future<File> compressToWebp(
    File file, {
    int quality = 75,
    int minWidth = 1200,
    int minHeight = 1200,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/compressed_${DateTime.now().microsecondsSinceEpoch}.webp';

      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        format: CompressFormat.webp,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        keepExif: false,
      );

      if (compressed != null) {
        return File(compressed.path);
      }
    } catch (_) {
      // Fallback cleanly to original file if compression fails
    }
    return file;
  }

  /// Compresses raw image bytes to WebP format (e.g. for profile avatars)
  static Future<Uint8List> compressBytesToWebp(
    Uint8List bytes, {
    int quality = 75,
    int minWidth = 800,
    int minHeight = 800,
  }) async {
    try {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        format: CompressFormat.webp,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
      );
      return compressed;
    } catch (_) {
      return bytes;
    }
  }
}
