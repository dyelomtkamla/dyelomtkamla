import 'package:flutter/painting.dart';

import '../../core/color_matrix.dart';

/// A "lens"-style look: a color grade plus optional glow, vignette and a
/// soft-light color wash. Everything scales with the user's intensity slider.
class FilterPreset {
  const FilterPreset({
    required this.id,
    required this.name,
    required this.matrix,
    this.glow = 0,
    this.vignette = 0,
    this.wash,
    this.washOpacity = 0,
    this.isPro = false,
  });

  final String id;
  final String name;
  final List<double> matrix;

  /// 0..1 bloom strength (screen-blended blur).
  final double glow;

  /// 0..1 darkening towards the edges.
  final double vignette;

  /// Gradient colors soft-light blended over the photo (light leaks, tints).
  final List<Color>? wash;
  final double washOpacity;

  final bool isPro;
}

final List<FilterPreset> filterPresets = [
  const FilterPreset(id: 'none', name: 'طبيعي', matrix: ColorMatrix.identity),
  FilterPreset(
    id: 'golden',
    name: 'ذهبي',
    matrix: ColorMatrix.chain([
      ColorMatrix.warmth(0.6),
      ColorMatrix.saturation(1.12),
      ColorMatrix.contrast(1.05),
    ]),
    glow: 0.15,
  ),
  FilterPreset(
    id: 'soft',
    name: 'ناعم',
    matrix: ColorMatrix.chain([
      ColorMatrix.fade(0.35),
      ColorMatrix.brightness(0.06),
      ColorMatrix.saturation(0.95),
    ]),
    glow: 0.3,
  ),
  FilterPreset(
    id: 'vivid',
    name: 'حيوي',
    matrix: ColorMatrix.chain([
      ColorMatrix.saturation(1.35),
      ColorMatrix.contrast(1.12),
    ]),
  ),
  FilterPreset(
    id: 'bw',
    name: 'أبيض وأسود',
    matrix: ColorMatrix.chain([
      ColorMatrix.saturation(0),
      ColorMatrix.contrast(1.18),
    ]),
    vignette: 0.35,
  ),
  // ---------- Pro looks ----------
  FilterPreset(
    id: 'creamy',
    name: 'كريمي',
    matrix: ColorMatrix.chain([
      ColorMatrix.warmth(0.35),
      ColorMatrix.fade(0.25),
      ColorMatrix.brightness(0.08),
      ColorMatrix.tint(r: 1.03, g: 1.0, b: 0.97),
    ]),
    glow: 0.45,
    isPro: true,
  ),
  FilterPreset(
    id: 'pink',
    name: 'وردي',
    matrix: ColorMatrix.chain([
      ColorMatrix.tint(r: 1.06, g: 0.97, b: 1.02, addR: 10, addB: 8),
      ColorMatrix.brightness(0.05),
      ColorMatrix.fade(0.15),
    ]),
    glow: 0.4,
    wash: const [Color(0xFFFF8FB8), Color(0xFFFFD1E3)],
    washOpacity: 0.35,
    isPro: true,
  ),
  FilterPreset(
    id: 'cinema',
    name: 'سينمائي',
    matrix: ColorMatrix.chain([
      ColorMatrix.tint(r: 1.08, g: 1.0, b: 0.9, addB: 18, addG: 6),
      ColorMatrix.contrast(1.15),
      ColorMatrix.saturation(0.9),
    ]),
    vignette: 0.5,
    wash: const [Color(0xFF00A3A3), Color(0xFFFF9248)],
    washOpacity: 0.25,
    isPro: true,
  ),
  FilterPreset(
    id: 'vintage',
    name: 'فينتاج',
    matrix: ColorMatrix.chain([
      ColorMatrix.lerpFromIdentity(ColorMatrix.sepia, 0.55),
      ColorMatrix.fade(0.4),
      ColorMatrix.contrast(1.05),
    ]),
    vignette: 0.55,
    isPro: true,
  ),
  FilterPreset(
    id: 'ice',
    name: 'ثلجي',
    matrix: ColorMatrix.chain([
      ColorMatrix.warmth(-0.55),
      ColorMatrix.brightness(0.07),
      ColorMatrix.saturation(0.9),
    ]),
    glow: 0.25,
    isPro: true,
  ),
  FilterPreset(
    id: 'neon',
    name: 'نيون',
    matrix: ColorMatrix.chain([
      ColorMatrix.saturation(1.45),
      ColorMatrix.contrast(1.1),
      ColorMatrix.hue(-12),
    ]),
    glow: 0.35,
    vignette: 0.35,
    wash: const [Color(0xFF8A2BE2), Color(0xFFFF2E93)],
    washOpacity: 0.4,
    isPro: true,
  ),
  FilterPreset(
    id: 'glow',
    name: 'إشراقة ✨',
    matrix: ColorMatrix.chain([
      ColorMatrix.brightness(0.1),
      ColorMatrix.warmth(0.2),
      ColorMatrix.saturation(1.08),
    ]),
    glow: 0.7,
    isPro: true,
  ),
  FilterPreset(
    id: 'studio',
    name: 'استوديو',
    matrix: ColorMatrix.chain([
      ColorMatrix.contrast(1.2),
      ColorMatrix.saturation(0.85),
      ColorMatrix.brightness(0.03),
    ]),
    vignette: 0.6,
    isPro: true,
  ),
  FilterPreset(
    id: 'sunset',
    name: 'غروب',
    matrix: ColorMatrix.chain([
      ColorMatrix.warmth(0.8),
      ColorMatrix.tint(r: 1.05, g: 0.98, b: 0.95, addR: 8),
      ColorMatrix.saturation(1.15),
    ]),
    glow: 0.3,
    wash: const [Color(0xFFFF5E62), Color(0xFFFFC371)],
    washOpacity: 0.45,
    isPro: true,
  ),
];
