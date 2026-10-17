import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:glow_cam/features/background/background_option.dart';
import 'package:glow_cam/features/editor/edit_settings.dart';
import 'package:glow_cam/features/editor/photo_painter.dart';
import 'package:glow_cam/features/export/export_service.dart';
import 'package:glow_cam/features/filters/filter_preset.dart';

Future<ui.Image> solid(int w, int h, List<int> rgba) async {
  final px = Uint8List(w * h * 4);
  for (var i = 0; i < px.length; i += 4) {
    px.setRange(i, i + 4, rgba);
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(px);
  final desc = ui.ImageDescriptor.raw(buffer, width: w, height: h, pixelFormat: ui.PixelFormat.rgba8888);
  final frame = await (await desc.instantiateCodec()).getNextFrame();
  return frame.image;
}

void main() {
  testWidgets('renders every filter and background at full resolution', (tester) async {
    await tester.runAsync(() async {
      final photo = await solid(64, 96, [180, 140, 120, 255]);
      final mask = await solid(64, 96, [255, 255, 255, 255]);
      final custom = await solid(32, 32, [0, 0, 255, 255]);

      for (final preset in filterPresets) {
        for (final bg in backgroundOptions) {
          final png = await ExportService.render(PhotoPainter(
            photo: photo,
            mask: mask,
            customBackground: custom,
            settings: EditSettings(preset: preset, background: bg, smoothing: 0.5, glow: 0.3),
          ));
          // PNG signature.
          expect(png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47], reason: '${preset.id}/${bg.id}');
        }
      }
    });
  });

  testWidgets('B&W filter outputs gray pixels', (tester) async {
    await tester.runAsync(() async {
      final photo = await solid(8, 8, [200, 60, 30, 255]);
      final painter = PhotoPainter(
        photo: photo,
        settings: EditSettings(preset: filterPresets.firstWhere((p) => p.id == 'bw')),
      );
      final recorder = ui.PictureRecorder();
      painter.paint(ui.Canvas(recorder), const ui.Size(8, 8));
      final image = await recorder.endRecording().toImage(8, 8);
      final data = (await image.toByteData())!;
      // Center pixel, unaffected by vignette.
      final i = (4 * 8 + 4) * 4;
      final r = data.getUint8(i), g = data.getUint8(i + 1), b = data.getUint8(i + 2);
      expect((r - g).abs() <= 2 && (g - b).abs() <= 2, isTrue, reason: '$r,$g,$b');
    });
  });
}
