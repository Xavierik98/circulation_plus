import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/models/interpellation_state.dart';
import '../../../../shared/models/department_model.dart';
import '../../../../shared/widgets/premium_button.dart';

class SignatureScreen extends ConsumerStatefulWidget {
  const SignatureScreen({super.key});

  @override
  ConsumerState<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends ConsumerState<SignatureScreen> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _hasSignature = false;
  bool _refusedToSign = false;
  // Empêche un double-appui rapide de pousser l'écran de confirmation deux
  // fois (ce qui déclenchait deux soumissions de PV quasi simultanées, la
  // seconde étant bloquée par la protection anti-doublon serveur).
  bool _isNavigating = false;

  Future<void> _navigateOnce(String route) async {
    if (_isNavigating) return;
    _isNavigating = true;
    await context.push(route);
    if (mounted) _isNavigating = false;
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = [details.localPosition];
      _hasSignature = true;
      _refusedToSign = false; // Signer annule le refus
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
    final interpellation = ref.watch(interpellationProvider);

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
            Text('Étape 6 sur 6', style: AppTextStyles.caption),
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

            // ── Info légale ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryGlow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'La signature du conducteur confirme la réception de '
                      'l\'avis d\'infraction. Ce document a une valeur légale.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            // ── Résumé de l'interpellation ───────────────────────
            _buildSummary(interpellation),

            const SizedBox(height: 24),

            // ── Signature agent ───────────────────────────────────
            Text('Signature de l\'agent', style: AppTextStyles.titleMedium),
            const SizedBox(height: 12),
            _buildSignaturePadFixed(),

            const SizedBox(height: 20),

            // ── Signature conducteur ──────────────────────────────
            Text('Signature du conducteur', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              interpellation.driverName.isNotEmpty
                  ? interpellation.driverName
                  : 'Conducteur',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textTertiary),
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
                    const Icon(Icons.refresh_rounded,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      'Effacer',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Option refus ──────────────────────────────────────
            _buildRefusalOption(),

            const SizedBox(height: 24),

            // ── Bouton principal ──────────────────────────────────
            if (_refusedToSign)
              PremiumButton(
                label: 'Procéder à la saisie des documents',
                icon: Icons.folder_open_outlined,
                onPressed: () => _navigateOnce('/police/refusal'),
              ).animate().fadeIn()
            else
              PremiumButton(
                label: 'Valider l\'interpellation',
                icon: Icons.check_circle_outline_rounded,
                onPressed: _hasSignature
                    ? () => _navigateOnce('/police/confirmation')
                    : null,
              ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(InterpellationState s) {
    final total = s.totalAmount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _SummaryRow(
              label: 'Conducteur',
              value: s.driverName.isNotEmpty ? s.driverName : '—'),
          const Divider(height: 16, color: AppColors.divider),
          _SummaryRow(
            label: 'Véhicule',
            value: s.vehiclePlate.isNotEmpty
                ? '${s.vehicleBrand} — ${s.vehiclePlate}'
                : '—',
          ),
          const Divider(height: 16, color: AppColors.divider),
          _SummaryRow(
            label: 'Lieu',
            value: s.lieuPrecis.isNotEmpty
                ? s.lieuPrecis
                : s.departement?.label ?? '—',
          ),
          const Divider(height: 16, color: AppColors.divider),
          _SummaryRow(
              label: 'Infractions',
              value:
                  '${s.selectedInfractions.length} infraction${s.selectedInfractions.length > 1 ? 's' : ''}'),
          const Divider(height: 16, color: AppColors.divider),
          _SummaryRow(
            label: 'Montant',
            value: '${_fmt(total)} FCFA',
            valueColor: AppColors.primary,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildSignaturePadFixed() {
    return Container(
      height: 64,
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
          color: _hasSignature
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.cardBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (!_hasSignature)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.draw_outlined,
                        size: 28, color: AppColors.textDisabled),
                    const SizedBox(height: 8),
                    Text(
                      'Signez ici',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textDisabled),
                    ),
                  ],
                ),
              ),
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

  Widget _buildRefusalOption() {
    return GestureDetector(
      onTap: () => setState(() {
        _refusedToSign = !_refusedToSign;
        if (_refusedToSign) _clearSignature();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _refusedToSign
              ? AppColors.error.withValues(alpha: 0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _refusedToSign
                ? AppColors.error.withValues(alpha: 0.4)
                : AppColors.cardBorder,
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
                  color: _refusedToSign
                      ? AppColors.error
                      : AppColors.textTertiary,
                ),
              ),
              child: _refusedToSign
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Le conducteur refuse de signer',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _refusedToSign
                          ? AppColors.error
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_refusedToSign) ...[
                    const SizedBox(height: 2),
                    Text(
                      '→ Saisie de documents + convocation automatique',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.error),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int amount) {
    if (amount < 1000) return amount.toString();
    final thousands = amount ~/ 1000;
    final remainder = amount % 1000;
    if (remainder == 0) return '$thousands 000';
    return '$thousands ${remainder.toString().padLeft(3, '0')}';
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
        Expanded(
            flex: 2, child: Text(label, style: AppTextStyles.bodySmall)),
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
