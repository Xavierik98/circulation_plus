import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/models/infraction_model.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../data/providers.dart';
import '../../../../shared/models/interpellation_state.dart';

class InfractionSelectionScreen extends ConsumerStatefulWidget {
  const InfractionSelectionScreen({super.key});

  @override
  ConsumerState<InfractionSelectionScreen> createState() =>
      _InfractionSelectionScreenState();
}

class _InfractionSelectionScreenState extends ConsumerState<InfractionSelectionScreen> {
  InfractionCategory? _selectedCategory;

  List<InfractionType> _filter(List<InfractionType> all) {
    if (_selectedCategory == null) return all;
    return all.where((i) => i.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedInfractionsProvider);
    final totalAmount = selected.fold<int>(0, (sum, i) => sum + i.fineAmount);

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
            Text('Sélection des infractions', style: AppTextStyles.titleSmall),
            Text('Étape 4 sur 6', style: AppTextStyles.caption),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.67,
            backgroundColor: AppColors.surfaceVariant,
            color: AppColors.primary,
            minHeight: 3,
          ),
        ),
      ),
      body: Column(
        children: [
          // Category filter
          _buildCategoryFilter(),

          // List
          Expanded(
            child: ref.watch(infractionsProvider).when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Catalogue indisponible.\n$e',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ),
                  data: (all) {
                    final list = _filter(all);
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final inf = list[index];
                        final isSelected =
                            selected.any((s) => s.id == inf.id);
                        return _InfractionTile(
                          infraction: inf,
                          isSelected: isSelected,
                          onToggle: () {
                            final current = List<InfractionType>.from(
                                ref.read(selectedInfractionsProvider));
                            if (isSelected) {
                              current.removeWhere((s) => s.id == inf.id);
                            } else {
                              current.add(inf);
                            }
                            // Mise à jour des deux providers simultanément
                            ref.read(selectedInfractionsProvider.notifier)
                                .state = current;
                            ref.read(interpellationProvider.notifier)
                                .setInfractions(current);
                          },
                        )
                            .animate(delay: Duration(milliseconds: index * 50))
                            .fadeIn(duration: 300.ms)
                            .slideX(begin: 0.05, end: 0);
                      },
                    );
                  },
                ),
          ),

          // Bottom total bar
          if (selected.isNotEmpty)
            _buildBottomBar(selected, totalAmount),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      (null, 'Tout', Icons.grid_view_rounded),
      (InfractionCategory.speed, 'Vitesse', Icons.speed_rounded),
      (InfractionCategory.safety, 'Sécurité', Icons.health_and_safety_rounded),
      (InfractionCategory.documents, 'Documents', Icons.description_outlined),
      (InfractionCategory.behavior, 'Comportement', Icons.psychology_rounded),
      (InfractionCategory.parking, 'Parking', Icons.local_parking_rounded),
    ];

    return Container(
      height: 48,
      color: AppColors.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (cat, label, icon) = categories[i];
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13,
                      color: isSelected ? Colors.white : AppColors.textTertiary),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _fmtAmount(int amount) {
    if (amount < 1000) return amount.toString();
    final t = amount ~/ 1000;
    final r = amount % 1000;
    return r == 0 ? '$t 000' : '$t ${r.toString().padLeft(3, '0')}';
  }

  Widget _buildBottomBar(List<InfractionType> selected, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${selected.length} infraction${selected.length > 1 ? 's' : ''}',
                    style: AppTextStyles.bodySmall,
                  ),
                  Text(
                    '${_fmtAmount(total)} FCFA',
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 180,
              child: PremiumButton(
                label: 'Continuer',
                icon: Icons.arrow_forward_rounded,
                height: 48,
                onPressed: () => context.push('/police/fine-calc'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfractionTile extends StatelessWidget {
  final InfractionType infraction;
  final bool isSelected;
  final VoidCallback onToggle;

  const _InfractionTile({
    required this.infraction,
    required this.isSelected,
    required this.onToggle,
  });

  Color get _categoryColor {
    return switch (infraction.category) {
      InfractionCategory.speed => AppColors.error,
      InfractionCategory.safety => AppColors.warning,
      InfractionCategory.documents => AppColors.info,
      InfractionCategory.behavior => AppColors.accent,
      InfractionCategory.parking => AppColors.textTertiary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGlow
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _categoryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(infraction.icon, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(infraction.labelFr, style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  )),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          infraction.code,
                          style: AppTextStyles.mono.copyWith(fontSize: 9, color: AppColors.textTertiary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (infraction.pointsDeducted > 0)
                        Text(
                          '-${infraction.pointsDeducted} pts',
                          style: AppTextStyles.caption.copyWith(color: AppColors.error),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(infraction.fineAmount / 1000).toStringAsFixed(0)}K',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                Text('FCFA', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
