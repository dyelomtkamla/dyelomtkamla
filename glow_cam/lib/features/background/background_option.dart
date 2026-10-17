import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

enum BackgroundKind { original, blur, color, gradient, image }

class BackgroundOption {
  const BackgroundOption({
    required this.id,
    required this.name,
    required this.kind,
    this.colors = const [],
    this.radial = false,
    this.isPro = false,
  });

  final String id;
  final String name;
  final BackgroundKind kind;
  final List<Color> colors;
  final bool radial;
  final bool isPro;

  bool get needsMask => kind != BackgroundKind.original;

  /// Builds the paint used to fill the backdrop for color/gradient kinds.
  Paint fillPaint(Rect rect) {
    final paint = Paint();
    if (kind == BackgroundKind.color) {
      paint.color = colors.first;
    } else if (radial) {
      paint.shader = ui.Gradient.radial(
        rect.center.translate(0, -rect.height * 0.12),
        rect.longestSide * 0.75,
        colors,
      );
    } else {
      paint.shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, colors);
    }
    return paint;
  }
}

const List<BackgroundOption> backgroundOptions = [
  BackgroundOption(id: 'original', name: 'الأصلية', kind: BackgroundKind.original),
  BackgroundOption(id: 'blur', name: 'بورتريه', kind: BackgroundKind.blur),
  BackgroundOption(id: 'white', name: 'أبيض', kind: BackgroundKind.color, colors: [Color(0xFFF7F7F5)]),
  BackgroundOption(id: 'black', name: 'أسود', kind: BackgroundKind.color, colors: [Color(0xFF111111)]),
  BackgroundOption(
    id: 'studio',
    name: 'استوديو',
    kind: BackgroundKind.gradient,
    colors: [Color(0xFF8E9096), Color(0xFF3A3B40)],
    radial: true,
    isPro: true,
  ),
  BackgroundOption(
    id: 'sunset',
    name: 'غروب',
    kind: BackgroundKind.gradient,
    colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B)],
    isPro: true,
  ),
  BackgroundOption(
    id: 'ocean',
    name: 'محيط',
    kind: BackgroundKind.gradient,
    colors: [Color(0xFF2193B0), Color(0xFF6DD5ED)],
    isPro: true,
  ),
  BackgroundOption(
    id: 'lavender',
    name: 'لافندر',
    kind: BackgroundKind.gradient,
    colors: [Color(0xFFB993D6), Color(0xFF8CA6DB)],
    isPro: true,
  ),
  BackgroundOption(
    id: 'rose',
    name: 'روز',
    kind: BackgroundKind.gradient,
    colors: [Color(0xFFFFDDE1), Color(0xFFEE9CA7)],
    radial: true,
    isPro: true,
  ),
  BackgroundOption(
    id: 'gold',
    name: 'ذهبية',
    kind: BackgroundKind.gradient,
    colors: [Color(0xFFF7E8B5), Color(0xFFC59B46)],
    radial: true,
    isPro: true,
  ),
  BackgroundOption(id: 'custom', name: 'صورتك', kind: BackgroundKind.image, isPro: true),
];
