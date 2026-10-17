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
  });

  final ui.Image photo;
  final ui.Image? mask;
  final ui.Image? customBackground;
  final EditSettings settings;
  final bool showOriginal;

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

    final w = size.width;
    final s = settings;
    final bg = s.background;
    final useMask = bg.needsMask && mask != null;

    // Everything inside this layer gets the color grade.
    canvas.saveLayer(rect, Paint()..colorFilter = ColorFilter.matrix(s.colorMatrix));

    if (useMask) {
      _paintBackdrop(canvas, rect, src, bg, w);
      // Person cut-out on its own layer, then keep only where the mask is.
      canvas.saveLayer(rect, Paint());
      _paintPerson(canvas, rect, src, w);
      final maskSrc = Rect.fromLTWH(0, 0, mask!.width.toDouble(), mask!.height.toDouble());
      canvas.drawImageRect(
        mask!,
        maskSrc,
        rect,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..filterQuality = FilterQuality.medium
          ..imageFilter = _blur(w * 0.0025),
      );
      canvas.restore();
    } else {
      _paintPerson(canvas, rect, src, w);
    }

    if (s.totalGlow > 0) {
      canvas.saveLayer(rect, Paint()..blendMode = BlendMode.screen);
      canvas.drawImageRect(
        photo,
        src,
        rect,
        Paint()
          ..imageFilter = _blur(w * 0.025)
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
          ..shader = ui.Gradient.linear(
            rect.topLeft,
            rect.bottomRight,
            [for (final c in wash) c.withValues(alpha: s.washOpacity)],
          ),
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

  void _paintPerson(Canvas canvas, Rect rect, Rect src, double w) {
    canvas.drawImageRect(photo, src, rect, Paint()..filterQuality = FilterQuality.high);
    if (settings.smoothing > 0) {
      // "Soft skin": a blurred copy blended with `lighten` evens out small dark
      // details (pores, blemishes) while keeping highlights and edges.
      canvas.drawImageRect(
        photo,
        src,
        rect,
        Paint()
          ..blendMode = BlendMode.lighten
          ..imageFilter = _blur(w * 0.006)
          ..color = Color.fromRGBO(0, 0, 0, settings.smoothing * 0.8),
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
      old.showOriginal != showOriginal;
}
