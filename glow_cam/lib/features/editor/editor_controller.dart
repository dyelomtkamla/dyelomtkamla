import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../background/background_option.dart';
import '../background/segmentation_service.dart';
import '../beauty/beauty_settings.dart';
import '../beauty/beauty_shader.dart';
import '../beauty/face_geometry.dart';
import '../filters/filter_preset.dart';
import 'edit_settings.dart';
import 'photo_loader.dart';
import 'photo_painter.dart';

/// A photo plus where its face is (null if none was found).
typedef PhotoWithFace = ({LoadedPhoto photo, FaceGeometry? face});

class EditorController extends ChangeNotifier {
  EditorController(
    this._photo, {
    this.face,
    FilterPreset? initialPreset,
    this._beauty = BeautySettings.natural,
    Future<PhotoWithFace?>? fullQuality,
  }) : _settings = EditSettings(preset: initialPreset) {
    if (fullQuality != null) {
      upgrading = true;
      fullQuality.then(
        _applyUpgrade,
        onError: (Object e) {
          debugPrint('Full-quality capture failed: $e');
          upgrading = false;
          if (!_disposed) notifyListeners();
        },
      );
    }
  }

  LoadedPhoto _photo;
  LoadedPhoto get photo => _photo;

  /// Face in the photo, normalized to the photo's box.
  FaceGeometry? face;

  EditSettings _settings;
  EditSettings get settings => _settings;

  BeautySettings _beauty;
  BeautySettings get beauty => _beauty;

  ui.Image? mask;
  ui.Image? customBackground;
  bool segmenting = false;

  /// True while the full-resolution still replaces the instant snapshot.
  bool upgrading = false;
  String? message;
  bool _disposed = false;

  BeautyShader? get shader => BeautyShader.instance;

  void update(EditSettings Function(EditSettings s) change) {
    _settings = change(_settings);
    notifyListeners();
  }

  void updateBeauty(BeautySettings Function(BeautySettings b) change) {
    _beauty = change(_beauty);
    notifyListeners();
  }

  void selectPreset(FilterPreset p) => update((s) => s.copyWith(preset: p));

  /// GPU filter for the current look, or null on devices without support.
  ui.ImageFilter? filter() => shader?.filter(look: _settings, beauty: _beauty, face: face);

  PhotoPainter painter({bool original = false}) => PhotoPainter(
    photo: _photo.image,
    settings: _settings,
    mask: mask,
    customBackground: customBackground,
    showOriginal: original,
    lookInShader: shader != null,
    smoothing: _beauty.smooth,
  );

  /// Runs person segmentation the first time a background is chosen.
  Future<void> selectBackground(BackgroundOption option) async {
    if (option.needsMask && mask == null) {
      await _segment();
      if (mask == null) {
        notifyListeners();
        return;
      }
    }
    update((s) => s.copyWith(background: option));
  }

  Future<void> _segment() async {
    segmenting = true;
    message = null;
    notifyListeners();
    try {
      mask = await SegmentationService.personMask(await _photo.file());
    } on NoPersonFoundException {
      message = 'لم نتعرف على شخص في الصورة. جرّب صورة سيلفي أوضح.';
    } catch (e) {
      message = 'تعذر فصل الخلفية: $e';
    } finally {
      segmenting = false;
    }
  }

  Future<void> setCustomBackground(String path) async {
    final image = await PhotoLoader.decode(await File(path).readAsBytes(), targetWidth: PhotoLoader.maxSide);
    customBackground?.dispose();
    customBackground = image;
    await selectBackground(backgroundOptions.firstWhere((b) => b.kind == BackgroundKind.image));
  }

  Future<void> _applyUpgrade(PhotoWithFace? result) async {
    upgrading = false;
    if (_disposed) {
      result?.photo.dispose();
      return;
    }
    if (result == null) {
      notifyListeners();
      return;
    }
    final old = _photo;
    _photo = result.photo;
    // Same framing as the snapshot, so its tracked face is a good fallback.
    face = result.face ?? face?.withWeight(1);
    old.dispose();
    if (mask != null) {
      mask!.dispose();
      mask = null;
      if (_settings.background.needsMask) await _segment();
      if (mask == null) _settings = _settings.copyWith(background: backgroundOptions.first);
    }
    if (!_disposed) notifyListeners();
  }

  void clearMessage() => message = null;

  @override
  void dispose() {
    _disposed = true;
    mask?.dispose();
    customBackground?.dispose();
    _photo.dispose();
    super.dispose();
  }
}
