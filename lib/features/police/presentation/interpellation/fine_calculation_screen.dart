import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/models/infraction_model.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../shared/widgets/glass_card.dart';

class FineCalculationScreen extends StatelessWidget {
  const FineCalculationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock selected infractions
    final selected = [InfractionType.all[1], InfractionType.all[8]];
    final baseAmount = selected.fold<int>(0, (sum, i) => sum + i.fineAmount);
    const lateMultiplier = 1.0;
    final total = (baseAmount * lateMultiplier).toInt();
    final deadline = DateTime.now().add(const Duration(days: 30));

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
            Text('Calcul de l\'amende', style: AppTextStyles.titleSmall),
            Text('Étape 4 sur 5', style: AppTextStyles.caption),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.8,
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

            // Total amount hero
            _buildAmountHero(total),

            const SizedBox(height: 20),

            // Breakdown
            _buildBreakdown(selected, total),

            const SizedBox(height: 20),

            // Driver summary
            _buildDriverSummary(),

            const SizedBox(height: 20),

            // Deadline
            _buildDeadlineCard(deadline),

            const SizedBox(height: 20),

            // Reference
            _buildReferenceCard(),

            const SizedBox(height: 24),

            PremiumButton(
              label: 'Procéder à la signature',
              icon: Icons.draw_outlined,
              onPressed: () => context.push('/police/signature'),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountHero(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1D3A), Color(0xFF162035)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Montant total de l\'amende',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: total),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text(
                '${(value / 1000).toStringAsFixed(0)} 000 FCFA',
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Text(
              '+50% si non payé dans 30 jours',
              style: AppTextStyles.caption.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildBreakdown(List<InfractionType> infractions, int total) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Détail des infractions', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          ...infractions.asMap().entries.map((entry) => Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            entry.value.icon,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.value.labelFr, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                            Text(entry.value.code, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      Text(
                        '${(entry.value.fineAmount / 1000).toStringAsFixed(0)} 000 F',
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  if (entry.key < infractions.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),
                ],
              )),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              Text('TOTAL', style: AppTextStyles.labelSmall),
              const SizedBox(width: 16),
              Text(
                '${(total / 1000).toStringAsFixed(0)} 000 FCFA',
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }

  Widget _buildDriverSummary() {
    return PremiumCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('TN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thierry Nguesso', style: AppTextStyles.titleSmall),
                Text('BZV-2024-047821', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Toyota Corolla', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
              Text('BZV-4521-A', style: AppTextStyles.mono.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildDeadlineCard(DateTime deadline) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Délai de paiement', style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning)),
                Text(
                  '${deadline.day.toString().padLeft(2,'0')}/${deadline.month.toString().padLeft(2,'0')}/${deadline.year}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('30 jours', style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning)),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  Widget _buildReferenceCard() {
    return PremiumCard(
      child: Row(
        children: [
          const Icon(Icons.tag_rounded, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Référence de l\'amende', style: AppTextStyles.bodySmall),
                const SizedBox(height: 4),
                Text('CP-2024-002847', style: AppTextStyles.mono.copyWith(fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textTertiary),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}
