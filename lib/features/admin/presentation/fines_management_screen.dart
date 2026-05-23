import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/fine_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../data/repositories.dart';

// ─── Providers locaux ─────────────────────────────────────────────────────────
final _statusFilterProvider = StateProvider<String?>((ref) => null);
final _pageProvider = StateProvider<int>((ref) => 1);

final _adminFinesProvider =
    FutureProvider.autoDispose<({List<FineModel> items, int total})>((ref) async {
  final status = ref.watch(_statusFilterProvider);
  final page = ref.watch(_pageProvider);
  final page_ = await FineRepository().list(
    status: status,
    page: page,
    limit: 25,
  );
  return (items: page_.items, total: page_.total);
});

class FinesManagementScreen extends ConsumerWidget {
  const FinesManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFines = ref.watch(_adminFinesProvider);
    final statusFilter = ref.watch(_statusFilterProvider);
    final page = ref.watch(_pageProvider);

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
        title: Text('Toutes les amendes', style: AppTextStyles.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => ref.invalidate(_adminFinesProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration:
                const BoxDecoration(gradient: AppColors.congoFlagGradient),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Status filter chips ──────────────────────────────────
          _FilterBar(
            selected: statusFilter,
            onSelect: (s) {
              ref.read(_statusFilterProvider.notifier).state = s;
              ref.read(_pageProvider.notifier).state = 1;
            },
          ),

          // ── Fines list ───────────────────────────────────────────
          Expanded(
            child: asyncFines.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('Erreur de chargement',
                        style: AppTextStyles.titleSmall),
                    const SizedBox(height: 8),
                    Text(e.toString(),
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(_adminFinesProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (result) {
                if (result.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 56,
                            color: AppColors.textDisabled),
                        const SizedBox(height: 16),
                        Text('Aucune amende',
                            style: AppTextStyles.titleSmall
                                .copyWith(color: AppColors.textTertiary)),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Count banner
                    Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '${result.total} PV',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.textTertiary),
                          ),
                          const Spacer(),
                          if (result.total > 25) ...[
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded,
                                  size: 20),
                              onPressed: page > 1
                                  ? () => ref
                                      .read(_pageProvider.notifier)
                                      .state = page - 1
                                  : null,
                              color: page > 1
                                  ? AppColors.primary
                                  : AppColors.textDisabled,
                            ),
                            Text('$page / ${(result.total / 25).ceil()}',
                                style: AppTextStyles.caption),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded,
                                  size: 20),
                              onPressed: page < (result.total / 25).ceil()
                                  ? () => ref
                                      .read(_pageProvider.notifier)
                                      .state = page + 1
                                  : null,
                              color: page < (result.total / 25).ceil()
                                  ? AppColors.primary
                                  : AppColors.textDisabled,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: result.items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final fine = result.items[i];
                          return _FineCard(fine: fine)
                              .animate(
                                  delay:
                                      Duration(milliseconds: i.clamp(0, 8) * 50))
                              .fadeIn(duration: 300.ms)
                              .slideX(begin: 0.04, end: 0);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? selected;
  final void Function(String?) onSelect;
  const _FilterBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final filters = [
      (null, 'Toutes', Icons.receipt_long_rounded),
      ('PENDING', 'En attente', Icons.schedule_rounded),
      ('PAID', 'Payées', Icons.check_circle_rounded),
      ('OVERDUE', 'Arriérées', Icons.warning_amber_rounded),
      ('CONTESTED', 'Contestées', Icons.balance_rounded),
    ];

    return Container(
      height: 48,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: filters.map((f) {
          final isSelected = selected == f.$1;
          return GestureDetector(
            onTap: () => onSelect(f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : AppColors.cardBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(f.$3,
                      size: 12,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    f.$2,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FineCard extends StatelessWidget {
  final FineModel fine;
  const _FineCard({required this.fine});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: () => context.push('/citizen/fine/${fine.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fine.infractionLabel,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(fine.reference,
                        style: AppTextStyles.mono.copyWith(
                            fontSize: 11,
                            color: AppColors.textTertiary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge.fromFineStatus(fine.status),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          Row(
            children: [
              _Chip(
                icon: Icons.person_outline_rounded,
                label: fine.driverName.isNotEmpty
                    ? fine.driverName
                    : '—',
              ),
              const SizedBox(width: 8),
              _Chip(
                icon: Icons.directions_car_outlined,
                label: fine.vehiclePlate.isNotEmpty
                    ? fine.vehiclePlate
                    : '—',
              ),
              const Spacer(),
              Text(
                '${(fine.amount / 1000).toStringAsFixed(0)}K FCFA',
                style: AppTextStyles.titleSmall
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _Chip(
                icon: Icons.badge_outlined,
                label: fine.officerBadge.isNotEmpty
                    ? fine.officerBadge
                    : '—',
              ),
              const Spacer(),
              Text(
                '${fine.issuedAt.day}/${fine.issuedAt.month}/${fine.issuedAt.year}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textTertiary),
        const SizedBox(width: 3),
        Text(label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            )),
      ],
    );
  }
}
