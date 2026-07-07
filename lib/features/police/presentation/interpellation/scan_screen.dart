import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../shared/models/interpellation_state.dart';

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
  String _scanType = 'license';
  String? _imagePath;

  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // ML Kit OCR n'est pas disponible sur Flutter Web
    if (!kIsWeb) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Select back camera if available
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
        
        // Démarrer l'analyse en flux continu
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
      // Ignorer silencieusement les erreurs de flux
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _parseRecognizedText(RecognizedText text) async {
    if (_scanComplete) return;

    String? foundLicense;
    String? foundName;

    // Analyse rudimentaire du bloc de texte
    for (TextBlock block in text.blocks) {
      final line = block.text.toUpperCase();
      
      // Cherche un format de numéro de permis typique (Lettres et Chiffres, ex: CG-1234567, ou 8-12 chiffres purs)
      if (RegExp(r'[A-Z0-9]{8,14}').hasMatch(line) && line.contains(RegExp(r'\d'))) {
        foundLicense = line.replaceAll(RegExp(r'[^A-Z0-9-]'), ''); // Nettoyage
      }
      
      // Cherche le nom (heuristique basique)
      if (line.contains('NOM') || line.contains('NAME')) {
        foundName = line.replaceAll(RegExp(r'(NOM|NAME|:|;)'), '').trim();
        if (foundName.isEmpty) foundName = null;
      }
    }

    if (foundLicense != null && foundLicense.length >= 6) {
      // Un numéro de permis potentiel a été détecté
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
        
        // Enregistrer dans le provider
        ref.read(interpellationProvider.notifier).setScanImage(image.path);
        ref.read(interpellationProvider.notifier).updateDriver(
          license: foundLicense,
          name: foundName ?? '',
        );
        
        // Auto-navigation
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) context.push('/police/ocr');
        });
      } catch (e) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isScanning) {
      return;
    }

    setState(() => _isScanning = true);
    try {
      final XFile image = await _cameraController!.takePicture();
      if (!mounted) return;
      
      setState(() {
        _imagePath = image.path;
        _scanComplete = true;
      });
      
      // Save to provider
      ref.read(interpellationProvider.notifier).setScanImage(image.path);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de la capture : $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _skipScan() {
    ref.read(interpellationProvider.notifier).setScanImage(null);
    context.push('/police/ocr');
  }

  @override
  Widget build(BuildContext context) {
    // Sur Flutter Web, l'OCR ML Kit n'est pas disponible — afficher un écran explicatif
    if (kIsWeb) {
      return _buildWebUnavailableScreen(context);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppColors.textPrimary),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nouvelle Interpellation',
                style: AppTextStyles.titleSmall),
            Text('Étape 1 sur 5 — Numérisation',
                style: AppTextStyles.caption),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.2,
            backgroundColor: AppColors.surfaceVariant,
            color: AppColors.primary,
            minHeight: 3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Scan type selector
            _buildScanTypeSelector(),

            const SizedBox(height: 24),

            // Live Camera Viewfinder
            _buildViewfinder(),

            const SizedBox(height: 24),

            // Instructions
            _buildInstructions(),

            const SizedBox(height: 24),

            if (!_scanComplete) ...[
              PremiumButton(
                label: _isScanning ? 'Capture en cours...' : 'Prendre la photo',
                isLoading: _isScanning,
                icon: Icons.camera_alt_rounded,
                onPressed: _isScanning || !_isCameraInitialized ? null : _takePicture,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _skipScan,
                  icon: const Icon(Icons.edit_note_rounded,
                      size: 16, color: AppColors.textTertiary),
                  label: Text(
                    'Saisie manuelle sans photo',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),
            ] else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Photo capturée — vérifiez les champs sur l\'écran suivant',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(begin: const Offset(0.8, 0.8)),
                  const SizedBox(height: 12),
                  // Retake
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _scanComplete = false;
                      _imagePath = null;
                    }),
                    icon: const Icon(Icons.refresh_rounded,
                        size: 16, color: AppColors.textTertiary),
                    label: Text('Reprendre la photo',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textTertiary)),
                  ),
                  const SizedBox(height: 8),
                  PremiumButton(
                    label: 'Continuer',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => context.push('/police/ocr'),
                  ).animate().fadeIn(),
                ],
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Écran affiché sur Flutter Web (OCR non disponible) ───────────────────
  Widget _buildWebUnavailableScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 16, color: AppColors.textPrimary),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nouvelle Interpellation', style: AppTextStyles.titleSmall),
            Text('Étape 1 sur 5 — Numérisation', style: AppTextStyles.caption),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.2,
            backgroundColor: AppColors.surfaceVariant,
            color: AppColors.primary,
            minHeight: 3,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.smartphone_rounded,
                    color: AppColors.warning, size: 40),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text(
                'Scanner OCR — Application Mobile',
                style: AppTextStyles.titleMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              Text(
                'Le scanner de permis par Intelligence Artificielle '
                'utilise Google ML Kit, disponible uniquement sur '
                'l\'application mobile Android/iOS installée sur le téléphone.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sur navigateur web, utilisez la saisie manuelle pour compléter l\'interpellation.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 32),
              PremiumButton(
                label: 'Continuer en saisie manuelle',
                icon: Icons.edit_note_rounded,
                onPressed: _skipScan,
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _ScanTypeBtn(
            label: 'Permis de conduire',
            icon: Icons.credit_card_rounded,
            isSelected: _scanType == 'license',
            onTap: () => setState(() => _scanType = 'license'),
          ),
          _ScanTypeBtn(
            label: 'Carte grise',
            icon: Icons.directions_car_rounded,
            isSelected: _scanType == 'registration',
            onTap: () => setState(() => _scanType = 'registration'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildViewfinder() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF040D07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Camera Preview or Captured Image
            if (_imagePath != null)
              Positioned.fill(
                child: kIsWeb
                    ? Container(color: AppColors.surfaceVariant)
                    : Image.file(File(_imagePath!), fit: BoxFit.cover),
              )
            else if (_isCameraInitialized && _cameraController != null)
              Positioned.fill(
                // Use a fitted box to cover the container with the camera aspect ratio
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize?.height ?? 1,
                    height: _cameraController!.value.previewSize?.width ?? 1,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),

            // 2. Dark Overlay with Cutout Mask
            if (_imagePath == null && _isCameraInitialized)
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScannerOverlayPainter(),
                ),
              ),

            // 3. Animated Scanning Line (only when live)
            if (_imagePath == null && _isCameraInitialized)
              Positioned(
                top: 0,
                bottom: 0,
                left: 30,
                right: 30,
                child: AnimatedBuilder(
                  animation: _scanAnimController,
                  builder: (context, _) => Positioned(
                    top: _scanAnimController.value * 260 + 20,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.gold.withValues(alpha: 0.9),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Overlay vert + icône check sur photo capturée
            if (_imagePath != null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success.withValues(alpha: 0.9),
                      size: 64,
                    ),
                  ),
                ),
              ),

            // Label statut bas
            Positioned(
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _scanComplete
                      ? 'Document numérisé ✓'
                      : _isScanning
                          ? 'Capture en cours...'
                          : 'Alignez le document dans le cadre',
                  style: AppTextStyles.caption.copyWith(
                    color: _scanComplete
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    final tips = [
      'Placez le document bien à plat',
      'Assurez-vous qu\'il n\'y ait pas de reflet',
      'Laissez l\'application faire la mise au point',
    ];
    return Column(
      children: tips
          .map((tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(tip, style: AppTextStyles.bodySmall)),
                  ],
                ),
              ))
          .toList(),
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _ScanTypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _ScanTypeBtn({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textTertiary,
                ),
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
    // 1. Draw the semi-transparent dark overlay over the whole view
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    
    // The cutout rect represents a typical ID card ratio
    final rectWidth = size.width * 0.85;
    final rectHeight = rectWidth * 0.65; // ~ID card ratio
    final cutoutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: rectWidth,
      height: rectHeight,
    );
    final cutoutRRect = RRect.fromRectAndRadius(cutoutRect, const Radius.circular(12));

    // We use Path.combine to subtract the cutout from the full background
    final bgPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()..addRRect(cutoutRRect);
    final finalPath = Path.combine(PathOperation.difference, bgPath, cutoutPath);
    
    canvas.drawPath(finalPath, backgroundPaint);

    // 2. Draw the golden corner brackets
    final bracketPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final double cornerLength = 25.0;
    
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
