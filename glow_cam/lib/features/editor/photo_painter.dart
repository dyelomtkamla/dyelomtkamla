import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../background/background_option.dart';
import 'edit_settings.dart';

/// Renders the edited photo. All blur radii are relative to the output size,
/// so the on-screen preview and the full-resolution export look identical.
class PhotoPainter extends CustomPainter {
  PhotoPainter({
    required this.photo,
    required this.settings,
    this.mask,
    this.customBackground,
    this.showOriginal = false,
    this.lookInShader = false,
    this.smoothing = 0,
  });

  final ui.Image photo;
  final ui.Image? mask;
  final ui.Image? customBackground;
  final EditSettings settings;
  final bool showOriginal;

  /// When true, the GPU beauty shader applies the color grade, glow, wash and
  /// vignette, so this painter only composites the photo and background.
  final bool lookInShader;

  /// Fallback skin smoothing for devices without shader filters.
  final double smoothing;

  static ui.ImageFilter _blur(double sigma) =>
      ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.clamp);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final src = Rect.fromLTWH(0, 0, photo.width.toDouble(), photo.height.toDouble());
    canvas.clipRect(rect);

    if (showOriginal) {
      canvas.drawImageRect(photo, src, rect, Paint()..filterQuality = FilterQuality.high);
      return;
    }

    if (lookInShader) {
      _paintComposite(canvas, rect, src, size.width);
      return;
    }

    final s = settings;
    // Everything inside this layer gets the color grade.
    canvas.saveLayer(rect, Paint()..colorFilter = ColorFilter.matrix(s.colorMatrix));
    _paintComposite(canvas, rect, src, size.width);
    if (s.totalGlow > 0) {
      canvas.saveLayer(rect, Paint()..blendMode = BlendMode.screen);
      canvas.drawImageRect(
        photo,
        src,
        rect,
        Paint()
          ..imageFilter = _blur(size.width * 0.025)
          ..color = Color.fromRGBO(0, 0, 0, s.totalGlow * 0.45),
      );
      canvas.restore();
    }
    canvas.restore();

    final wash = s.preset.wash;
    if (wash != null && s.washOpacity > 0) {
      canvas.saveLayer(rect, Paint()..blendMode = BlendMode.softLight);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [
            for (final c in wash) c.withValues(alpha: s.washOpacity),
          ]),
      );
      canvas.restore();
    }

    if (s.totalVignette > 0) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            rect.center,
            rect.longestSide * 0.72,
            [Colors.transparent, Color.fromRGBO(0, 0, 0, s.totalVignette * 0.75)],
            [0.45, 1],
          ),
      );
    }
  }

  /// Photo, optionally cut out and placed on the chosen background.
  void _paintComposite(Canvas canvas, Rect rect, Rect src, double w) {
    final bg = settings.background;
    final m = mask;
    if (!bg.needsMask || m == null) {
      _paintPerson(canvas, rect, src, w);
      return;
    }
    _paintBackdrop(canvas, rect, src, bg, w);
    // Person cut-out on its own layer, then keep only where the mask is.
    canvas.saveLayer(rect, Paint());
    _paintPerson(canvas, rect, src, w);
    canvas.drawImageRect(
      m,
      Rect.fromLTWH(0, 0, m.width.toDouble(), m.height.toDouble()),
      rect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..filterQuality = FilterQuality.medium
        ..imageFilter = _blur(w * 0.0025),
    );
    canvas.restore();
  }

  void _paintPerson(Canvas canvas, Rect rect, Rect src, double w) {
    canvas.drawImageRect(photo, src, rect, Paint()..filterQuality = FilterQuality.high);
    if (!lookInShader && smoothing > 0) {
      // "Soft skin" fallback: a blurred copy blended with `lighten` evens out
      // small dark details while keeping highlights and edges.
      canvas.drawImageRect(
        photo,
        src,
        rect,
        Paint()
          ..blendMode = BlendMode.lighten
          ..imageFilter = _blur(w * 0.006)
          ..color = Color.fromRGBO(0, 0, 0, smoothing * 0.8),
      );
    }
  }

  void _paintBackdrop(Canvas canvas, Rect rect, Rect src, BackgroundOption bg, double w) {
    switch (bg.kind) {
      case BackgroundKind.original:
        break;
      case BackgroundKind.blur:
        canvas.drawImageRect(photo, src, rect, Paint()..imageFilter = _blur(w * 0.03));
      case BackgroundKind.color:
      case BackgroundKind.gradient:
        canvas.drawRect(rect, bg.fillPaint(rect));
      case BackgroundKind.image:
        final custom = customBackground;
        if (custom == null) {
          canvas.drawRect(rect, Paint()..color = Colors.black);
        } else {
          canvas.drawImageRect(
            custom,
            _coverSrc(custom, rect.size),
            rect,
            Paint()..filterQuality = FilterQuality.high,
          );
        }
    }
  }

  /// Source rect that center-crops [image] to fill [target] (BoxFit.cover).
  static Rect _coverSrc(ui.Image image, Size target) {
    final iw = image.width.toDouble(), ih = image.height.toDouble();
    final scale = (target.width / iw) > (target.height / ih) ? target.width / iw : target.height / ih;
    final sw = target.width / scale, sh = target.height / scale;
    return Rect.fromLTWH((iw - sw) / 2, (ih - sh) / 2, sw, sh);
  }

  @override
  bool shouldRepaint(PhotoPainter old) =>
      old.photo != photo ||
      old.mask != mask ||
      old.customBackground != customBackground ||
      old.settings != settings ||
      old.showOriginal != showOriginal ||
      old.lookInShader != lookInShader ||
      old.smoothing != smoothing;
}
