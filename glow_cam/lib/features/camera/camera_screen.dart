import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../beauty/beauty_settings.dart';
import '../beauty/beauty_shader.dart';
import '../beauty/face_geometry.dart';
import '../beauty/face_tracker.dart';
import '../editor/edit_settings.dart';
import '../editor/editor_controller.dart';
import '../editor/editor_screen.dart';
import '../editor/photo_loader.dart';
import '../editor/widgets/option_strip.dart';
import '../filters/filter_preset.dart';
import '../pro/paywall_screen.dart';
import '../pro/pro_service.dart';

/// Home screen: full-screen selfie camera with live GPU beauty and filters.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  final _previewKey = GlobalKey();
  final _tracker = FaceTracker();

  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = 0;
  String? _error;
  bool _busy = false;
  FlashMode _flash = FlashMode.off;
  FilterPreset _preset = filterPresets.first;
  BeautySettings _beauty = BeautySettings.natural;
  Size _box = Size.zero;

  BeautyShader? get _shader => BeautyShader.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameras();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera(_controller);
    _tracker.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      if (state == AppLifecycleState.resumed && _cameras.isNotEmpty && c == null) {
        _startCamera(_cameras[_cameraIndex]);
      }
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      _stopCamera(c);
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      _startCamera(_cameras[_cameraIndex]);
    }
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'لا توجد كاميرا متاحة على هذا الجهاز');
        return;
      }
      final front = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
      _cameraIndex = front >= 0 ? front : 0;
      await _startCamera(_cameras[_cameraIndex]);
    } on CameraException catch (e) {
      setState(() => _error = _describe(e));
    }
  }

  Future<void> _startCamera(CameraDescription description) async {
    final previous = _controller;
    final controller = CameraController(
      description,
      // 720p keeps the live face-tracking stream light; the saved photo comes
      // from a full-resolution still.
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
    _controller = controller;
    _tracker.reset();
    await _stopCamera(previous);
    try {
      await controller.initialize();
      await controller.setFlashMode(_flash);
      if (_shader != null) {
        await controller.startImageStream((image) => _tracker.processFrame(image, description));
      }
      _error = null;
    } on CameraException catch (e) {
      _error = _describe(e);
    }
    if (mounted) setState(() {});
  }

  Future<void> _stopCamera(CameraController? c) async {
    if (c == null) return;
    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
    } catch (_) {}
    await c.dispose();
  }

  String _describe(CameraException e) => switch (e.code) {
    'CameraAccessDenied' ||
    'CameraAccessDeniedWithoutPrompt' ||
    'CameraAccessRestricted' => 'يرجى السماح باستخدام الكاميرا من إعدادات الجهاز',
    _ => 'تعذر تشغيل الكاميرا (${e.code})',
  };

  bool get _isFront =>
      _cameras.isNotEmpty && _cameras[_cameraIndex].lensDirection == CameraLensDirection.front;

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startCamera(_cameras[_cameraIndex]);
  }

  Future<void> _toggleFlash() async {
    _flash = _flash == FlashMode.off ? FlashMode.always : FlashMode.off;
    await _controller?.setFlashMode(_flash);
    setState(() {});
  }

  /// Instant capture: freeze the current preview frame right away and open
  /// the editor, while the full-resolution still is taken in the background.
  Future<void> _capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture || _busy) return;
    setState(() => _busy = true);
    try {
      final face = _tracker.face.value?.withWeight(1);
      final snapshot = await _snapshot();
      final still = _takeStill(c, _box.aspectRatio, mirror: _isFront);

      if (snapshot != null) {
        final photo = await PhotoLoader.fromImage(snapshot);
        await _openEditor(photo, face: face, fullQuality: still);
      } else {
        final result = await still;
        if (result == null) {
          _snack('تعذر التقاط الصورة');
          return;
        }
        await _openEditor(result.photo, face: result.face ?? face);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The raw (unfiltered) preview exactly as framed on screen.
  Future<ui.Image?> _snapshot() async {
    try {
      final boundary = _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: MediaQuery.devicePixelRatioOf(context));
      if (await _isBlank(image)) {
        image.dispose();
        return null;
      }
      return image;
    } catch (e) {
      debugPrint('Preview snapshot failed: $e');
      return null;
    }
  }

  /// Some devices can't read back the camera texture; detect a black frame.
  static Future<bool> _isBlank(ui.Image image) async {
    final data = await image.toByteData();
    if (data == null) return true;
    var maxValue = 0;
    for (var gy = 1; gy < 8; gy++) {
      for (var gx = 1; gx < 8; gx++) {
        final x = image.width * gx ~/ 8, y = image.height * gy ~/ 8;
        final i = (y * image.width + x) * 4;
        for (var k = 0; k < 3; k++) {
          final v = data.getUint8(i + k);
          if (v > maxValue) maxValue = v;
        }
      }
    }
    return maxValue < 10;
  }

  static Future<PhotoWithFace?> _takeStill(CameraController c, double aspect, {required bool mirror}) async {
    try {
      final file = await c.takePicture();
      final photo = await PhotoLoader.load(file.path, mirror: mirror, cropAspect: aspect);
      final face = await StillFaceDetector.detect(await photo.file(), photo.size);
      return (photo: photo, face: face);
    } catch (e) {
      debugPrint('Still capture failed: $e');
      return null;
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      final photo = await PhotoLoader.load(picked.path);
      final face = await StillFaceDetector.detect(await photo.file(), photo.size);
      await _openEditor(photo, face: face);
    } catch (e) {
      _snack('تعذر فتح الصورة: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openEditor(
    LoadedPhoto photo, {
    FaceGeometry? face,
    Future<PhotoWithFace?>? fullQuality,
  }) async {
    if (!mounted) {
      photo.dispose();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(
          photo: photo,
          face: face,
          initialPreset: _preset,
          beauty: _beauty,
          fullQuality: fullQuality,
        ),
      ),
    );
  }

  void _snack(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _openBeautySheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.75),
      barrierColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          void change(BeautySettings b) {
            setState(() => _beauty = b);
            setSheet(() {});
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('بدون'),
                        selected: _beauty.isOff,
                        onSelected: (_) => change(BeautySettings.off),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('طبيعي ✨'),
                        selected: _beauty == BeautySettings.natural,
                        onSelected: (_) => change(BeautySettings.natural),
                      ),
                    ],
                  ),
                  LabeledSlider(
                    icon: Icons.face_retouching_natural,
                    label: 'نعومة',
                    value: _beauty.smooth,
                    onChanged: (v) => change(_beauty.copyWith(smooth: v)),
                  ),
                  LabeledSlider(
                    icon: Icons.remove_red_eye_outlined,
                    label: 'العيون',
                    value: _beauty.eyes,
                    onChanged: (v) => change(_beauty.copyWith(eyes: v)),
                  ),
                  LabeledSlider(
                    icon: Icons.face,
                    label: 'نحت الوجه',
                    value: _beauty.slim,
                    onChanged: (v) => change(_beauty.copyWith(slim: v)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ProScope.of(context).isPro;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreview(),
          if (_busy)
            const ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(isPro),
                const Spacer(),
                Text(
                  _preset.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                  ),
                ),
                const SizedBox(height: 8),
                _buildFilterCarousel(),
                _buildControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final c = _controller;
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography, size: 56, color: Colors.white54),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _initCameras, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }
    if (c == null || !c.value.isInitialized || c.value.previewSize == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final box = constraints.biggest;
        final ps = c.value.previewSize!;
        // previewSize is reported in sensor (landscape) orientation.
        final upright = ps.width > ps.height ? Size(ps.height, ps.width) : ps;
        _box = box;
        _tracker
          ..screenBox = box
          ..previewSize = upright;

        final raw = RepaintBoundary(
          key: _previewKey,
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(width: upright.width, height: upright.height, child: CameraPreview(c)),
            ),
          ),
        );

        final shader = _shader;
        if (shader == null) {
          return ColorFiltered(colorFilter: ColorFilter.matrix(_preset.matrix), child: raw);
        }
        final look = EditSettings(preset: _preset);
        return ValueListenableBuilder<FaceGeometry?>(
          valueListenable: _tracker.face,
          child: raw,
          builder: (context, face, child) => ImageFiltered(
            imageFilter: shader.filter(look: look, beauty: _beauty, face: face),
            child: child!,
          ),
        );
      },
    );
  }

  Widget _buildTopBar(bool isPro) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      children: [
        _RoundButton(
          icon: _flash == FlashMode.off ? Icons.flash_off : Icons.flash_on,
          tooltip: 'الفلاش',
          onPressed: _toggleFlash,
        ),
        const SizedBox(width: 8),
        if (_shader != null)
          _RoundButton(
            icon: _beauty.isOff ? Icons.face_outlined : Icons.face_retouching_natural,
            tooltip: 'تجميل',
            onPressed: _openBeautySheet,
          ),
        const Spacer(),
        if (!isPro)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black,
            ),
            onPressed: () => PaywallScreen.show(context),
            icon: const Icon(Icons.workspace_premium, size: 18),
            label: const Text('Pro'),
          ),
      ],
    ),
  );

  Widget _buildFilterCarousel() => SizedBox(
    height: 64,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filterPresets.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, i) {
        final p = filterPresets[i];
        final selected = p.id == _preset.id;
        return Semantics(
          button: true,
          selected: selected,
          label: p.name,
          child: GestureDetector(
            onTap: () => setState(() => _preset = p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.brandGradient,
                border: Border.all(color: Colors.white, width: selected ? 3 : 0),
              ),
              child: Center(
                child: p.isPro
                    ? const Icon(Icons.workspace_premium, color: Colors.white)
                    : Text(
                        p.name.characters.first,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _buildControls() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundButton(icon: Icons.photo_library, tooltip: 'المعرض', onPressed: _pickFromGallery),
        Semantics(
          button: true,
          label: 'التقاط صورة',
          child: GestureDetector(
            onTap: _capture,
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5),
              ),
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: DecoratedBox(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
                ),
              ),
            ),
          ),
        ),
        _RoundButton(icon: Icons.cameraswitch, tooltip: 'تبديل الكاميرا', onPressed: _switchCamera),
      ],
    ),
  );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: tooltip,
    iconSize: 26,
    style: IconButton.styleFrom(
      backgroundColor: Colors.black38,
      foregroundColor: Colors.white,
      minimumSize: const Size(52, 52),
    ),
    icon: Icon(icon),
    onPressed: onPressed,
  );
}
