import 'package:flutter_test/flutter_test.dart';
import 'package:glow_cam/core/color_matrix.dart';

/// Applies a 4x5 matrix to an RGBA pixel (0..255).
List<double> apply(List<double> m, List<double> px) => [
  for (var r = 0; r < 4; r++)
    m[r * 5] * px[0] + m[r * 5 + 1] * px[1] + m[r * 5 + 2] * px[2] + m[r * 5 + 3] * px[3] + m[r * 5 + 4],
];

void expectPixel(List<double> actual, List<double> expected) {
  for (var i = 0; i < 4; i++) {
    expect(actual[i], closeTo(expected[i], 1e-6), reason: 'channel $i');
  }
}

void main() {
  const px = [200.0, 120.0, 40.0, 255.0];

  test('identity leaves pixels unchanged', () {
    expectPixel(apply(ColorMatrix.identity, px), px);
  });

  test('then() applies first then second', () {
    final a = ColorMatrix.brightness(0.2);
    final b = ColorMatrix.contrast(1.3);
    final composed = ColorMatrix.then(a, b);
    expectPixel(apply(composed, px), apply(b, apply(a, px)));
  });

  test('chain() matches nested application', () {
    final ms = [ColorMatrix.warmth(0.5), ColorMatrix.saturation(1.4), ColorMatrix.fade(0.3)];
    var expected = px;
    for (final m in ms) {
      expected = apply(m, expected);
    }
    expectPixel(apply(ColorMatrix.chain(ms), px), expected);
  });

  test('saturation(0) produces gray', () {
    final out = apply(ColorMatrix.saturation(0), px);
    expect(out[0], closeTo(out[1], 1e-6));
    expect(out[1], closeTo(out[2], 1e-6));
  });

  test('lerpFromIdentity endpoints', () {
    final m = ColorMatrix.sepia;
    expect(ColorMatrix.lerpFromIdentity(m, 0), ColorMatrix.identity);
    expect(ColorMatrix.lerpFromIdentity(m, 1), m);
  });

  test('hue(0) is identity', () {
    expectPixel(apply(ColorMatrix.hue(0), px), px);
  });

  test('warmth increases red and decreases blue', () {
    final out = apply(ColorMatrix.warmth(1), px);
    expect(out[0], greaterThan(px[0]));
    expect(out[2], lessThan(px[2]));
  });
}
