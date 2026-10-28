import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/hostel_colors.dart';
import '../../../../core/utils/camera_permission.dart';
import '../../../../core/utils/location_permission.dart';

/// Returns the captured path, or null on cancellation. Attendance capture
/// additionally requires location permission, enabled GPS and a location fix.
class FaceCaptureScreen extends StatefulWidget {
  const FaceCaptureScreen({
    super.key,
    this.lensDirection = CameraLensDirection.front,
    this.hint = 'Fit your face inside the oval',
    this.requireLocation = false,
  });
  final CameraLensDirection lensDirection;
  final String hint;
  final bool requireLocation;
  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0, _generation = 0;
  bool _initializing = true, _capturing = false, _locationReady = false;
  String? _error;
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initialize();
    });
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _foreground = false;
      if (_controller != null) {
        _generation++;
        final old = _controller;
        _controller = null;
        unawaited(old?.dispose());
        if (mounted) {
          setState(() {
            _initializing = false;
            _locationReady = false;
          });
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      _foreground = true;
      if (!_initializing) _initialize();
    }
  }

  Future<bool> _checkAccess() async {
    if (!await ensureCameraPermission(context) || !mounted) return false;
    if (widget.requireLocation) {
      if (mounted) setState(() => _locationReady = false);
      if (!await ensureLocationPermission(context) || !mounted) return false;
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return false;
      setState(() => _locationReady = true);
    }
    return true;
  }

  Future<void> _initialize({bool switchCamera = false}) async {
    final generation = ++_generation;
    setState(() {
      _initializing = true;
      _error = null;
      _locationReady = false;
    });
    final previous = _controller;
    _controller = null;
    CameraController? candidate;
    try {
      await previous?.dispose();
      if (!mounted || generation != _generation) return;
      if (!await _checkAccess()) {
        if (mounted && generation == _generation) {
          setState(
            () => _error = widget.requireLocation
                ? 'Camera and location access are required to mark attendance.'
                : 'Camera access is required to take a photo.',
          );
        }
        return;
      }
      if (!mounted || generation != _generation) return;
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw StateError('No camera is available on this device.');
      }
      if (switchCamera) {
        _cameraIndex = (_cameraIndex + 1) % _cameras.length;
      } else {
        final index = _cameras.indexWhere(
          (c) => c.lensDirection == widget.lensDirection,
        );
        _cameraIndex = index < 0 ? 0 : index;
      }
      candidate = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await candidate.initialize();
      if (!mounted || generation != _generation || !_foreground) {
        await candidate.dispose();
        return;
      }
      setState(() => _controller = candidate);
    } catch (_) {
      await candidate?.dispose();
      if (mounted && generation == _generation) {
        setState(() {
          _error = widget.requireLocation
              ? 'Unable to prepare capture. Check camera access and location services, then try again.'
              : 'Unable to open the camera. Check camera access and try again.';
        });
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _initializing = false);
      }
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_capturing ||
        _initializing ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }
    setState(() => _capturing = true);
    try {
      if (!await _checkAccess()) {
        if (mounted) {
          setState(() {
            _locationReady = false;
            _error = 'Required permissions are missing. Enable access and try again.';
          });
        }
        return;
      }
      if (!mounted ||
          controller != _controller ||
          !controller.value.isInitialized) {
        return;
      }
      final image = await controller.takePicture();
      if (mounted) Navigator.of(context).pop(image.path);
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationReady = false;
          _error = 'Unable to capture your photo. Check camera and location access, then try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const c = HostelColors.dark;
    final controller = _controller;
    final ready =
        !_initializing &&
        _error == null &&
        controller != null &&
        controller.value.isInitialized &&
        (!widget.requireLocation || _locationReady);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Cancel capture',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: c.ink),
                    ),
                    Expanded(
                      child: Text(
                        widget.requireLocation
                            ? 'Mark attendance'
                            : 'Take profile photo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Switch camera',
                      onPressed: ready && !_capturing && _cameras.length > 1
                          ? () => _initialize(switchCamera: true)
                          : null,
                      icon: Icon(
                        Icons.flip_camera_android_outlined,
                        color: ready ? c.ink : c.inkMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: ColoredBox(
                      color: c.surfaceSunken,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (controller != null &&
                              controller.value.isInitialized)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final landscape =
                                    MediaQuery.orientationOf(context) ==
                                    Orientation.landscape;
                                final ratio = landscape
                                    ? controller.value.aspectRatio
                                    : 1 / controller.value.aspectRatio;
                                return ClipRect(
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: constraints.maxHeight * ratio,
                                      height: constraints.maxHeight,
                                      child: CameraPreview(controller),
                                    ),
                                  ),
                                );
                              },
                            ),
                          if (_initializing)
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: c.onBrand),
                                  const SizedBox(height: 14),
                                  Text(
                                    widget.requireLocation
                                        ? 'Preparing camera and location...'
                                        : 'Opening camera...',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: c.ink),
                                  ),
                                ],
                              ),
                            )
                          else if (_error != null)
                            Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.no_photography_outlined,
                                      color: c.inkMuted,
                                      size: 36,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: c.ink,
                                        height: 1.5,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _capturing
                                          ? null
                                          : () => _initialize(),
                                      style: TextButton.styleFrom(
                                        foregroundColor: c.primary,
                                      ),
                                      child: const Text('Try again'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else ...[
                            IgnorePointer(
                              child: CustomPaint(
                                painter: _OvalGuidePainter(
                                  color: c.marigold,
                                  scrim: c.scrim,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 16,
                              left: 12,
                              right: 12,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.surface.withValues(alpha: .85),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Text(
                                    widget.hint,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: c.ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 8,
                              right: 8,
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (widget.requireLocation)
                                    _status(
                                      _locationReady
                                          ? 'Location found'
                                          : 'Finding location...',
                                      Icons.location_on_outlined,
                                      c,
                                    ),
                                  _status(
                                    'Face guide',
                                    Icons.face_retouching_natural_outlined,
                                    c,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Text(
                    'Hold the phone at eye level. Take off cap, mask or sunglasses.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.inkMuted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  enabled: ready && !_capturing,
                  label: 'Capture photo',
                  child: SizedBox.square(
                    dimension: 76,
                    child: OutlinedButton(
                      onPressed: ready && !_capturing ? _capture : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(5),
                        shape: const CircleBorder(),
                        side: BorderSide(
                          color: ready ? c.ink : c.lineStrong,
                          width: 4,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ready ? c.ink : c.lineStrong,
                        ),
                        child: _capturing
                            ? Center(
                                child: SizedBox.square(
                                  dimension: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: c.surface,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _status(String text, IconData icon, HostelColors c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: c.successSoft,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c.success),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: c.success,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _OvalGuidePainter extends CustomPainter {
  const _OvalGuidePainter({required this.color, required this.scrim});
  final Color color, scrim;
  @override
  void paint(Canvas canvas, Size size) {
    final oval = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * .46),
      width: size.width * .62,
      height: size.height * .54,
    );
    final hole = Path()..addOval(oval);
    final shade = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      hole,
    );
    canvas.drawPath(shade, Paint()..color = scrim.withValues(alpha: .25));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final metric in hole.computeMetrics()) {
      for (double offset = 0; offset < metric.length; offset += 20) {
        canvas.drawPath(metric.extractPath(offset, offset + 11), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OvalGuidePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.scrim != scrim;
}
