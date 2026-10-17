import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'face_geometry.dart';

/// Tracks the main face on the live camera stream and publishes its geometry
/// normalized to the on-screen preview box.
class FaceTracker {
  FaceTracker()
    : _detector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: true,
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.15,
        ),
      );

  final FaceDetector _detector;
  final ValueNotifier<FaceGeometry?> face = ValueNotifier(null);

  bool _busy = false;
  bool _closed = false;

  /// Size of the on-screen box the preview fills (BoxFit.cover).
  Size screenBox = Size.zero;

  /// Upright size of the preview content (portrait).
  Size previewSize = Size.zero;

  /// Drops frames while the previous one is still being processed.
  Future<void> processFrame(CameraImage image, CameraDescription camera) async {
    if (_busy || _closed || screenBox.isEmpty || previewSize.isEmpty) return;
    _busy = true;
    try {
      final rotation = _rotation(camera);
      final input = rotation == null ? null : _toInputImage(image, rotation);
      if (input == null) return;
      final faces = await _detector.processImage(input);
      if (_closed) return;
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      _publish(faces, imageSize, rotation!, camera.lensDirection);
    } catch (e) {
      debugPrint('Face tracking error: $e');
    } finally {
      _busy = false;
    }
  }

  void _publish(List<Face> faces, Size imageSize, InputImageRotation rotation, CameraLensDirection lens) {
    final prev = face.value;
    FaceGeometry? next;
    if (faces.isNotEmpty) {
      final main = faces.reduce(
        (a, b) =>
            a.boundingBox.width * a.boundingBox.height >= b.boundingBox.width * b.boundingBox.height ? a : b,
      );
      next = FaceGeometry.fromFace(main, screenBox, (p) {
        final n = previewNormalized(p, imageSize, rotation, lens);
        return coverToBox(n, previewSize, screenBox);
      });
    }

    if (next == null) {
      // Fade out over a few frames instead of popping.
      if (prev == null) return;
      final w = prev.weight - 0.25;
      face.value = w <= 0 ? null : prev.withWeight(w);
      return;
    }
    if (prev == null) {
      face.value = next.withWeight(0.5);
    } else {
      // Exponential smoothing; strong enough to kill jitter, light enough to
      // follow head movement.
      face.value = prev.lerpTo(next, 0.6).withWeight(math.min(1, prev.weight + 0.5));
    }
  }

  /// Maps a detector point to 0..1 coordinates of the upright, as-displayed
  /// (mirrored for the selfie camera) preview. Mirrors the official ML Kit
  /// example's coordinate translation.
  @visibleForTesting
  static Offset previewNormalized(
    math.Point<int> p,
    Size imageSize,
    InputImageRotation rotation,
    CameraLensDirection lens,
  ) {
    final x = p.x.toDouble(), y = p.y.toDouble();
    final ios = Platform.isIOS;
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return Offset(
          x / (ios ? imageSize.width : imageSize.height),
          y / (ios ? imageSize.height : imageSize.width),
        );
      case InputImageRotation.rotation270deg:
        return Offset(
          1 - x / (ios ? imageSize.width : imageSize.height),
          y / (ios ? imageSize.height : imageSize.width),
        );
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        final nx = x / imageSize.width;
        return Offset(lens == CameraLensDirection.back ? nx : 1 - nx, y / imageSize.height);
    }
  }

  /// Maps 0..1 preview coordinates to pixels of [box] when the preview of
  /// [content] size fills it with BoxFit.cover (centered crop).
  static Offset coverToBox(Offset n, Size content, Size box) {
    final s = math.max(box.width / content.width, box.height / content.height);
    final dw = content.width * s, dh = content.height * s;
    return Offset((box.width - dw) / 2 + n.dx * dw, (box.height - dh) / 2 + n.dy * dh);
  }

  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImageRotation? _rotation(CameraDescription camera) {
    final sensor = camera.sensorOrientation;
    if (Platform.isIOS) return InputImageRotationValue.fromRawValue(sensor);
    // The app is locked to portrait.
    final comp = _orientations[DeviceOrientation.portraitUp]!;
    final deg = camera.lensDirection == CameraLensDirection.front
        ? (sensor + comp) % 360
        : (sensor - comp + 360) % 360;
    return InputImageRotationValue.fromRawValue(deg);
  }

  InputImage? _toInputImage(CameraImage image, InputImageRotation rotation) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    Uint8List bytes;
    var resolved = format;
    if (image.planes.length == 1) {
      bytes = image.planes.first.bytes;
    } else if (Platform.isAndroid && image.planes.length == 3) {
      bytes = _yuv420ToNv21(image);
      resolved = InputImageFormat.nv21;
    } else {
      return null;
    }
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: resolved,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Uint8List? _nv21;

  Uint8List _yuv420ToNv21(CameraImage image) {
    final w = image.width, h = image.height;
    final ySize = w * h;
    final out = (_nv21 != null && _nv21!.length == ySize + ySize ~/ 2)
        ? _nv21!
        : (_nv21 = Uint8List(ySize + ySize ~/ 2));
    final yPlane = image.planes[0];
    var dst = 0;
    for (var row = 0; row < h; row++) {
      out.setRange(dst, dst + w, yPlane.bytes, row * yPlane.bytesPerRow);
      dst += w;
    }
    final u = image.planes[1], v = image.planes[2];
    final uStride = u.bytesPerPixel ?? 1, vStride = v.bytesPerPixel ?? 1;
    var uv = ySize;
    for (var row = 0; row < h ~/ 2; row++) {
      for (var col = 0; col < w ~/ 2; col++) {
        out[uv++] = v.bytes[row * v.bytesPerRow + col * vStride];
        out[uv++] = u.bytes[row * u.bytesPerRow + col * uStride];
      }
    }
    return out;
  }

  void reset() => face.value = null;

  Future<void> close() async {
    _closed = true;
    await _detector.close();
    face.dispose();
  }
}

/// One-shot face detection for still photos (captured or from the gallery).
class StillFaceDetector {
  static Future<FaceGeometry?> detect(String path, Size imageSize) async {
    final detector = FaceDetector(
      options: FaceDetectorOptions(enableContours: true, performanceMode: FaceDetectorMode.accurate),
    );
    try {
      final faces = await detector.processImage(InputImage.fromFilePath(path));
      if (faces.isEmpty) return null;
      final main = faces.reduce(
        (a, b) =>
            a.boundingBox.width * a.boundingBox.height >= b.boundingBox.width * b.boundingBox.height ? a : b,
      );
      return FaceGeometry.fromFace(main, imageSize, (p) => Offset(p.x.toDouble(), p.y.toDouble()));
    } catch (e) {
      debugPrint('Still face detection failed: $e');
      return null;
    } finally {
      await detector.close();
    }
  }
}
