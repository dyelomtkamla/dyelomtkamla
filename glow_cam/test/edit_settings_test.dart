import 'package:flutter_test/flutter_test.dart';
import 'package:glow_cam/core/color_matrix.dart';
import 'package:glow_cam/features/background/background_option.dart';
import 'package:glow_cam/features/background/segmentation_service.dart';
import 'package:glow_cam/features/editor/edit_settings.dart';
import 'package:glow_cam/features/filters/filter_preset.dart';

void main() {
  test('default settings are a no-op grade', () {
    final m = EditSettings().colorMatrix;
    for (var i = 0; i < 20; i++) {
      expect(m[i], closeTo(ColorMatrix.identity[i], 1e-9));
    }
    expect(EditSettings().usesPro, isFalse);
  });

  test('pro filter or background marks the edit as Pro', () {
    final proPreset = filterPresets.firstWhere((p) => p.isPro);
    final proBg = backgroundOptions.firstWhere((b) => b.isPro);
    expect(EditSettings(preset: proPreset).usesPro, isTrue);
    expect(EditSettings(background: proBg).usesPro, isTrue);
  });

  test('intensity scales glow and vignette', () {
    final p = filterPresets.firstWhere((p) => p.glow > 0 && p.vignette > 0);
    final half = EditSettings(preset: p, intensity: 0.5);
    expect(half.totalGlow, closeTo(p.glow * 0.5, 1e-9));
    expect(half.totalVignette, closeTo(p.vignette * 0.5, 1e-9));
  });

  test('preset and background ids are unique', () {
    expect(filterPresets.map((p) => p.id).toSet().length, filterPresets.length);
    expect(backgroundOptions.map((b) => b.id).toSet().length, backgroundOptions.length);
  });

  group('confidencesToRgba', () {
    test('returns null when no person is present', () {
      expect(confidencesToRgba(List.filled(100, 0.05)), isNull);
    });

    test('maps confidence to premultiplied alpha with a sharpened edge', () {
      final out = confidencesToRgba([1, 0, 0.5, ...List.filled(10, 1.0)])!;
      expect(out.sublist(0, 4), [255, 255, 255, 255]);
      expect(out[7], 0);
      expect(out[11], inInclusiveRange(120, 135));
    });
  });
}
