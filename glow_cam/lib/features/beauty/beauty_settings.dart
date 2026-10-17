/// Face beauty amounts, each 0..1.
class BeautySettings {
  const BeautySettings({
    this.smooth = 0,
    this.eyes = 0,
    this.slim = 0,
    this.blush = 0,
    this.lips = 0,
    this.brighten = 0,
  });

  /// Subtle default, like a natural "beauty" lens.
  static const natural = BeautySettings(
    smooth: 0.6,
    eyes: 0.25,
    slim: 0.3,
    blush: 0.3,
    lips: 0.3,
    brighten: 0.35,
  );

  static const off = BeautySettings();

  final double smooth;
  final double eyes;
  final double slim;
  final double blush;
  final double lips;
  final double brighten;

  bool get isOff => this == off;

  BeautySettings copyWith({
    double? smooth,
    double? eyes,
    double? slim,
    double? blush,
    double? lips,
    double? brighten,
  }) => BeautySettings(
    smooth: smooth ?? this.smooth,
    eyes: eyes ?? this.eyes,
    slim: slim ?? this.slim,
    blush: blush ?? this.blush,
    lips: lips ?? this.lips,
    brighten: brighten ?? this.brighten,
  );

  @override
  bool operator ==(Object other) =>
      other is BeautySettings &&
      other.smooth == smooth &&
      other.eyes == eyes &&
      other.slim == slim &&
      other.blush == blush &&
      other.lips == lips &&
      other.brighten == brighten;

  @override
  int get hashCode => Object.hash(smooth, eyes, slim, blush, lips, brighten);
}
