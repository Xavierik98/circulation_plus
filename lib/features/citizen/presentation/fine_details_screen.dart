import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/fine_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../data/providers.dart';

class FineDetailsScreen extends ConsumerWidget {
  final String fineId;
  const FineDetailsScreen({super.key, required this.fineId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFine = ref.watch(fineDetailProvider(fineId));

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
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        title: Text('Détail de l\'amende', style: AppTextStyles.titleSmall),
        actions: [
          asyncFine.whenData((fine) => IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () async {
              final text =
                  'Circulation+ — PNC\n'
                  'Amende : ${fine.reference}\n'
                  'Infraction : ${fine.infractionLabel}\n'
                  'Plaque : ${fine.vehiclePlate}\n'
                  'Montant : ${(fine.amount / 1000).toStringAsFixed(0)} 000 FCFA\n'
                  'Échéance : ${fine.deadline.day}/${fine.deadline.month}/${fine.deadline.year}\n'
                  'Statut : ${fine.status.name.toUpperCase()}';
              await Clipboard.setData(ClipboardData(text: text));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Résumé copié dans le presse-papier'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          )).valueOrNull ?? const SizedBox.shrink(),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
              height: 3,
              decoration:
                  const BoxDecoration(gradient: AppColors.congoFlagGradient)),
        ),
      ),
      body: asyncFine.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Impossible de charger l\'amende',
                    style: AppTextStyles.titleSmall),
                const SizedBox(height: 8),
                Text(e.toString(),
                    style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                PremiumButton(
                  label: 'Réessayer',
                  icon: Icons.refresh_rounded,
                  onPressed: () =>
                      ref.invalidate(fineDetailProvider(fineId)),
                ),
              ],
            ),
          ),
        ),
        data: (fine) => _FineDetailsBody(fine: fine),
      ),
    );
  }
}

class _FineDetailsBody extends StatelessWidget {
  final FineModel fine;
  const _FineDetailsBody({required this.fine});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header hero
          _buildHeroCard(fine),
          const SizedBox(height: 20),

          // Infraction details
          _buildSection('Infraction', [
            _DetailRow(label: 'Type', value: fine.infractionLabel),
            _DetailRow(label: 'Code', value: fine.infractionCode),
            _DetailRow(
                label: 'Référence', value: fine.reference, isMono: true),
            _DetailRow(
                label: 'Date',
                value:
                    '${fine.issuedAt.day}/${fine.issuedAt.month}/${fine.issuedAt.year}'),
            _DetailRow(
                label: 'Heure',
                value:
                    '${fine.issuedAt.hour}:${fine.issuedAt.minute.toString().padLeft(2, '0')}'),
          ]),

          const SizedBox(height: 16),

          // Officer info
          _buildSection('Agent verbalisateur', [
            _DetailRow(label: 'Nom', value: fine.officerName),
            _DetailRow(
                label: 'Matricule',
                value: fine.officerBadge,
                isMono: true),
          ]),

          const SizedBox(height: 16),

          // Vehicle info
          _buildSection('Véhicule', [
            _DetailRow(
                label: 'Plaque', value: fine.vehiclePlate, isMono: true),
            _DetailRow(label: 'Marque', value: fine.vehicleBrand),
            _DetailRow(label: 'Propriétaire', value: fine.driverName),
          ]),

          const SizedBox(height: 16),

          // Location mock map
          _buildMapCard(fine),

          const SizedBox(height: 16),

          // Financial
          _buildSection('Informations financières', [
            _DetailRow(
                label: 'Montant',
                value:
                    '${(fine.amount / 1000).toStringAsFixed(0)} 000 FCFA',
                valueColor: AppColors.primary),
            _DetailRow(
                label: 'Majoration 50%',
                value:
                    '+${(fine.amount * 0.5 / 1000).toStringAsFixed(0)} 000 FCFA (si retard)',
                valueColor: AppColors.warning),
            _DetailRow(
                label: 'Échéance',
                value:
                    '${fine.deadline.day}/${fine.deadline.month}/${fine.deadline.year}',
                valueColor: fine.isOverdue
                    ? AppColors.error
                    : AppColors.textPrimary),
          ]),

          const SizedBox(height: 24),

          if (fine.status == FineStatus.pending ||
              fine.status == FineStatus.overdue) ...[
            PremiumButton(
              label: 'Payer maintenant',
              icon: Icons.payment_rounded,
              onPressed: () =>
                  context.push('/citizen/payment/${fine.id}'),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 12),
            _ContestButton(fine: fine),
          ] else if (fine.status == FineStatus.paid) ...[
            PremiumButton(
              label: 'Voir le reçu',
              icon: Icons.receipt_long_rounded,
              gradient: AppColors.successGradient,
              onPressed: () {
                final target = fine.paymentId ?? fine.id;
                context.push('/citizen/receipt/$target');
              },
            ).animate().fadeIn(),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroCard(FineModel fine) {
    final isPaid = fine.status == FineStatus.paid;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isPaid ? const Color(0xFF0A1A12) : const Color(0xFF1A100A),
            isPaid ? const Color(0xFF0C1C14) : const Color(0xFF1C1208),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPaid
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: (isPaid ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: (isPaid ? AppColors.success : AppColors.warning)
                          .withValues(alpha: 0.3)),
                ),
                child: Icon(
                  isPaid
                      ? Icons.check_circle_rounded
                      : Icons.gavel_rounded,
                  color: isPaid ? AppColors.success : AppColors.warning,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fine.infractionLabel,
                        style: AppTextStyles.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    StatusBadge.fromFineStatus(fine.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Montant', style: AppTextStyles.caption),
                  Text(
                    '${(fine.amount / 1000).toStringAsFixed(0)} 000 FCFA',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: isPaid ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ],
              ),
              Container(height: 36, width: 1, color: AppColors.divider),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(isPaid ? 'Payé le' : 'Échéance',
                      style: AppTextStyles.caption),
                  Text(
                    isPaid && fine.paidAt != null
                        ? '${fine.paidAt!.day}/${fine.paidAt!.month}/${fine.paidAt!.year}'
                        : '${fine.deadline.day}/${fine.deadline.month}/${fine.deadline.year}',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.97, 0.97));
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.titleSmall
                  .copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: 12),
          ...rows.asMap().entries.map((e) => Column(
                children: [
                  e.value,
                  if (e.key < rows.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child:
                          Divider(height: 1, color: AppColors.divider),
                    ),
                ],
              )),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildMapCard(FineModel fine) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mock map
          Container(
            height: 160,
            decoration: const BoxDecoration(
              color: Color(0xFF0D1928),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: CustomPaint(
              painter: _MockMapPainter(fine.latitude, fine.longitude),
              size: Size.infinite,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.error.withValues(alpha: 0.4),
                              blurRadius: 12),
                        ],
                      ),
                      child: const Icon(Icons.location_on_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(fine.location, style: AppTextStyles.bodySmall),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isMono;
  const _DetailRow(
      {required this.label,
      required this.value,
      this.valueColor,
      this.isMono = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: Text(label, style: AppTextStyles.bodySmall)),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: isMono
                ? AppTextStyles.mono.copyWith(
                    fontSize: 12,
                    color: valueColor ?? AppColors.primary)
                : AppTextStyles.bodyMedium.copyWith(
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

class _ContestButton extends StatelessWidget {
  final FineModel fine;
  const _ContestButton({required this.fine});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(14),
          color: AppColors.surfaceVariant,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.balance_rounded,
                size: 18, color: AppColors.textTertiary),
            const SizedBox(width: 8),
            Text('Contester cette amende',
                style: AppTextStyles.buttonMedium
                    .copyWith(color: AppColors.textTertiary)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}

class _MockMapPainter extends CustomPainter {
  final double lat;
  final double lng;
  _MockMapPainter(this.lat, this.lng);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final roadPaint = Paint()
      ..color = AppColors.divider.withValues(alpha: 0.5)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.45),
        Offset(size.width, size.height * 0.45), roadPaint);
    canvas.drawLine(Offset(size.width * 0.5, 0),
        Offset(size.width * 0.5, size.height), roadPaint);
    final blockPaint = Paint()
      ..color = AppColors.surfaceVariant.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.1, size.height * 0.1, 60, 40), blockPaint);
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.55, 80, 50),
        blockPaint);
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.65, size.height * 0.1, 50, 35),
        blockPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
