import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/fine_model.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../data/providers.dart';

class CitizenDashboard extends ConsumerWidget {
  const CitizenDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finesAsync = ref.watch(myFinesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.refresh(myFinesProvider.future);
        },
        child: finesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Impossible de charger vos contraventions.\n$e',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ),
          data: (fines) {
            final pending = fines
                .where((f) =>
                    f.status == FineStatus.pending ||
                    f.status == FineStatus.overdue)
                .toList();
            final totalDebt = pending.fold<int>(0, (s, f) => s + f.amount);
            return CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 16),
                      _buildProfileBanner(totalDebt, pending.length),
                      const SizedBox(height: 24),
                      _buildActiveFines(context, pending),
                      const SizedBox(height: 24),
                      _buildPaidHistory(context, fines),
                      const SizedBox(height: 24),
                      _buildAlerts(),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.congoGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.congoGreen.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.congoGreen, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Circulation+', style: AppTextStyles.titleSmall),
              Text(
                'PORTAIL CITOYEN',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.congoGreen,
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/citizen/notifications'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(Icons.notifications_outlined, size: 20, color: AppColors.textSecondary),
                ),
                Positioned(
                  top: -2, right: -2,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.error, shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.divider),
      ),
    );
  }

  Widget _buildProfileBanner(int totalDebt, int pendingCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            if (pendingCount > 0) ...[const Color(0xFF1A0E0A), const Color(0xFF1C1008)]
            else ...[const Color(0xFF0A1A10), const Color(0xFF0C1C12)],
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: pendingCount > 0
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: pendingCount > 0
                      ? AppColors.warningGradient
                      : AppColors.successGradient,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('TN',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thierry Nguesso', style: AppTextStyles.titleMedium),
                    Text('+242 06 789 0123', style: AppTextStyles.bodySmall),
                    Text('CG-1988-047821', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _BannerStat(
                label: 'Amendes actives',
                value: '$pendingCount',
                color: pendingCount > 0 ? AppColors.warning : AppColors.success,
              ),
              _VerticalDivider(),
              _BannerStat(
                label: 'Total dû',
                value: totalDebt > 0 ? '${(totalDebt / 1000).toStringAsFixed(0)}K FCFA' : '0 FCFA',
                color: totalDebt > 0 ? AppColors.error : AppColors.success,
              ),
              _VerticalDivider(),
              const _BannerStat(
                label: 'Points permis',
                value: '9/12',
                color: AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2);
  }

  Widget _buildActiveFines(BuildContext context, List<FineModel> fines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text('Amendes à payer', style: AppTextStyles.titleMedium),
            const Spacer(),
            if (fines.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${fines.length} active${fines.length > 1 ? 's' : ''}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (fines.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 40, color: AppColors.success),
                  const SizedBox(height: 8),
                  Text('Aucune amende en attente', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success)),
                ],
              ),
            ),
          )
        else
          ...fines.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CitizenFineCard(fine: entry.value)
                .animate(delay: Duration(milliseconds: entry.key * 100))
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1),
          )),
      ],
    );
  }

  Widget _buildPaidHistory(BuildContext context, List<FineModel> allFines) {
    final paid = allFines.where((f) => f.status == FineStatus.paid).toList();
    if (paid.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4, height: 18,
              decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 10),
            Text('Historique paiements', style: AppTextStyles.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        ...paid.map((fine) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _PaidFineRow(fine: fine),
        )),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4, height: 18,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 10),
            Text('Alertes & rappels', style: AppTextStyles.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        const _AlertCard(
          icon: Icons.credit_card_off_outlined,
          title: 'Renouvellement permis',
          body: 'Votre permis expire dans ~30 jours. Rendez-vous à la Préfecture.',
          color: AppColors.warning,
        ),
        const SizedBox(height: 8),
        const _AlertCard(
          icon: Icons.gavel_rounded,
          title: 'Amende en retard',
          body: 'L\'amende CP-2024-000892 est en retard de 45 jours. Pénalité +50%.',
          color: AppColors.error,
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _CitizenFineCard extends StatelessWidget {
  final FineModel fine;
  const _CitizenFineCard({required this.fine});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/citizen/fine/${fine.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: fine.isOverdue
                ? AppColors.error.withValues(alpha: 0.4)
                : AppColors.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (fine.isOverdue ? AppColors.error : AppColors.warning).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.gavel_rounded,
                    color: fine.isOverdue ? AppColors.error : AppColors.warning,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fine.infractionLabel,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(fine.reference,
                          style: AppTextStyles.mono.copyWith(fontSize: 11, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
                StatusBadge.fromFineStatus(fine.status),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Montant', style: AppTextStyles.caption),
                    Text(
                      '${(fine.amount / 1000).toStringAsFixed(0)} 000 FCFA',
                      style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Échéance', style: AppTextStyles.caption),
                    Text(
                      '${fine.deadline.day}/${fine.deadline.month}/${fine.deadline.year}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: fine.isOverdue ? AppColors.error : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Payer',
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaidFineRow extends StatelessWidget {
  final FineModel fine;
  const _PaidFineRow({required this.fine});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/citizen/receipt/${fine.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fine.infractionLabel, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
                  Text(fine.paymentMethod ?? '', style: AppTextStyles.caption),
                ],
              ),
            ),
            Text(
              '${(fine.amount / 1000).toStringAsFixed(0)}K FCFA',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.success),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.receipt_outlined, size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _BannerStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.titleMedium.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppColors.divider);
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _AlertCard({required this.icon, required this.title, required this.body, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelSmall.copyWith(color: color)),
                const SizedBox(height: 4),
                Text(body, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
