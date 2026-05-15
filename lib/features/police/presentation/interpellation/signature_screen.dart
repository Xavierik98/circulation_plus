import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/widgets/premium_button.dart';

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({super.key});

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _hasSignature = false;

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = [details.localPosition];
      _hasSignature = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _strokes.add(List.from(_currentStroke));
      _currentStroke = [];
    });
  }

  void _clearSignature() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
      _hasSignature = false;
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
            Text('Signature numérique', style: AppTextStyles.titleSmall),
            Text('Étape 5 sur 5', style: AppTextStyles.caption),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 1.0,
            backgroundColor: AppColors.surfaceVariant,
            color: AppColors.primary,
            minHeight: 3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryGlow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'La signature du conducteur confirme la réception de l\'avis d\'infraction. Ce document a une valeur légale.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            // Summary before signature
            _buildSummary(),

            const SizedBox(height: 24),

            // Officer signature
            Text('Signature de l\'agent', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Agent PNB-4521 — Jean-Pierre Moukala',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            _buildSignaturePad('officer'),

            const SizedBox(height: 20),

            // Driver signature
            Text('Signature du conducteur', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Thierry Nguesso — Permis BZV-2024-047821',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 12),
            _buildSignaturePadInteractive(),

            if (_hasSignature) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _clearSignature,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text('Effacer', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Confirm checkbox
            _RefusalOption(),

            const SizedBox(height: 24),

            PremiumButton(
              label: 'Valider l\'interpellation',
              icon: Icons.check_circle_outline_rounded,
              onPressed: _hasSignature ? () => context.push('/police/confirmation') : null,
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Column(
        children: [
          _SummaryRow(label: 'Conducteur', value: 'Thierry Nguesso'),
          Divider(height: 16, color: AppColors.divider),
          _SummaryRow(label: 'Véhicule', value: 'Toyota Corolla — BZV-4521-A'),
          Divider(height: 16, color: AppColors.divider),
          _SummaryRow(label: 'Infractions', value: '2 infractions'),
          Divider(height: 16, color: AppColors.divider),
          _SummaryRow(
            label: 'Montant',
            value: '50 000 FCFA',
            valueColor: AppColors.primary,
          ),
          Divider(height: 16, color: AppColors.divider),
          _SummaryRow(label: 'Référence', value: 'CP-2024-002847'),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildSignaturePad(String type) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_rounded, size: 16, color: AppColors.success),
            const SizedBox(width: 8),
            Text(
              'Signé électroniquement',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignaturePadInteractive() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasSignature ? AppColors.primary.withValues(alpha: 0.5) : AppColors.cardBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Grid hint
            if (!_hasSignature)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.draw_outlined, size: 28, color: AppColors.textDisabled),
                    const SizedBox(height: 8),
                    Text(
                      'Signez ici',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled),
                    ),
                  ],
                ),
              ),

            // Signature canvas
            GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: _SignaturePainter(
                  strokes: _strokes,
                  currentStroke: _currentStroke,
                ),
                size: Size.infinite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label, style: AppTextStyles.bodySmall)),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _RefusalOption extends StatefulWidget {
  @override
  State<_RefusalOption> createState() => _RefusalOptionState();
}

class _RefusalOptionState extends State<_RefusalOption> {
  bool _refusedToSign = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _refusedToSign = !_refusedToSign),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _refusedToSign ? AppColors.error.withValues(alpha: 0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _refusedToSign ? AppColors.error.withValues(alpha: 0.4) : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _refusedToSign ? AppColors.error : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _refusedToSign ? AppColors.error : AppColors.textTertiary,
                ),
              ),
              child: _refusedToSign
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Le conducteur refuse de signer (enregistré)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: _refusedToSign ? AppColors.error : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _SignaturePainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset> stroke) {
      if (stroke.length < 2) return;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }

    for (final stroke in strokes) {
      drawStroke(stroke);
    }
    drawStroke(currentStroke);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
