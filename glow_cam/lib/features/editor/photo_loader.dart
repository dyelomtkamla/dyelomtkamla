import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// A photo prepared for editing: EXIF rotation baked in, optionally mirrored,
/// downscaled, and decoded for the GPU.
class LoadedPhoto {
  LoadedPhoto({required this.path, required this.image, required this.thumbnail});

  /// Normalized JPEG on disk (fed to ML Kit so the mask lines up exactly).
  final String path;
  final ui.Image image;
  final ui.Image thumbnail;

  void dispose() {
    image.dispose();
    thumbnail.dispose();
  }
}

class PhotoLoader {
  static const int maxSide = 2048;
  static const int thumbSide = 180;

  static Future<LoadedPhoto> load(String sourcePath, {bool mirror = false}) async {
    final dir = await getTemporaryDirectory();
    final outPath = '${dir.path}/glow_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final bytes = await compute(
      _normalize,
      _NormalizeArgs(sourcePath, mirror),
    );
    await File(outPath).writeAsBytes(bytes, flush: true);
    final image = await decode(bytes);
    final thumb = await decode(bytes, targetWidth: thumbSide);
    return LoadedPhoto(path: outPath, image: image, thumbnail: thumb);
  }

  static Future<ui.Image> decode(Uint8List bytes, {int? targetWidth}) async {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: targetWidth);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }
}

class _NormalizeArgs {
  const _NormalizeArgs(this.path, this.mirror);
  final String path;
  final bool mirror;
}

Uint8List _normalize(_NormalizeArgs args) {
  final decoded = img.decodeImage(File(args.path).readAsBytesSync());
  if (decoded == null) throw const FormatException('صيغة الصورة غير مدعومة');
  var out = img.bakeOrientation(decoded);
  if (args.mirror) out = img.flipHorizontal(out);
  final longest = out.width > out.height ? out.width : out.height;
  if (longest > PhotoLoader.maxSide) {
    out = out.width >= out.height
        ? img.copyResize(out, width: PhotoLoader.maxSide, interpolation: img.Interpolation.average)
        : img.copyResize(out, height: PhotoLoader.maxSide, interpolation: img.Interpolation.average);
  }
  return img.encodeJpg(out, quality: 95);
}
