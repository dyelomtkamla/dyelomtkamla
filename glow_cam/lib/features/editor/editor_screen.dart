import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../background/background_option.dart';
import '../beauty/beauty_settings.dart';
import '../beauty/face_geometry.dart';
import '../export/export_service.dart';
import '../filters/filter_preset.dart';
import '../pro/paywall_screen.dart';
import '../pro/pro_service.dart';
import 'edit_settings.dart';
import 'editor_controller.dart';
import 'photo_loader.dart';
import 'widgets/option_strip.dart';

enum _Tab { filters, beauty, background, adjust }

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.photo,
    this.face,
    this.initialPreset,
    this.beauty = BeautySettings.natural,
    this.fullQuality,
  });

  final LoadedPhoto photo;
  final FaceGeometry? face;
  final FilterPreset? initialPreset;
  final BeautySettings beauty;

  /// Full-resolution version of [photo] that replaces it when ready.
  final Future<PhotoWithFace?>? fullQuality;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorController _c = EditorController(
    widget.photo,
    face: widget.face,
    initialPreset: widget.initialPreset,
    beauty: widget.beauty,
    fullQuality: widget.fullQuality,
  );
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
      final png = await ExportService.render(_c.painter(), filter: _c.filter());
      if (share) {
        await ExportService.share(png);
      } else {
        final ok = await ExportService.saveToGallery(png);
        messenger.showSnackBar(
          SnackBar(
            content: Text(ok ? 'تم حفظ الصورة في المعرض ✨' : 'يرجى السماح بالوصول إلى الصور من الإعدادات'),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  bool get _busy => _exporting || _c.upgrading;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: _c, builder: (context, _) => _buildScaffold(context));
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('تعديل الصورة'),
        actions: [
          IconButton(
            tooltip: 'مشاركة',
            icon: const Icon(Icons.ios_share),
            onPressed: _busy ? null : () => _export(share: true),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilledButton.icon(
              onPressed: _busy ? null : () => _export(share: false),
              icon: _busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download),
              label: const Text('حفظ'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildPreview()),
          _buildPanel(),
          _buildTabs(),
        ],
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
                    RepaintBoundary(child: _buildPhoto()),
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
                    if (_c.upgrading)
                      const PositionedDirectional(
                        bottom: 12,
                        start: 12,
                        child: Chip(
                          avatar: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          label: Text('جاري تحسين الجودة…'),
                        ),
                      ),
                    if (_showOriginal)
                      const PositionedDirectional(top: 12, start: 12, child: Chip(label: Text('الأصل'))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    final paint = CustomPaint(painter: _c.painter(original: _showOriginal));
    final filter = _showOriginal ? null : _c.filter();
    return filter == null ? paint : ImageFiltered(imageFilter: filter, child: paint);
  }

  Widget _buildBeautyPanel() {
    final b = _c.beauty;
    return Column(
      children: [
        if (_c.face == null)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'لم يتم العثور على وجه — سيتم تطبيق النعومة والإشراق فقط',
              style: TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ),
        LabeledSlider(
          icon: Icons.face_retouching_natural,
          label: 'نعومة البشرة',
          value: b.smooth,
          onChanged: (v) => _c.updateBeauty((b) => b.copyWith(smooth: v)),
        ),
        LabeledSlider(
          icon: Icons.wb_sunny_outlined,
          label: 'إشراقة',
          value: b.brighten,
          onChanged: (v) => _c.updateBeauty((b) => b.copyWith(brighten: v)),
        ),
        LabeledSlider(
          icon: Icons.remove_red_eye_outlined,
          label: 'تكبير العيون',
          value: b.eyes,
          onChanged: (v) => _c.updateBeauty((b) => b.copyWith(eyes: v)),
        ),
        LabeledSlider(
          icon: Icons.face,
          label: 'نحت الوجه',
          value: b.slim,
          onChanged: (v) => _c.updateBeauty((b) => b.copyWith(slim: v)),
        ),
        LabeledSlider(
          icon: Icons.favorite_border,
          label: 'خدود وردية',
          value: b.blush,
          onChanged: (v) => _c.updateBeauty((b) => b.copyWith(blush: v)),
        ),
        LabeledSlider(
          icon: Icons.mood,
          label: 'لون الشفايف',
          value: b.lips,
          onChanged: (v) => _c.updateBeauty((b) => b.copyWith(lips: v)),
        ),
      ],
    );
  }

  Widget _buildPanel() {
    final s = _c.settings;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.3),
      child: SingleChildScrollView(child: _panelContent(s)),
    );
  }

  Widget _panelContent(EditSettings s) {
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
        _Tab.beauty => _buildBeautyPanel(),
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
      _Tab.beauty: (Icons.face_retouching_natural, 'تجميل'),
      _Tab.background: (Icons.wallpaper, 'الخلفية'),
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
        destinations: [for (final t in tabs.values) NavigationDestination(icon: Icon(t.$1), label: t.$2)],
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
