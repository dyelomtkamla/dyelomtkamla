import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart' show CameraLensDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow_cam/core/color_matrix.dart';
import 'package:glow_cam/features/beauty/beauty_settings.dart';
import 'package:glow_cam/features/beauty/beauty_shader.dart';
import 'package:glow_cam/features/beauty/face_geometry.dart';
import 'package:glow_cam/features/beauty/face_tracker.dart';
import 'package:glow_cam/features/editor/edit_settings.dart';
import 'package:glow_cam/features/editor/photo_loader.dart';
import 'package:glow_cam/features/filters/filter_preset.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// A synthetic upright face centered at (cx, cy) with half-width r, rotated by [roll].
({List<Offset> oval, List<Offset> eyeA, List<Offset> eyeB, List<Offset> lips}) synthFace(
  double cx,
  double cy,
  double r, {
  double roll = 0,
}) {
  Offset rot(double x, double y) {
    final c = math.cos(roll), s = math.sin(roll);
    return Offset(cx + c * x - s * y, cy + s * x + c * y);
  }

  final oval = [
    for (var i = 0; i < 36; i++) rot(r * math.sin(i * math.pi / 18), -1.3 * r * math.cos(i * math.pi / 18)),
  ];
  List<Offset> ring(double x, double y, double rx, double ry) => [
    for (var i = 0; i < 16; i++) rot(x + rx * math.cos(i * math.pi / 8), y + ry * math.sin(i * math.pi / 8)),
  ];
  return (
    oval: oval,
    eyeA: ring(-0.4 * r, -0.2 * r, 0.15 * r, 0.06 * r),
    eyeB: ring(0.4 * r, -0.2 * r, 0.15 * r, 0.06 * r),
    lips: ring(0, 0.65 * r, 0.3 * r, 0.1 * r),
  );
}

void main() {
  const box = Size(400, 800);

  group('FaceGeometry', () {
    test('normalizes key points to the box', () {
      final f = synthFace(200, 400, 100);
      final g = FaceGeometry.fromPoints(box: box, oval: f.oval, eyeA: f.eyeA, eyeB: f.eyeB, lips: f.lips)!;
      expect(g.center.dx, closeTo(0.5, 0.01));
      expect(g.center.dy, closeTo(0.5, 0.01));
      expect(g.radius.width, closeTo(100 / 400, 0.01));
      expect(g.roll, closeTo(0, 1e-6));
      expect(g.eye1.dx, lessThan(g.eye2.dx));
      expect(g.eye1.dx * 400, closeTo(160, 1));
      expect(g.eye1.dy * 800, closeTo(380, 1));
      expect(g.eyeRadius * 400, closeTo(80 * 0.38, 0.5));
      // Jaw anchors sit in the lower half, on each side of the face.
      expect(g.jaw1.dx, lessThan(0.5));
      expect(g.jaw2.dx, greaterThan(0.5));
      expect(g.jaw1.dy, greaterThan(0.5));
      // Lips below the eyes, cheeks between eyes and lips.
      expect(g.lips.dy * 800, closeTo(465, 1));
      expect(g.cheek1.dy, inExclusiveRange(g.eye1.dy, g.lips.dy));
    });

    test('measures roll from the eye line', () {
      final f = synthFace(200, 400, 100, roll: 0.3);
      final g = FaceGeometry.fromPoints(box: box, oval: f.oval, eyeA: f.eyeA, eyeB: f.eyeB, lips: f.lips)!;
      expect(g.roll, closeTo(0.3, 1e-3));
      expect(g.center.dx * 400, closeTo(200, 2));
    });

    test('eye order does not depend on contour labels (mirroring)', () {
      final f = synthFace(200, 400, 100);
      final a = FaceGeometry.fromPoints(box: box, oval: f.oval, eyeA: f.eyeA, eyeB: f.eyeB, lips: f.lips)!;
      final b = FaceGeometry.fromPoints(box: box, oval: f.oval, eyeA: f.eyeB, eyeB: f.eyeA, lips: f.lips)!;
      expect(a.eye1, b.eye1);
      expect(a.roll, closeTo(b.roll, 1e-9));
    });

    test('rejects degenerate input', () {
      final f = synthFace(200, 400, 100);
      expect(
        FaceGeometry.fromPoints(
          box: box,
          oval: f.oval.take(3).toList(),
          eyeA: f.eyeA,
          eyeB: f.eyeB,
          lips: f.lips,
        ),
        isNull,
      );
    });

    test('lerpTo blends and keeps endpoints', () {
      final a = FaceGeometry.fromPoints(
        box: box,
        oval: synthFace(150, 400, 100).oval,
        eyeA: synthFace(150, 400, 100).eyeA,
        eyeB: synthFace(150, 400, 100).eyeB,
        lips: synthFace(150, 400, 100).lips,
      )!;
      final f = synthFace(250, 400, 100);
      final b = FaceGeometry.fromPoints(box: box, oval: f.oval, eyeA: f.eyeA, eyeB: f.eyeB, lips: f.lips)!;
      expect(a.lerpTo(b, 0).center, a.center);
      expect(a.lerpTo(b, 1).center.dx, closeTo(b.center.dx, 1e-9));
      expect(a.lerpTo(b, 0.5).center.dx, closeTo(0.5, 0.01));
    });
  });

  group('FaceTracker mapping', () {
    test('front camera (rotation 270) is mirrored on Android', () {
      final n = FaceTracker.previewNormalized(
        const math.Point(180, 320),
        const Size(1280, 720),
        InputImageRotation.rotation270deg,
        CameraLensDirection.front,
      );
      expect(n.dx, closeTo(1 - 180 / 720, 1e-9));
      expect(n.dy, closeTo(320 / 1280, 1e-9));
    });

    test('coverToBox crops the centered preview', () {
      // 720x1280 preview on a 1080x2400 screen: height-bound, sides cropped.
      const content = Size(720, 1280), screen = Size(1080, 2400);
      expect(FaceTracker.coverToBox(const Offset(0.5, 0.5), content, screen), const Offset(540, 1200));
      final top = FaceTracker.coverToBox(Offset.zero, content, screen);
      expect(top.dy, closeTo(0, 1e-9));
      expect(top.dx, lessThan(0));
    });
  });

  test('centerCrop matches the screen aspect', () {
    final src = img.Image(width: 900, height: 1600);
    final out = centerCrop(src, 1080 / 2400);
    expect(out.width / out.height, closeTo(1080 / 2400, 0.01));
    expect(out.height, 1600);
  });

  group('BeautyShader.uniforms', () {
    test('has one value per float uniform after uSize', () {
      final u = BeautyShader.uniforms(look: EditSettings(), beauty: BeautySettings.natural);
      expect(u.length, 62);
    });

    test('packs the color matrix column-major with offsets in 0..1', () {
      final look = EditSettings(preset: filterPresets.firstWhere((p) => p.id == 'golden'));
      final u = BeautyShader.uniforms(look: look, beauty: BeautySettings.off);
      final m = look.colorMatrix;
      const matStart = 34;
      for (var c = 0; c < 4; c++) {
        for (var r = 0; r < 4; r++) {
          expect(u[matStart + c * 4 + r], m[r * 5 + c]);
        }
      }
      expect(u[matStart + 16], closeTo(m[4] / 255, 1e-12));
    });

    test('face weight is zero without a face', () {
      final u = BeautyShader.uniforms(look: EditSettings(), beauty: BeautySettings.natural);
      expect(u[29], 0);
    });
  });

  group('beauty.frag', () {
    late ui.FragmentProgram program;

    setUpAll(() async {
      program = await ui.FragmentProgram.fromAsset('shaders/beauty.frag');
    });

    Future<ui.Image> image(int w, int h, List<int> Function(int x, int y) px) async {
      final bytes = Uint8List(w * h * 4);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          bytes.setRange((y * w + x) * 4, (y * w + x) * 4 + 4, px(x, y));
        }
      }
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final d = ui.ImageDescriptor.raw(buffer, width: w, height: h, pixelFormat: ui.PixelFormat.rgba8888);
      return (await (await d.instantiateCodec()).getNextFrame()).image;
    }

    /// Runs the shader as a paint shader (the CPU-testable path) and returns RGBA.
    Future<ByteData> run(ui.Image input, List<double> uniforms) async {
      final shader = program.fragmentShader()
        ..setFloat(0, input.width.toDouble())
        ..setFloat(1, input.height.toDouble());
      for (var i = 0; i < uniforms.length; i++) {
        shader.setFloat(i + 2, uniforms[i]);
      }
      shader.setImageSampler(0, input);
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(
        Rect.fromLTWH(0, 0, input.width.toDouble(), input.height.toDouble()),
        Paint()..shader = shader,
      );
      final out = await recorder.endRecording().toImage(input.width, input.height);
      return (await out.toByteData())!;
    }

    int at(ByteData d, int w, int x, int y, int c) => d.getUint8((y * w + x) * 4 + c);

    testWidgets('identity look leaves the image unchanged', (tester) async {
      await tester.runAsync(() async {
        final input = await image(16, 16, (x, y) => [x * 15, y * 15, 128, 255]);
        final out = await run(input, BeautyShader.uniforms(look: EditSettings(), beauty: BeautySettings.off));
        for (final (x, y) in [(0, 0), (5, 9), (15, 15)]) {
          for (var c = 0; c < 3; c++) {
            expect((at(out, 16, x, y, c) - [x * 15, y * 15, 128][c]).abs(), lessThanOrEqualTo(2));
          }
        }
      });
    });

    testWidgets('B&W look outputs gray', (tester) async {
      await tester.runAsync(() async {
        final input = await image(8, 8, (x, y) => [210, 90, 40, 255]);
        final look = EditSettings(preset: filterPresets.firstWhere((p) => p.id == 'bw'));
        final out = await run(input, BeautyShader.uniforms(look: look, beauty: BeautySettings.off));
        final r = at(out, 8, 4, 4, 0), g = at(out, 8, 4, 4, 1), b = at(out, 8, 4, 4, 2);
        expect((r - g).abs() <= 2 && (g - b).abs() <= 2, isTrue, reason: '$r,$g,$b');
      });
    });

    testWidgets('smoothing evens out skin but keeps dark beard pixels', (tester) async {
      await tester.runAsync(() async {
        const w = 64;
        final rnd = math.Random(1);
        // Skin tone with blotchy noise, and a dark "beard" stripe at the bottom.
        final input = await image(w, w, (x, y) {
          if (y >= 56) return [25, 20, 18, 255];
          final n = rnd.nextInt(24) - 12;
          return [214 + n, 160 + n, 135 + n, 255];
        });
        double variance(ByteData d) {
          final vals = [
            for (var y = 8; y < 48; y++)
              for (var x = 8; x < 56; x++) at(d, w, x, y, 1).toDouble(),
          ];
          final mean = vals.reduce((a, b) => a + b) / vals.length;
          return vals.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / vals.length;
        }

        final f = synthFace(32, 32, 30);
        final face = FaceGeometry.fromPoints(
          box: const Size(w * 1.0, w * 1.0),
          oval: f.oval,
          eyeA: f.eyeA,
          eyeB: f.eyeB,
          lips: f.lips,
        );
        final before = await run(
          input,
          BeautyShader.uniforms(look: EditSettings(), beauty: BeautySettings.off, face: face),
        );
        final after = await run(
          input,
          BeautyShader.uniforms(look: EditSettings(), beauty: const BeautySettings(smooth: 1), face: face),
        );
        expect(variance(after), lessThan(variance(before) * 0.6));
        // Beard stays dark and untouched.
        expect(at(after, w, 32, 62, 0), lessThanOrEqualTo(30));
      });
    });

    testWidgets('eye enlarge magnifies around the eye center', (tester) async {
      await tester.runAsync(() async {
        const w = 200, h = 400;
        // A small dark "pupil" disc (radius 6) at the first eye position.
        final f = synthFace(100, 200, 60);
        final face = FaceGeometry.fromPoints(
          box: const Size(w * 1.0, h * 1.0),
          oval: f.oval,
          eyeA: f.eyeA,
          eyeB: f.eyeB,
          lips: f.lips,
        )!;
        final ex = face.eye1.dx * w, ey = face.eye1.dy * h;
        final input = await image(w, h, (x, y) {
          final inside = (x - ex) * (x - ex) + (y - ey) * (y - ey) < 36;
          return inside ? [0, 0, 0, 255] : [230, 230, 230, 255];
        });
        int darkWidth(ByteData d) {
          var n = 0;
          for (var x = 0; x < w; x++) {
            if (at(d, w, x, ey.round(), 0) < 128) n++;
          }
          return n;
        }

        final plain = await run(
          input,
          BeautyShader.uniforms(look: EditSettings(), beauty: BeautySettings.off, face: face),
        );
        final big = await run(
          input,
          BeautyShader.uniforms(look: EditSettings(), beauty: const BeautySettings(eyes: 1), face: face),
        );
        expect(darkWidth(big), greaterThan(darkWidth(plain)));
      });
    });
  });

  test('identity matrix sanity', () {
    expect(EditSettings().colorMatrix.length, ColorMatrix.identity.length);
  });
}
