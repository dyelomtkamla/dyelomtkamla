import 'dart:math' as math;

/// 4x5 color matrices in the format used by Flutter's `ColorFilter.matrix`
/// (row-major, translation column in 0..255 space).
class ColorMatrix {
  ColorMatrix._();

  static const List<double> identity = [
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0, //
    0, 0, 1, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  /// Returns the matrix that applies [first] and then [second].
  static List<double> then(List<double> first, List<double> second) {
    final out = List<double>.filled(20, 0);
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 5; c++) {
        var v = 0.0;
        for (var k = 0; k < 4; k++) {
          v += second[r * 5 + k] * first[k * 5 + c];
        }
        if (c == 4) v += second[r * 5 + 4];
        out[r * 5 + c] = v;
      }
    }
    return out;
  }

  /// Chains several matrices, applied in list order.
  static List<double> chain(List<List<double>> matrices) => matrices.fold(identity, then);

  /// Linear blend between identity (t = 0) and [m] (t = 1).
  static List<double> lerpFromIdentity(List<double> m, double t) =>
      List<double>.generate(20, (i) => identity[i] + (m[i] - identity[i]) * t);

  /// [amount] in -1..1, shifts all channels.
  static List<double> brightness(double amount) {
    final o = amount * 255 * 0.4;
    return [1, 0, 0, 0, o, 0, 1, 0, 0, o, 0, 0, 1, 0, o, 0, 0, 0, 1, 0];
  }

  /// [factor] 1 = unchanged, < 1 flatter, > 1 punchier.
  static List<double> contrast(double factor) {
    final o = 128 * (1 - factor);
    return [
      factor, 0, 0, 0, o, //
      0, factor, 0, 0, o, //
      0, 0, factor, 0, o, //
      0, 0, 0, 1, 0, //
    ];
  }

  /// [s] 1 = unchanged, 0 = grayscale.
  static List<double> saturation(double s) {
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final inv = 1 - s;
    return [
      lr * inv + s, lg * inv, lb * inv, 0, 0, //
      lr * inv, lg * inv + s, lb * inv, 0, 0, //
      lr * inv, lg * inv, lb * inv + s, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }

  /// [t] in -1..1: positive is warmer (more red/yellow), negative cooler.
  static List<double> warmth(double t) {
    final o = t * 30;
    return [
      1, 0, 0, 0, o, //
      0, 1, 0, 0, o * 0.35, //
      0, 0, 1, 0, -o, //
      0, 0, 0, 1, 0, //
    ];
  }

  /// Multiplies each channel and adds an offset (0..255 space).
  static List<double> tint({
    double r = 1,
    double g = 1,
    double b = 1,
    double addR = 0,
    double addG = 0,
    double addB = 0,
  }) => [
    r, 0, 0, 0, addR, //
    0, g, 0, 0, addG, //
    0, 0, b, 0, addB, //
    0, 0, 0, 1, 0, //
  ];

  /// Lifts blacks and lowers whites for a matte, faded look. [a] in 0..1.
  static List<double> fade(double a) {
    final k = 1 - a * 0.25;
    final o = a * 255 * 0.12;
    return tint(r: k, g: k, b: k, addR: o, addG: o, addB: o);
  }

  static const List<double> sepia = [
    0.393, 0.769, 0.189, 0, 0, //
    0.349, 0.686, 0.168, 0, 0, //
    0.272, 0.534, 0.131, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  /// Rotates hue by [degrees].
  static List<double> hue(double degrees) {
    final rad = degrees * math.pi / 180;
    final c = math.cos(rad), s = math.sin(rad);
    const lr = 0.213, lg = 0.715, lb = 0.072;
    return [
      lr + c * (1 - lr) + s * -lr, lg + c * -lg + s * -lg, lb + c * -lb + s * (1 - lb), 0, 0, //
      lr + c * -lr + s * 0.143, lg + c * (1 - lg) + s * 0.140, lb + c * -lb + s * -0.283, 0, 0, //
      lr + c * -lr + s * -(1 - lr), lg + c * -lg + s * lg, lb + c * (1 - lb) + s * lb, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }
}
