import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/models/interpellation_state.dart';

class _StitchColors {
  static const Color primary = Color(0xFF83fb9c); // or 0xFF006b2e
  static const Color background = Colors.black;
  static const Color surface = Colors.black;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
}

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scanAnimController;
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  
  bool _isScanning = false;
  bool _scanComplete = false;
  String? _imagePath;
  bool _flashOn = false;

  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    if (!kIsWeb) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final backCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );
        
        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
        
        await _cameraController!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || _scanComplete || !_isCameraInitialized || _imagePath != null) return;
    _isBusy = true;

    try {
      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final InputImageRotation imageRotation = 
          InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
      final InputImageFormat inputImageFormat = 
          InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final recognizedText = await _textRecognizer.processImage(inputImage);
      await _parseRecognizedText(recognizedText);
    } catch (e) {
      // Ignore
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _parseRecognizedText(RecognizedText text) async {
    if (_scanComplete) return;

    String? foundLicense;
    String? foundName;

    for (TextBlock block in text.blocks) {
      final line = block.text.toUpperCase();
      if (RegExp(r'[A-Z0-9]{8,14}').hasMatch(line) && line.contains(RegExp(r'\d'))) {
        foundLicense = line.replaceAll(RegExp(r'[^A-Z0-9-]'), '');
      }
      if (line.contains('NOM') || line.contains('NAME')) {
        foundName = line.replaceAll(RegExp(r'(NOM|NAME|:|;)'), '').trim();
        if (foundName.isEmpty) foundName = null;
      }
    }

    if (foundLicense != null && foundLicense.length >= 6) {
      setState(() => _isScanning = true);
      try {
        await _cameraController?.stopImageStream();
        final XFile image = await _cameraController!.takePicture();
        if (!mounted) return;
        
        setState(() {
          _imagePath = image.path;
          _scanComplete = true;
          _isScanning = false;
        });
        
        ref.read(interpellationProvider.notifier).setScanImage(image.path);
        ref.read(interpellationProvider.notifier).updateDriver(
          license: foundLicense,
          name: foundName ?? '',
        );
        
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) context.push('/police/ocr');
        });
      } catch (e) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isScanning) return;
    setState(() => _isScanning = true);
    try {
      final XFile image = await _cameraController!.takePicture();
      if (!mounted) return;
      
      setState(() {
        _imagePath = image.path;
        _scanComplete = true;
      });
      ref.read(interpellationProvider.notifier).setScanImage(image.path);
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) context.push('/police/ocr');
      });
    } catch (e) {
      // Error handling
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _skipScan() {
    ref.read(interpellationProvider.notifier).setScanImage(null);
    context.push('/police/ocr');
  }

  void _toggleFlash() async {
    if (_cameraController != null && _isCameraInitialized) {
      _flashOn = !_flashOn;
      await _cameraController!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildWebUnavailableScreen(context);

    return Scaffold(
      backgroundColor: _StitchColors.background,
      body: Stack(
        children: [
          // 1. Full Screen Camera Viewport
          Positioned.fill(
            child: _imagePath != null
                ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                : (_isCameraInitialized && _cameraController != null)
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _cameraController!.value.previewSize?.height ?? 1,
                          height: _cameraController!.value.previewSize?.width ?? 1,
                          child: CameraPreview(_cameraController!),
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: _StitchColors.primary),
                      ),
          ),

          // 2. Overlay & Scan Line
          if (_imagePath == null && _isCameraInitialized)
            Positioned.fill(
              child: CustomPaint(
                painter: _ScannerOverlayPainter(),
              ),
            ),
          
          if (_imagePath == null && _isCameraInitialized)
            AnimatedBuilder(
              animation: _scanAnimController,
              builder: (context, _) => Positioned(
                top: MediaQuery.of(context).size.height * (0.25 + (_scanAnimController.value * 0.40)),
                left: MediaQuery.of(context).size.width * 0.1,
                right: MediaQuery.of(context).size.width * 0.1,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: _StitchColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: _StitchColors.primary.withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
              ),
            ),

          if (_imagePath != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.3),
                ),
                child: Center(
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.greenAccent,
                    size: 80,
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                ),
              ),
            ),

          // 3. Top AppBar
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    'Scan Permis',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _flashOn ? Icons.flash_on : Icons.flash_off,
                      color: _flashOn ? _StitchColors.primary : Colors.white,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ],
              ),
            ),
          ),

          // 4. Bottom Controls (kept for functionality even if not strictly in mockup)
          if (_imagePath == null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Text(
                    _isScanning ? 'Analyse...' : 'Placez le permis dans le cadre',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isScanning || !_isCameraInitialized ? null : _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_isScanning ? 'Capture en cours...' : 'Prendre la photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _StitchColors.primary,
                      foregroundColor: Colors.black87,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _skipScan,
                    child: Text(
                      'Saisie manuelle sans photo',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebUnavailableScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.smartphone, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(
                'Scanner OCR non disponible sur le Web',
                style: GoogleFonts.inter(fontSize: 18, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _skipScan,
                child: const Text('Continuer en saisie manuelle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;
    
    // As per Stitch CSS: top 25%, bottom 35%, left/right 10%
    final cutoutRect = Rect.fromLTRB(
      size.width * 0.1,
      size.height * 0.25,
      size.width * 0.9,
      size.height * 0.65,
    );
    final cutoutRRect = RRect.fromRectAndRadius(cutoutRect, const Radius.circular(12));

    final bgPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(cutoutRRect);
    final finalPath = Path.combine(PathOperation.difference, bgPath, cutoutPath);
    
    canvas.drawPath(finalPath, backgroundPaint);

    final bracketPaint = Paint()
      ..color = const Color(0xFF83fb9c) // from Stitch theme: primary-fixed / ocr-active
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final double cornerLength = 32.0;
    
    // Top-Left
    canvas.drawLine(cutoutRect.topLeft, cutoutRect.topLeft + Offset(cornerLength, 0), bracketPaint);
    canvas.drawLine(cutoutRect.topLeft, cutoutRect.topLeft + Offset(0, cornerLength), bracketPaint);

    // Top-Right
    canvas.drawLine(cutoutRect.topRight, cutoutRect.topRight + Offset(-cornerLength, 0), bracketPaint);
    canvas.drawLine(cutoutRect.topRight, cutoutRect.topRight + Offset(0, cornerLength), bracketPaint);

    // Bottom-Left
    canvas.drawLine(cutoutRect.bottomLeft, cutoutRect.bottomLeft + Offset(cornerLength, 0), bracketPaint);
    canvas.drawLine(cutoutRect.bottomLeft, cutoutRect.bottomLeft + Offset(0, -cornerLength), bracketPaint);

    // Bottom-Right
    canvas.drawLine(cutoutRect.bottomRight, cutoutRect.bottomRight + Offset(-cornerLength, 0), bracketPaint);
    canvas.drawLine(cutoutRect.bottomRight, cutoutRect.bottomRight + Offset(0, -cornerLength), bracketPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
