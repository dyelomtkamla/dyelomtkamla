import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../editor/photo_painter.dart';

class ExportService {
  static const album = 'GlowCam';

  /// Renders [painter] at the photo's native resolution and encodes PNG.
  static Future<Uint8List> render(PhotoPainter painter) async {
    final w = painter.photo.width, h = painter.photo.height;
    final recorder = ui.PictureRecorder();
    painter.paint(ui.Canvas(recorder), ui.Size(w.toDouble(), h.toDouble()));
    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    picture.dispose();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  /// Returns false if the user denied gallery access.
  static Future<bool> saveToGallery(Uint8List png) async {
    if (!await Gal.hasAccess(toAlbum: true) && !await Gal.requestAccess(toAlbum: true)) {
      return false;
    }
    await Gal.putImageBytes(png, album: album, name: _name());
    return true;
  }

  static Future<void> share(Uint8List png) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_name()}.png');
    await file.writeAsBytes(png, flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  static String _name() => 'glowcam_${DateTime.now().millisecondsSinceEpoch}';
}
