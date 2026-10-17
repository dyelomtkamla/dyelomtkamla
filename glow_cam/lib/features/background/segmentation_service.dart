import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';

class NoPersonFoundException implements Exception {}

/// Separates the person from the background on-device with ML Kit.
class SegmentationService {
  /// Returns an alpha mask image (opaque = person) the same size as the photo.
  static Future<ui.Image> personMask(String imagePath) async {
    final segmenter = SelfieSegmenter(mode: SegmenterMode.single);
    try {
      final mask = await segmenter.processImage(InputImage.fromFilePath(imagePath));
      if (mask == null) throw NoPersonFoundException();
      final rgba = await compute(_confidencesToRgba, mask.confidences);
      if (rgba == null) throw NoPersonFoundException();
      return await _decodeRgba(rgba, mask.width, mask.height);
    } finally {
      await segmenter.close();
    }
  }

  static Future<ui.Image> _decodeRgba(Uint8List pixels, int width, int height) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(pixels, width, height, ui.PixelFormat.rgba8888, completer.complete);
    return completer.future;
  }
}

/// Converts ML Kit confidences to premultiplied white RGBA, sharpening the
/// edge a little so hair and shoulders look clean. Returns null if the mask
/// barely contains a person.
@visibleForTesting
Uint8List? confidencesToRgba(List<double> confidences) => _confidencesToRgba(confidences);

Uint8List? _confidencesToRgba(List<double> confidences) {
  final out = Uint8List(confidences.length * 4);
  var personPixels = 0;
  for (var i = 0; i < confidences.length; i++) {
    final c = confidences[i];
    // smoothstep(0.25, 0.75, c)
    final t = ((c - 0.25) / 0.5).clamp(0.0, 1.0);
    final a = (t * t * (3 - 2 * t) * 255).round();
    if (a > 128) personPixels++;
    final j = i * 4;
    out[j] = a;
    out[j + 1] = a;
    out[j + 2] = a;
    out[j + 3] = a;
  }
  if (personPixels < confidences.length * 0.02) return null;
  return out;
}
