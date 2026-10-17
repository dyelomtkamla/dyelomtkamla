import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../editor/editor_screen.dart';
import '../editor/photo_loader.dart';
import '../filters/filter_preset.dart';
import '../pro/paywall_screen.dart';
import '../pro/pro_service.dart';

/// Home screen: full-screen selfie camera with a live filter carousel.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = 0;
  String? _error;
  bool _busy = false;
  FlashMode _flash = FlashMode.off;
  FilterPreset _preset = filterPresets.first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameras();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      c.dispose();
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
      ResolutionPreset.veryHigh,
      enableAudio: false,
    );
    _controller = controller;
    await previous?.dispose();
    try {
      await controller.initialize();
      await controller.setFlashMode(_flash);
      _error = null;
    } on CameraException catch (e) {
      _error = _describe(e);
    }
    if (mounted) setState(() {});
  }

  String _describe(CameraException e) => switch (e.code) {
        'CameraAccessDenied' ||
        'CameraAccessDeniedWithoutPrompt' ||
        'CameraAccessRestricted' =>
          'يرجى السماح باستخدام الكاميرا من إعدادات الجهاز',
        _ => 'تعذر تشغيل الكاميرا (${e.code})',
      };

  bool get _isFront => _cameras.isNotEmpty &&
      _cameras[_cameraIndex].lensDirection == CameraLensDirection.front;

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

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture || _busy) return;
    setState(() => _busy = true);
    try {
      final file = await c.takePicture();
      await _openEditor(file.path, mirror: _isFront);
    } on CameraException catch (e) {
      _snack(_describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _busy = true);
    try {
      await _openEditor(picked.path);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openEditor(String path, {bool mirror = false}) async {
    try {
      final photo = await PhotoLoader.load(path, mirror: mirror);
      if (!mounted) {
        photo.dispose();
        return;
      }
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => EditorScreen(photo: photo, initialPreset: _preset),
      ));
    } catch (e) {
      _snack('تعذر فتح الصورة: $e');
    }
  }

  void _snack(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ProScope.of(context).isPro;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPreview(),
          if (_busy) const ColoredBox(color: Colors.black38, child: Center(child: CircularProgressIndicator())),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(isPro),
                const Spacer(),
                Text(_preset.name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black)])),
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
    if (c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    // Fill the screen (cover) while keeping the camera's aspect ratio.
    final size = MediaQuery.sizeOf(context);
    var scale = size.aspectRatio * c.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;
    return ClipRect(
      child: Transform.scale(
        scale: scale,
        child: Center(
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix(_preset.matrix),
            child: CameraPreview(c),
          ),
        ),
      ),
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
            const Spacer(),
            if (!isPro)
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black),
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
                        : Text(p.name.characters.first,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
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
