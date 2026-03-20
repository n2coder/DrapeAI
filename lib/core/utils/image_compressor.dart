import 'dart:developer';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Client-side image compression applied before any upload leaves the device.
///
/// Target output: max 800×800 px, JPEG at 65 % quality.
/// A typical 3–5 MB phone-camera photo comes out at ~100–200 KB.
class ImageCompressor {
  static const int _maxDimension = 800;
  static const int _quality = 65;

  /// Compress [file] and return a new compressed [File].
  /// The original file is never modified.
  /// Falls back silently to the original if compression fails.
  static Future<File> compress(File file) async {
    try {
      final targetPath =
          '${file.parent.path}/cmp_${file.uri.pathSegments.last.replaceAll(RegExp(r'\.[^.]+$'), '')}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        minWidth: _maxDimension,
        minHeight: _maxDimension,
        quality: _quality,
        format: CompressFormat.jpeg,
      );

      if (result == null) return file;
      final compressed = File(result.path);

      // Log size reduction in debug mode
      final origKb = (await file.length() / 1024).round();
      final compKb = (await compressed.length() / 1024).round();
      final pct = origKb > 0 ? ((1 - compKb / origKb) * 100).round() : 0;
      log('ImageCompressor: ${origKb}KB → ${compKb}KB (–$pct%)',
          name: 'ImageCompressor');

      return compressed;
    } catch (e) {
      log('ImageCompressor: compression failed, using original — $e',
          name: 'ImageCompressor');
      return file;
    }
  }
}
