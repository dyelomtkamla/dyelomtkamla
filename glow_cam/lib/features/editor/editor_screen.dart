import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../background/background_option.dart';
import '../export/export_service.dart';
import '../filters/filter_preset.dart';
import '../pro/paywall_screen.dart';
import '../pro/pro_service.dart';
import 'editor_controller.dart';
import 'photo_loader.dart';
import 'photo_painter.dart';
import 'widgets/option_strip.dart';

enum _Tab { filters, background, beauty, adjust }

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.photo, this.initialPreset});

  final LoadedPhoto photo;
  final FilterPreset? initialPreset;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorController _c =
      EditorController(widget.photo, initialPreset: widget.initialPreset);
  _Tab _tab = _Tab.filters;
  bool _showOriginal = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    final msg = _c.message;
    if (msg != null) {
      _c.clearMessage();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  PhotoPainter _painter({bool original = false}) => PhotoPainter(
        photo: _c.photo.image,
        settings: _c.settings,
        mask: _c.mask,
        customBackground: _c.customBackground,
        showOriginal: original,
      );

  Future<bool> _ensureProIfNeeded() async {
    final pro = ProScope.of(context);
    if (!_c.settings.usesPro || pro.isPro) return true;
    return PaywallScreen.show(context);
  }

  Future<void> _export({required bool share}) async {
    if (_exporting || !await _ensureProIfNeeded() || !mounted) return;
    setState(() => _exporting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final png = await ExportService.render(_painter());
      if (share) {
        await ExportService.share(png);
      } else {
        final ok = await ExportService.saveToGallery(png);
        messenger.showSnackBar(SnackBar(
          content: Text(ok ? 'تم حفظ الصورة في المعرض ✨' : 'يرجى السماح بالوصول إلى الصور من الإعدادات'),
        ));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('تعديل الصورة'),
        actions: [
          IconButton(
            tooltip: 'مشاركة',
            icon: const Icon(Icons.ios_share),
            onPressed: _exporting ? null : () => _export(share: true),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilledButton.icon(
              onPressed: _exporting ? null : () => _export(share: false),
              icon: _exporting
                  ? const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download),
              label: const Text('حفظ'),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) => Column(
          children: [
            Expanded(child: _buildPreview()),
            _buildPanel(),
            _buildTabs(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final img = _c.photo.image;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: AspectRatio(
          aspectRatio: img.width / img.height,
          child: Semantics(
            label: 'معاينة الصورة، اضغط مطولاً لعرض الأصل',
            child: GestureDetector(
              onLongPressStart: (_) => setState(() => _showOriginal = true),
              onLongPressEnd: (_) => setState(() => _showOriginal = false),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(child: CustomPaint(painter: _painter(original: _showOriginal))),
                    if (_c.segmenting)
                      const ColoredBox(
                        color: Colors.black45,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('جاري فصل الخلفية…'),
                            ],
                          ),
                        ),
                      ),
                    if (_showOriginal)
                      const PositionedDirectional(
                        top: 12,
                        start: 12,
                        child: Chip(label: Text('الأصل')),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    final s = _c.settings;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: switch (_tab) {
        _Tab.filters => Column(
            children: [
              OptionStrip(
                itemCount: filterPresets.length,
                itemBuilder: (context, i) {
                  final p = filterPresets[i];
                  return OptionTile(
                    label: p.name,
                    isPro: p.isPro,
                    selected: s.preset.id == p.id,
                    onTap: () => _c.selectPreset(p),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.matrix(p.matrix),
                      child: RawImage(image: _c.photo.thumbnail, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
              if (s.preset.id != 'none')
                LabeledSlider(
                  icon: Icons.tune,
                  label: 'الشدة',
                  value: s.intensity,
                  onChanged: (v) => _c.update((s) => s.copyWith(intensity: v)),
                ),
            ],
          ),
        _Tab.background => OptionStrip(
            itemCount: backgroundOptions.length,
            itemBuilder: (context, i) {
              final b = backgroundOptions[i];
              return OptionTile(
                label: b.name,
                isPro: b.isPro,
                selected: s.background.id == b.id,
                onTap: _c.segmenting ? () {} : () => _onBackgroundTap(b),
                child: _BackgroundSwatch(option: b, photo: _c.photo),
              );
            },
          ),
        _Tab.beauty => Column(
            children: [
              LabeledSlider(
                icon: Icons.face_retouching_natural,
                label: 'نعومة البشرة',
                value: s.smoothing,
                onChanged: (v) => _c.update((s) => s.copyWith(smoothing: v)),
              ),
              LabeledSlider(
                icon: Icons.auto_awesome,
                label: 'توهج',
                value: s.glow,
                onChanged: (v) => _c.update((s) => s.copyWith(glow: v)),
              ),
              LabeledSlider(
                icon: Icons.vignette,
                label: 'إطار داكن',
                value: s.vignette,
                onChanged: (v) => _c.update((s) => s.copyWith(vignette: v)),
              ),
            ],
          ),
        _Tab.adjust => Column(
            children: [
              LabeledSlider(
                icon: Icons.light_mode,
                label: 'الإضاءة',
                min: -1,
                value: s.brightness,
                onChanged: (v) => _c.update((s) => s.copyWith(brightness: v)),
              ),
              LabeledSlider(
                icon: Icons.contrast,
                label: 'التباين',
                min: -1,
                value: s.contrast,
                onChanged: (v) => _c.update((s) => s.copyWith(contrast: v)),
              ),
              LabeledSlider(
                icon: Icons.palette,
                label: 'التشبع',
                min: -1,
                value: s.saturation,
                onChanged: (v) => _c.update((s) => s.copyWith(saturation: v)),
              ),
              LabeledSlider(
                icon: Icons.thermostat,
                label: 'الدفء',
                min: -1,
                value: s.warmth,
                onChanged: (v) => _c.update((s) => s.copyWith(warmth: v)),
              ),
            ],
          ),
      },
    );
  }

  Future<void> _onBackgroundTap(BackgroundOption b) async {
    if (b.kind == BackgroundKind.image) {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      await _c.setCustomBackground(picked.path);
    } else {
      await _c.selectBackground(b);
    }
  }

  Widget _buildTabs() {
    const tabs = {
      _Tab.filters: (Icons.filter_vintage, 'فلاتر'),
      _Tab.background: (Icons.wallpaper, 'الخلفية'),
      _Tab.beauty: (Icons.face_retouching_natural, 'تجميل'),
      _Tab.adjust: (Icons.tune, 'ضبط'),
    };
    return SafeArea(
      top: false,
      child: NavigationBar(
        height: 64,
        backgroundColor: Colors.black,
        indicatorColor: AppTheme.brand.withValues(alpha: 0.35),
        selectedIndex: _tab.index,
        onDestinationSelected: (i) => setState(() => _tab = _Tab.values[i]),
        destinations: [
          for (final t in tabs.values) NavigationDestination(icon: Icon(t.$1), label: t.$2),
        ],
      ),
    );
  }
}

class _BackgroundSwatch extends StatelessWidget {
  const _BackgroundSwatch({required this.option, required this.photo});

  final BackgroundOption option;
  final LoadedPhoto photo;

  @override
  Widget build(BuildContext context) => switch (option.kind) {
        BackgroundKind.original => RawImage(image: photo.thumbnail, fit: BoxFit.cover),
        BackgroundKind.blur => ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: RawImage(image: photo.thumbnail, fit: BoxFit.cover),
          ),
        BackgroundKind.image => const ColoredBox(
            color: Colors.white12,
            child: Icon(Icons.add_photo_alternate, color: Colors.white),
          ),
        _ => CustomPaint(painter: _SwatchPainter(option)),
      };
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.option);
  final BackgroundOption option;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, option.fillPaint(rect));
  }

  @override
  bool shouldRepaint(_SwatchPainter old) => old.option != option;
}
