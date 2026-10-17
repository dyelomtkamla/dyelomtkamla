import '../../core/color_matrix.dart';
import '../background/background_option.dart';
import '../filters/filter_preset.dart';

class EditSettings {
  EditSettings({
    FilterPreset? preset,
    this.intensity = 1,
    BackgroundOption? background,
    this.smoothing = 0,
    this.glow = 0,
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.warmth = 0,
    this.vignette = 0,
  })  : preset = preset ?? filterPresets.first,
        background = background ?? backgroundOptions.first;

  final FilterPreset preset;
  final double intensity; // 0..1
  final BackgroundOption background;
  final double smoothing; // 0..1
  final double glow; // 0..1, added to the preset glow
  final double brightness; // -1..1
  final double contrast; // -1..1
  final double saturation; // -1..1
  final double warmth; // -1..1
  final double vignette; // 0..1, added to the preset vignette

  /// The full color grade: preset (scaled by intensity) followed by manual tweaks.
  List<double> get colorMatrix => ColorMatrix.chain([
        ColorMatrix.lerpFromIdentity(preset.matrix, intensity),
        ColorMatrix.brightness(brightness),
        ColorMatrix.contrast(1 + contrast * 0.5),
        ColorMatrix.saturation(1 + saturation),
        ColorMatrix.warmth(warmth),
      ]);

  double get totalGlow => (preset.glow * intensity + glow).clamp(0.0, 1.0);
  double get totalVignette => (preset.vignette * intensity + vignette).clamp(0.0, 1.0);
  double get washOpacity => preset.washOpacity * intensity;

  bool get usesPro => preset.isPro || background.isPro;

  EditSettings copyWith({
    FilterPreset? preset,
    double? intensity,
    BackgroundOption? background,
    double? smoothing,
    double? glow,
    double? brightness,
    double? contrast,
    double? saturation,
    double? warmth,
    double? vignette,
  }) =>
      EditSettings(
        preset: preset ?? this.preset,
        intensity: intensity ?? this.intensity,
        background: background ?? this.background,
        smoothing: smoothing ?? this.smoothing,
        glow: glow ?? this.glow,
        brightness: brightness ?? this.brightness,
        contrast: contrast ?? this.contrast,
        saturation: saturation ?? this.saturation,
        warmth: warmth ?? this.warmth,
        vignette: vignette ?? this.vignette,
      );
}
