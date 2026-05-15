import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/fine_model.dart';
import '../../../shared/models/driver_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/status_badge.dart';

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  bool _showSearch = false;
  final DriverModel driver = DriverModel.mockDriver;

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

  @override
  Widget build(BuildContext context) {
    final fines = FineModel.mockFines;
    final unpaid = fines.where((f) => f.status != FineStatus.paid).toList();
    final paid = fines.where((f) => f.status == FineStatus.paid).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Text('Historique conducteur', style: AppTextStyles.titleMedium),
            actions: [
              IconButton(
                onPressed: () => setState(() => _showSearch = !_showSearch),
                icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded),
                color: AppColors.textSecondary,
              ),
            ],
            bottom: TabBar(
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
            ),
          ),
        ],
        body: Column(
          children: [
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Plaque, nom, référence...',
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                    suffixIcon: Icon(Icons.tune_rounded, size: 20),
                  ),
                ).animate().fadeIn(duration: 300.ms),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildDriverCard(),
            ),

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
        ),
      ),
    );
  }

  Widget _buildDriverCard() {
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
                '${driver.firstName[0]}${driver.lastName[0]}',
                style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver.fullName, style: AppTextStyles.titleSmall),
                const SizedBox(height: 2),
                Text(driver.licenseNumber, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Permis valide',
                  style: AppTextStyles.caption.copyWith(color: AppColors.success, fontSize: 10),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${driver.remainingPoints}/${driver.totalPoints} pts',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _FineList extends StatelessWidget {
  final List<FineModel> fines;
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
  final FineModel fine;
  const _FineCard({required this.fine});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(fine.infractionLabel, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
              ),
              StatusBadge.fromFineStatus(fine.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.tag_rounded, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(fine.reference, style: AppTextStyles.mono.copyWith(fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(icon: Icons.directions_car_outlined, label: fine.vehiclePlate),
              const SizedBox(width: 8),
              _InfoChip(icon: Icons.location_on_outlined, label: fine.location.split(',').first),
              const Spacer(),
              Text(
                '${(fine.amount / 1000).toStringAsFixed(0)}K FCFA',
                style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_outlined, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                '${fine.issuedAt.day}/${fine.issuedAt.month}/${fine.issuedAt.year}',
                style: AppTextStyles.caption,
              ),
              const Spacer(),
              if (fine.status == FineStatus.pending || fine.status == FineStatus.overdue)
                Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 12,
                      color: fine.isOverdue ? AppColors.error : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Échéance: ${fine.deadline.day}/${fine.deadline.month}/${fine.deadline.year}',
                      style: AppTextStyles.caption.copyWith(
                        color: fine.isOverdue ? AppColors.error : AppColors.warning,
                      ),
                    ),
                  ],
                ),
            ],
          ),
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
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
