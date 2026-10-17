import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../editor/edit_settings.dart';
import 'beauty_settings.dart';
import 'face_geometry.dart';

/// Loads the GPU beauty shader and turns settings into an [ui.ImageFilter].
///
/// Requires Impeller (the default renderer on modern iOS/Android). When it is
/// unavailable, [instance] stays null and the app falls back to plain color
/// filters.
class BeautyShader {
  BeautyShader._(this._program);

  final ui.FragmentProgram _program;

  static BeautyShader? instance;

  static Future<void> load() async {
    if (!ui.ImageFilter.isShaderFilterSupported) return;
    try {
      instance = BeautyShader._(await ui.FragmentProgram.fromAsset('shaders/beauty.frag'));
    } catch (e) {
      debugPrint('Beauty shader unavailable: $e');
    }
  }

  ui.ImageFilter filter({
    required EditSettings look,
    BeautySettings beauty = BeautySettings.off,
    FaceGeometry? face,
  }) {
    final shader = _program.fragmentShader();
    final values = uniforms(look: look, beauty: beauty, face: face);
    // Index 0-1 (uSize) is filled in by the engine.
    for (var i = 0; i < values.length; i++) {
      shader.setFloat(i + 2, values[i]);
    }
    return ui.ImageFilter.shader(shader);
  }

  /// Float uniforms after `uSize`, in declaration order of beauty.frag.
  @visibleForTesting
  static List<double> uniforms({
    required EditSettings look,
    required BeautySettings beauty,
    FaceGeometry? face,
  }) {
    final f = face;
    final m = look.colorMatrix;
    final wash = look.preset.wash;
    final washOpacity = wash == null ? 0.0 : look.washOpacity;
    final washA = wash?.first;
    final washB = wash?.last;
    return [
      // uFace
      f?.center.dx ?? 0, f?.center.dy ?? 0, f?.radius.width ?? 0, f?.radius.height ?? 0,
      // uRoll
      f?.roll ?? 0,
      // uEyes
      f?.eye1.dx ?? 0, f?.eye1.dy ?? 0, f?.eye2.dx ?? 0, f?.eye2.dy ?? 0,
      // uEyeRadius
      f?.eyeRadius ?? 0,
      // uJaw
      f?.jaw1.dx ?? 0, f?.jaw1.dy ?? 0, f?.jaw2.dx ?? 0, f?.jaw2.dy ?? 0,
      // uCheeks
      f?.cheek1.dx ?? 0, f?.cheek1.dy ?? 0, f?.cheek2.dx ?? 0, f?.cheek2.dy ?? 0,
      // uLips
      f?.lips.dx ?? 0, f?.lips.dy ?? 0, f?.lipsHalf.width ?? 0, f?.lipsHalf.height ?? 0,
      // uAmt1: smooth, eyes, slim, blush
      beauty.smooth, beauty.eyes, beauty.slim, beauty.blush,
      // uAmt2: lips, brighten, vignette, face weight
      beauty.lips, beauty.brighten, look.totalVignette, f?.weight ?? 0,
      // uAmt3: glow
      look.totalGlow, 0, 0, 0,
      // uColor (mat4, column-major) from the row-major 4x5 color matrix
      for (var c = 0; c < 4; c++)
        for (var r = 0; r < 4; r++) m[r * 5 + c],
      // uColorOffset
      m[4] / 255, m[9] / 255, m[14] / 255, m[19] / 255,
      // uWashA, uWashB
      (washA?.r ?? 0), (washA?.g ?? 0), (washA?.b ?? 0), washOpacity,
      (washB?.r ?? 0), (washB?.g ?? 0), (washB?.b ?? 0), 0,
    ];
  }
}
