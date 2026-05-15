import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/fine_model.dart';
import '../../../shared/widgets/premium_button.dart';

class ReceiptScreen extends StatelessWidget {
  final String fineId;
  const ReceiptScreen({super.key, required this.fineId});

  @override
  Widget build(BuildContext context) {
    final fine = FineModel.mockFines.firstWhere(
      (f) => f.id == fineId,
      orElse: () => FineModel.mockFines.firstWhere((f) => f.status == FineStatus.paid),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: GestureDetector(
          onTap: () => context.go('/citizen'),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reçu de paiement', style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 15, fontWeight: FontWeight.w600)),
            Text('PORTAIL CITOYEN', style: TextStyle(color: Color(0xFF009A44), fontSize: 9, letterSpacing: 1.5)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildReceiptCard(fine),
            const SizedBox(height: 20),
            _buildActions(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard(FineModel fine) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: AppColors.successGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text('REÇU DE PAIEMENT',
                    style: AppTextStyles.overline.copyWith(color: Colors.white.withValues(alpha: 0.9), letterSpacing: 3)),
                const SizedBox(height: 8),
                Text('République du Congo',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                Text('Ministère de l\'Intérieur — DGST',
                    style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),

          // Dashed divider
          _DashedDivider(),

          // Receipt body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _ReceiptRow(label: 'Référence', value: fine.reference, isMono: true, bold: true),
                const SizedBox(height: 12),
                _ReceiptRow(label: 'Conducteur', value: fine.driverName),
                const SizedBox(height: 8),
                _ReceiptRow(label: 'Véhicule', value: '${fine.vehicleBrand} — ${fine.vehiclePlate}'),
                const SizedBox(height: 8),
                _ReceiptRow(label: 'Infraction', value: fine.infractionLabel),
                const SizedBox(height: 8),
                _ReceiptRow(
                  label: 'Date d\'infraction',
                  value: '${fine.issuedAt.day}/${fine.issuedAt.month}/${fine.issuedAt.year}',
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: AppColors.divider)),
                _ReceiptRow(label: 'Méthode', value: fine.paymentMethod ?? 'MTN Mobile Money'),
                const SizedBox(height: 8),
                _ReceiptRow(label: 'Référence paiement', value: fine.paymentRef ?? 'MTN-2024-78923', isMono: true),
                const SizedBox(height: 8),
                _ReceiptRow(
                  label: 'Date paiement',
                  value: fine.paidAt != null
                      ? '${fine.paidAt!.day}/${fine.paidAt!.month}/${fine.paidAt!.year}'
                      : _formatNow(),
                ),
              ],
            ),
          ),

          // Dashed divider
          _DashedDivider(),

          // Total
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('MONTANT TOTAL', style: AppTextStyles.labelMedium.copyWith(letterSpacing: 1.5)),
                Text(
                  '${(fine.amount / 1000).toStringAsFixed(0)} 000 FCFA',
                  style: AppTextStyles.headlineSmall.copyWith(color: AppColors.success),
                ),
              ],
            ),
          ),

          // Dashed divider
          _DashedDivider(),

          // QR mock
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: CustomPaint(painter: _QrMockPainter()),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scannez pour vérifier\nCP-2024-002847',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text('Document authentique — DGST Congo',
                          style: AppTextStyles.caption.copyWith(color: AppColors.success)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        PremiumButton(
          label: 'Télécharger le PDF',
          icon: Icons.download_rounded,
          gradient: AppColors.successGradient,
          onPressed: () {},
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.surfaceVariant,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.print_outlined, size: 18, color: AppColors.textTertiary),
                      const SizedBox(width: 8),
                      Text('Imprimer', style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.surfaceVariant,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.share_outlined, size: 18, color: AppColors.textTertiary),
                      const SizedBox(width: 8),
                      Text('Partager', style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go('/citizen'),
          child: Text('Retour à l\'accueil', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  String _formatNow() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMono;
  final bool bold;
  const _ReceiptRow({required this.label, required this.value, this.isMono = false, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Text(label, style: AppTextStyles.bodySmall)),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: isMono
                ? AppTextStyles.mono.copyWith(fontSize: 11, color: AppColors.primary)
                : AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
                  ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(painter: _DashedPainter()),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.divider..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 6, 0), paint);
      x += 10;
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QrMockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.textSecondary..style = PaintingStyle.fill;
    final cell = size.width / 7;
    const pattern = [
      [1,1,1,1,1,1,1],
      [1,0,0,0,0,0,1],
      [1,0,1,1,1,0,1],
      [1,0,1,0,1,0,1],
      [1,0,1,1,1,0,1],
      [1,0,0,0,0,0,1],
      [1,1,1,1,1,1,1],
    ];
    for (int r = 0; r < 7; r++) {
      for (int c = 0; c < 7; c++) {
        if (pattern[r][c] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell + 2, r * cell + 2, cell - 1, cell - 1),
            paint,
          );
        }
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
