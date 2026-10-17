import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// A photo prepared for editing: EXIF rotation baked in, optionally mirrored
/// and cropped, downscaled, and decoded for the GPU.
class LoadedPhoto {
  LoadedPhoto({required this.image, required this.thumbnail, this._path});

  final ui.Image image;
  final ui.Image thumbnail;
  String? _path;

  ui.Size get size => ui.Size(image.width.toDouble(), image.height.toDouble());

  /// Upright image file on disk (fed to ML Kit so its output lines up
  /// exactly). Written lazily for in-memory snapshots.
  Future<String> file() async {
    final existing = _path;
    if (existing != null) return existing;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final path = await PhotoLoader._tempPath('png');
    await File(path).writeAsBytes(data!.buffer.asUint8List(), flush: true);
    return _path = path;
  }

  void dispose() {
    image.dispose();
    thumbnail.dispose();
  }
}

class PhotoLoader {
  static const int maxSide = 2048;
  static const int thumbSide = 180;

  /// Loads a file. [cropAspect] (width / height) center-crops to match the
  /// framing the user saw on screen.
  static Future<LoadedPhoto> load(String sourcePath, {bool mirror = false, double? cropAspect}) async {
    final bytes = await compute(_normalize, _NormalizeArgs(sourcePath, mirror, cropAspect));
    final path = await _tempPath('jpg');
    await File(path).writeAsBytes(bytes, flush: true);
    final image = await decode(bytes);
    final thumb = await decode(bytes, targetWidth: thumbSide);
    return LoadedPhoto(path: path, image: image, thumbnail: thumb);
  }

  /// Wraps an in-memory image (e.g. an instant preview snapshot).
  static Future<LoadedPhoto> fromImage(ui.Image image) async {
    final tw = thumbSide, th = (thumbSide * image.height / image.width).round();
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, tw.toDouble(), th.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    final picture = recorder.endRecording();
    final thumb = await picture.toImage(tw, th);
    picture.dispose();
    return LoadedPhoto(image: image, thumbnail: thumb);
  }

  static Future<ui.Image> decode(Uint8List bytes, {int? targetWidth}) async {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: targetWidth);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  static Future<String> _tempPath(String ext) async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/glow_${DateTime.now().microsecondsSinceEpoch}.$ext';
  }
}

class _NormalizeArgs {
  const _NormalizeArgs(this.path, this.mirror, this.cropAspect);
  final String path;
  final bool mirror;
  final double? cropAspect;
}

Uint8List _normalize(_NormalizeArgs args) {
  final decoded = img.decodeImage(File(args.path).readAsBytesSync());
  if (decoded == null) throw const FormatException('صيغة الصورة غير مدعومة');
  var out = img.bakeOrientation(decoded);
  if (args.mirror) out = img.flipHorizontal(out);
  final aspect = args.cropAspect;
  if (aspect != null && aspect > 0) out = centerCrop(out, aspect);
  final longest = out.width > out.height ? out.width : out.height;
  if (longest > PhotoLoader.maxSide) {
    out = out.width >= out.height
        ? img.copyResize(out, width: PhotoLoader.maxSide, interpolation: img.Interpolation.average)
        : img.copyResize(out, height: PhotoLoader.maxSide, interpolation: img.Interpolation.average);
  }
  return img.encodeJpg(out, quality: 95);
}

/// Center-crops [src] to [aspect] (width / height), like BoxFit.cover.
@visibleForTesting
img.Image centerCrop(img.Image src, double aspect) {
  final current = src.width / src.height;
  if ((current - aspect).abs() < 0.01) return src;
  if (current > aspect) {
    final w = (src.height * aspect).round();
    return img.copyCrop(src, x: (src.width - w) ~/ 2, y: 0, width: w, height: src.height);
  }
  final h = (src.width / aspect).round();
  return img.copyCrop(src, x: 0, y: (src.height - h) ~/ 2, width: src.width, height: h);
}
