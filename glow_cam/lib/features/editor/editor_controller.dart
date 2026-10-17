import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../background/background_option.dart';
import '../background/segmentation_service.dart';
import '../filters/filter_preset.dart';
import 'edit_settings.dart';
import 'photo_loader.dart';

class EditorController extends ChangeNotifier {
  EditorController(this.photo, {FilterPreset? initialPreset})
      : _settings = EditSettings(preset: initialPreset);

  final LoadedPhoto photo;

  EditSettings _settings;
  EditSettings get settings => _settings;

  ui.Image? mask;
  ui.Image? customBackground;
  bool segmenting = false;
  String? message;

  void update(EditSettings Function(EditSettings s) change) {
    _settings = change(_settings);
    notifyListeners();
  }

  void selectPreset(FilterPreset p) => update((s) => s.copyWith(preset: p));

  /// Runs person segmentation the first time a background is chosen.
  Future<void> selectBackground(BackgroundOption option) async {
    if (option.needsMask && mask == null) {
      segmenting = true;
      message = null;
      notifyListeners();
      try {
        mask = await SegmentationService.personMask(photo.path);
      } on NoPersonFoundException {
        message = 'لم نتعرف على شخص في الصورة. جرّب صورة سيلفي أوضح.';
      } catch (e) {
        message = 'تعذر فصل الخلفية: $e';
      } finally {
        segmenting = false;
      }
      if (mask == null) {
        notifyListeners();
        return;
      }
    }
    update((s) => s.copyWith(background: option));
  }

  Future<void> setCustomBackground(String path) async {
    final image = await PhotoLoader.decode(
      await File(path).readAsBytes(),
      targetWidth: PhotoLoader.maxSide,
    );
    customBackground?.dispose();
    customBackground = image;
    await selectBackground(backgroundOptions.firstWhere((b) => b.kind == BackgroundKind.image));
  }

  void clearMessage() => message = null;

  @override
  void dispose() {
    mask?.dispose();
    customBackground?.dispose();
    photo.dispose();
    super.dispose();
  }
}
