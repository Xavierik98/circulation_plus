import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/fine_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../data/repositories.dart';
import '../../../data/api_client.dart';

// Provider local: résultat de recherche conducteur
final _driverSearchProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);
final _driverSearchLoadingProvider = StateProvider<bool>((ref) => false);
final _driverSearchErrorProvider = StateProvider<String?>((ref) => null);

class DriverHistoryScreen extends ConsumerStatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  ConsumerState<DriverHistoryScreen> createState() =>
      _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends ConsumerState<DriverHistoryScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  String _searchType = 'plate'; // 'plate' | 'license'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim().toUpperCase();
    if (query.isEmpty) return;

    ref.read(_driverSearchErrorProvider.notifier).state = null;
    ref.read(_driverSearchProvider.notifier).state = null;
    ref.read(_driverSearchLoadingProvider.notifier).state = true;

    try {
      final result = await DriverRepository().search(
        plate: _searchType == 'plate' ? query : null,
        license: _searchType == 'license' ? query : null,
      );
      if (mounted) {
        ref.read(_driverSearchProvider.notifier).state = result;
      }
    } on ApiException catch (e) {
      if (mounted) {
        ref.read(_driverSearchErrorProvider.notifier).state = e.message;
      }
    } catch (e) {
      if (mounted) {
        ref.read(_driverSearchErrorProvider.notifier).state =
            'Erreur réseau. Vérifiez votre connexion.';
      }
    } finally {
      if (mounted) {
        ref.read(_driverSearchLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = ref.watch(_driverSearchProvider);
    final isLoading = ref.watch(_driverSearchLoadingProvider);
    final error = ref.watch(_driverSearchErrorProvider);

    final fines = driver != null
        ? (driver['fines'] as List<dynamic>? ?? [])
        : <dynamic>[];
    final unpaid = fines
        .where((f) {
          final s = (f as Map<String, dynamic>)['status'] as String? ?? '';
          return s != 'PAID';
        })
        .cast<Map<String, dynamic>>()
        .toList();
    final paid = fines
        .where((f) {
          final s = (f as Map<String, dynamic>)['status'] as String? ?? '';
          return s == 'PAID';
        })
        .cast<Map<String, dynamic>>()
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Text('Historique conducteur',
                style: AppTextStyles.titleMedium),
            bottom: driver != null
                ? TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.gold,
                    labelColor: AppColors.gold,
                    unselectedLabelColor: AppColors.textTertiary,
                    indicatorWeight: 2,
                    labelStyle: AppTextStyles.labelMedium,
                    tabs: [
                      Tab(text: 'En attente (${unpaid.length})'),
                      Tab(text: 'Payées (${paid.length})'),
                    ],
                  )
                : null,
          ),
        ],
        body: Column(
          children: [
            // ── Barre de recherche ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  // Type selector
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        _TypeBtn(
                          label: 'Par plaque',
                          icon: Icons.directions_car_rounded,
                          isSelected: _searchType == 'plate',
                          onTap: () =>
                              setState(() => _searchType = 'plate'),
                        ),
                        _TypeBtn(
                          label: 'Par permis',
                          icon: Icons.credit_card_rounded,
                          isSelected: _searchType == 'license',
                          onTap: () =>
                              setState(() => _searchType = 'license'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Search field + button
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textCapitalization: TextCapitalization.characters,
                          style: AppTextStyles.mono
                              .copyWith(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: _searchType == 'plate'
                                ? 'Ex : BZV-4521-A'
                                : 'Ex : BZV-2024-047821',
                            prefixIcon: Icon(
                              _searchType == 'plate'
                                  ? Icons.directions_car_rounded
                                  : Icons.credit_card_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                          ),
                          onSubmitted: (_) => _search(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: isLoading ? null : _search,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.search_rounded,
                                  color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 12),

            // ── Résultats ───────────────────────────────────────
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(error,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.error))),
                    ],
                  ),
                ).animate().fadeIn(),
              )
            else if (driver == null && !isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.manage_search_rounded,
                          size: 56,
                          color: AppColors.textDisabled.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('Rechercher un conducteur',
                          style: AppTextStyles.titleSmall
                              .copyWith(color: AppColors.textTertiary)),
                      const SizedBox(height: 6),
                      Text(
                        'Saisissez une plaque d\'immatriculation\nou un numéro de permis de conduire.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textDisabled),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (driver != null) ...[
              // Driver card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _DriverCard(driver: driver),
              ),
              const SizedBox(height: 4),
              // Fine tabs
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _FineList(fines: unpaid),
                    _FineList(fines: paid),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _TypeBtn(
      {required this.label,
      required this.icon,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textTertiary),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color:
                      isSelected ? Colors.white : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final prenom = driver['prenom'] as String? ?? '';
    final nom = driver['nom'] as String? ?? '';
    final fullName = '$prenom $nom'.trim();
    final initials = '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}';
    final license = driver['numeroPermis'] as String? ?? '—';
    final phone = driver['telephone'] as String? ?? '—';
    final totalFines = (driver['_count']?['fines'] as num?)?.toInt()
        ?? (driver['fines'] as List?)?.length
        ?? 0;

    return PremiumCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials.isNotEmpty ? initials : '??',
                style: AppTextStyles.titleMedium
                    .copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName.isNotEmpty ? fullName : 'Conducteur',
                    style: AppTextStyles.titleSmall),
                const SizedBox(height: 2),
                Text(license,
                    style: AppTextStyles.mono.copyWith(
                        fontSize: 11,
                        color: AppColors.textTertiary)),
                const SizedBox(height: 2),
                Text(phone,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$totalFines PV',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.primary, fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _FineList extends StatelessWidget {
  final List<Map<String, dynamic>> fines;
  const _FineList({required this.fines});

  @override
  Widget build(BuildContext context) {
    if (fines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text('Aucune amende', style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: fines.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final fine = fines[index];
        return _FineCard(fine: fine)
            .animate(delay: Duration(milliseconds: index * 80))
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.05, end: 0);
      },
    );
  }
}

class _FineCard extends StatelessWidget {
  final Map<String, dynamic> fine;
  const _FineCard({required this.fine});

  FineStatus _status() {
    switch (fine['status'] as String?) {
      case 'PAID':
        return FineStatus.paid;
      case 'OVERDUE':
        return FineStatus.overdue;
      case 'CONTESTED':
        return FineStatus.contested;
      default:
        return FineStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final infraction =
        fine['infractionType'] as Map<String, dynamic>? ?? {};
    final label = infraction['libelle'] as String? ?? '—';
    final reference = fine['reference'] as String? ?? '—';
    final status = _status();
    final amount = (fine['montantTotal'] as num?)?.toInt() ?? 0;
    final issuedRaw = fine['verbaliseLe'] as String?;
    final deadlineRaw = fine['dateEcheance'] as String?;
    final issuedAt = issuedRaw != null
        ? DateTime.tryParse(issuedRaw)?.toLocal()
        : null;
    final deadline = deadlineRaw != null
        ? DateTime.tryParse(deadlineRaw)?.toLocal()
        : null;
    final isOverdue = status == FineStatus.pending &&
        deadline != null &&
        deadline.isBefore(DateTime.now());

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary)),
              ),
              StatusBadge.fromFineStatus(status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.tag_rounded,
                  size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(reference,
                  style: AppTextStyles.mono
                      .copyWith(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              if (issuedAt != null)
                _InfoChip(
                    icon: Icons.schedule_outlined,
                    label:
                        '${issuedAt.day}/${issuedAt.month}/${issuedAt.year}'),
              const Spacer(),
              Text(
                '${(amount / 1000).toStringAsFixed(0)}K FCFA',
                style: AppTextStyles.titleSmall
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
          if (deadline != null &&
              (status == FineStatus.pending ||
                  status == FineStatus.overdue)) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.event_outlined,
                    size: 12,
                    color: isOverdue ? AppColors.error : AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  'Échéance : ${deadline.day}/${deadline.month}/${deadline.year}',
                  style: AppTextStyles.caption.copyWith(
                    color: isOverdue ? AppColors.error : AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
