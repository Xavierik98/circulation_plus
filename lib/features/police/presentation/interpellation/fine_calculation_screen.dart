import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/models/infraction_model.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../data/providers.dart';

class FineCalculationScreen extends ConsumerWidget {
  const FineCalculationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedInfractionsProvider);

    // Montant de base : somme des montantBase des infractions sélectionnées
    final baseAmount = selected.fold<int>(0, (sum, i) => sum + i.fineAmount);
    // + 1 000 XAF frais plateforme Circulation+
    const devFee = 1000;
    final total = baseAmount + devFee;
    final deadline = DateTime.now().add(const Duration(days: 30));

    if (selected.isEmpty) {
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
          title: Text('Calcul de l\'amende', style: AppTextStyles.titleSmall),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 48),
              const SizedBox(height: 16),
              Text('Aucune infraction sélectionnée',
                  style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              Text('Retournez à l\'étape précédente et sélectionnez au moins une infraction.',
                  style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
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

            // Hero montant total
            _buildAmountHero(total, devFee),

            const SizedBox(height: 20),

            // Détail des infractions
            _buildBreakdown(selected, baseAmount, devFee, total),

            const SizedBox(height: 20),

            // Délai de paiement
            _buildDeadlineCard(deadline),

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

  Widget _buildAmountHero(int total, int devFee) {
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
            'Montant total à payer',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: total),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text(
                '${_fmt(value)} FCFA',
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            'dont $devFee XAF frais plateforme Circulation+',
            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 12),
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

  Widget _buildBreakdown(
    List<InfractionType> infractions,
    int baseAmount,
    int devFee,
    int total,
  ) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Détail des infractions', style: AppTextStyles.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${infractions.length} infraction${infractions.length > 1 ? 's' : ''}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...infractions.asMap().entries.map((entry) => Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(entry.value.icon,
                          style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.value.labelFr,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        Text(entry.value.code,
                            style: AppTextStyles.mono
                                .copyWith(fontSize: 10, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_fmt(entry.value.fineAmount)} F',
                    style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.textPrimary),
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
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),

          // Frais plateforme
          Row(
            children: [
              const Icon(Icons.phone_android_rounded, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Frais plateforme Circulation+',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary)),
              ),
              Text('${_fmt(devFee)} F',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textTertiary)),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          Row(
            children: [
              const Spacer(),
              Text('TOTAL', style: AppTextStyles.labelSmall),
              const SizedBox(width: 16),
              Text(
                '${_fmt(total)} FCFA',
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
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
                Text('Délai de paiement',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning)),
                Text(
                  '${deadline.day.toString().padLeft(2, '0')}/'
                  '${deadline.month.toString().padLeft(2, '0')}/'
                  '${deadline.year}',
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
            child: Text('30 jours',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning)),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  /// Formatte un montant XAF : 24000 → "24 000"
  String _fmt(int amount) {
    if (amount < 1000) return amount.toString();
    final thousands = amount ~/ 1000;
    final remainder = amount % 1000;
    if (remainder == 0) return '$thousands 000';
    return '$thousands ${remainder.toString().padLeft(3, '0')}';
  }
}
