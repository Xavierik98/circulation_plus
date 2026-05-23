import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../shared/models/interpellation_state.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  bool _isScanning = false;
  bool _scanComplete = false;
  String _scanType = 'license';
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1200,
      );
      if (!mounted) return;
      if (image != null) {
        setState(() {
          _imagePath = image.path;
          _scanComplete = true;
        });
        // Sauvegarder dans l'état de l'interpellation
        ref.read(interpellationProvider.notifier).setScanImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur appareil photo : $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  /// Saisie manuelle sans photo (l'agent saisit directement le formulaire).
  void _skipScan() {
    ref.read(interpellationProvider.notifier).setScanImage(null);
    context.push('/police/ocr');
  }

  @override
  Widget build(BuildContext context) {
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

            // Camera viewfinder
            _buildViewfinder(),

            const SizedBox(height: 24),

            // Instructions
            _buildInstructions(),

            const SizedBox(height: 24),

            if (!_scanComplete) ...[
              PremiumButton(
                label: _isScanning ? 'Ouverture appareil...' : 'Prendre la photo',
                isLoading: _isScanning,
                icon: Icons.camera_alt_rounded,
                onPressed: _isScanning ? null : _startScan,
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
                    icon: const Icon(Icons.camera_alt_rounded,
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
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Fond grille ou image capturée
            if (_imagePath != null)
              Positioned.fill(
                child: Image.file(
                  File(_imagePath!),
                  fit: BoxFit.cover,
                ),
              )
            else
              CustomPaint(
                painter: _CameraGridPainter(),
                size: Size.infinite,
              ),

            // Cadre document (visible uniquement sans photo)
            if (_imagePath == null)
              Container(
                width: 260,
                height: 165,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isScanning
                        ? AppColors.gold
                        : AppColors.gold.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    ..._corners(),
                    if (_isScanning)
                      AnimatedBuilder(
                        animation: _scanController,
                        builder: (context, _) => Positioned(
                          top: _scanController.value * 145,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.gold.withValues(alpha: 0.9),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!_isScanning)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _scanType == 'license'
                                  ? Icons.credit_card_rounded
                                  : Icons.directions_car_rounded,
                              size: 36,
                              color: AppColors.gold.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _scanType == 'license'
                                  ? 'Permis de conduire'
                                  : 'Carte grise',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // Overlay vert + icône check sur photo capturée
            if (_imagePath != null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success.withValues(alpha: 0.8),
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
                      ? 'Photo enregistrée ✓'
                      : _isScanning
                          ? 'Ouverture appareil photo...'
                          : 'Appuyez sur le bouton pour prendre la photo',
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

  List<Widget> _corners() {
    const size = 16.0;
    const width = 2.5;
    const color = AppColors.gold;
    return [
      const Positioned(
          top: 0,
          left: 0,
          child: _Corner(color: color, size: size, strokeWidth: width, corner: 0)),
      const Positioned(
          top: 0,
          right: 0,
          child: _Corner(color: color, size: size, strokeWidth: width, corner: 1)),
      const Positioned(
          bottom: 0,
          left: 0,
          child: _Corner(color: color, size: size, strokeWidth: width, corner: 2)),
      const Positioned(
          bottom: 0,
          right: 0,
          child: _Corner(color: color, size: size, strokeWidth: width, corner: 3)),
    ];
  }

  Widget _buildInstructions() {
    final tips = [
      'Cadrez le document dans la lumière',
      'Le texte doit être lisible, évitez les reflets',
      'Vous pourrez corriger les champs manuellement ensuite',
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

class _Corner extends StatelessWidget {
  final Color color;
  final double size;
  final double strokeWidth;
  final int corner;
  const _Corner(
      {required this.color,
      required this.size,
      required this.strokeWidth,
      required this.corner});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter:
            _CornerPainter(color: color, strokeWidth: strokeWidth, corner: corner),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int corner;
  _CornerPainter(
      {required this.color, required this.strokeWidth, required this.corner});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    switch (corner) {
      case 0:
        path
          ..moveTo(0, size.height)
          ..lineTo(0, 0)
          ..lineTo(size.width, 0);
        break;
      case 1:
        path
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(size.width, size.height);
        break;
      case 2:
        path
          ..moveTo(0, 0)
          ..lineTo(0, size.height)
          ..lineTo(size.width, size.height);
        break;
      case 3:
        path
          ..moveTo(0, size.height)
          ..lineTo(size.width, size.height)
          ..lineTo(size.width, 0);
        break;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
