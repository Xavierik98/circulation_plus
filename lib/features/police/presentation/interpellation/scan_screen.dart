import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/widgets/premium_button.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  bool _isScanning = false;
  bool _scanComplete = false;
  String _scanType = 'license';

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
    await Future.delayed(const Duration(milliseconds: 2000));
    setState(() {
      _isScanning = false;
      _scanComplete = true;
    });
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
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Scan type selector
            _buildScanTypeSelector(),

            const SizedBox(height: 24),

            // Camera viewfinder mock
            _buildViewfinder(),

            const SizedBox(height: 24),

            // Instructions
            _buildInstructions(),

            const SizedBox(height: 24),

            if (!_scanComplete)
              PremiumButton(
                label: _isScanning ? 'Numérisation...' : 'Lancer la numérisation',
                isLoading: _isScanning,
                icon: Icons.document_scanner_rounded,
                onPressed: _isScanning ? null : _startScan,
              ).animate().fadeIn(delay: 300.ms)
            else
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Document numérisé avec succès',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success),
                        ),
                      ],
                    ),
                  ).animate().scale(begin: const Offset(0.8, 0.8)),
                  const SizedBox(height: 16),
                  PremiumButton(
                    label: 'Continuer',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => context.push('/police/ocr'),
                  ).animate().fadeIn(),
                ],
              ),
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
            // Camera grid
            CustomPaint(
              painter: _CameraGridPainter(),
              size: Size.infinite,
            ),

            // Document frame
            Container(
              width: 260,
              height: 165,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _scanComplete
                      ? AppColors.success
                      : (_isScanning ? AppColors.gold : AppColors.gold.withValues(alpha: 0.4)),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  ..._corners(),

                  // Scanning line animation
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

                  if (_scanComplete)
                    Center(
                      child: Icon(
                        Icons.check_rounded,
                        color: AppColors.success.withValues(alpha: 0.3),
                        size: 80,
                      ),
                    ),
                ],
              ),
            ),

            // Mock document inside
            if (!_isScanning && !_scanComplete)
              Container(
                width: 240,
                height: 145,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xFF1A2540),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 60, height: 8, color: AppColors.divider),
                    const SizedBox(height: 6),
                    Container(width: 120, height: 8, color: AppColors.divider.withValues(alpha: 0.6)),
                    const SizedBox(height: 4),
                    Container(width: 90, height: 8, color: AppColors.divider.withValues(alpha: 0.4)),
                  ],
                ),
              ),

            // Status overlay
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _scanComplete
                      ? 'Document détecté'
                      : _isScanning
                          ? 'Numérisation en cours...'
                          : 'Placez le document dans le cadre',
                  style: AppTextStyles.caption.copyWith(
                    color: _scanComplete ? AppColors.success : AppColors.textSecondary,
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
    final color = _scanComplete ? AppColors.success : AppColors.gold;
    return [
      Positioned(
        top: 0,
        left: 0,
        child: _Corner(color: color, size: size, strokeWidth: width, corner: 0),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: _Corner(color: color, size: size, strokeWidth: width, corner: 1),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: _Corner(color: color, size: size, strokeWidth: width, corner: 2),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: _Corner(color: color, size: size, strokeWidth: width, corner: 3),
      ),
    ];
  }

  Widget _buildInstructions() {
    final tips = [
      'Assurez-vous d\'un bon éclairage',
      'Le document doit être bien à plat',
      'Évitez les reflets sur le document',
    ];
    return Column(
      children: tips.map((tip) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Text(tip, style: AppTextStyles.bodySmall),
          ],
        ),
      )).toList(),
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
              Icon(icon, size: 16,
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
  const _Corner({required this.color, required this.size, required this.strokeWidth, required this.corner});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(color: color, strokeWidth: strokeWidth, corner: corner),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int corner;
  _CornerPainter({required this.color, required this.strokeWidth, required this.corner});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path();
    switch (corner) {
      case 0: path..moveTo(0, size.height)..lineTo(0, 0)..lineTo(size.width, 0); break;
      case 1: path..moveTo(0, 0)..lineTo(size.width, 0)..lineTo(size.width, size.height); break;
      case 2: path..moveTo(0, 0)..lineTo(0, size.height)..lineTo(size.width, size.height); break;
      case 3: path..moveTo(0, size.height)..lineTo(size.width, size.height)..lineTo(size.width, 0); break;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.divider.withValues(alpha: 0.15)..strokeWidth = 0.5;
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
