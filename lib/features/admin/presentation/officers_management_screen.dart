import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/officer_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/status_badge.dart';

class OfficersManagementScreen extends StatefulWidget {
  const OfficersManagementScreen({super.key});

  @override
  State<OfficersManagementScreen> createState() => _OfficersManagementScreenState();
}

class _OfficersManagementScreenState extends State<OfficersManagementScreen> {
  OfficerStatus? _filterStatus;
  String _searchQuery = '';

  List<OfficerModel> get _filteredOfficers {
    var officers = OfficerModel.mockOfficers;
    if (_filterStatus != null) {
      officers = officers.where((o) => o.status == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      officers = officers.where((o) =>
          o.fullName.toLowerCase().contains(q) ||
          o.badgeNumber.toLowerCase().contains(q) ||
          o.zone.toLowerCase().contains(q)).toList();
    }
    return officers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Gestion des agents', style: AppTextStyles.titleMedium),
        actions: [
          IconButton(icon: const Icon(Icons.person_add_outlined, size: 20), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient)),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterBar(),
          _buildSummaryRow(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredOfficers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                return _OfficerCard(officer: _filteredOfficers[i])
                    .animate(delay: Duration(milliseconds: i * 60))
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.05);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Rechercher un agent...',
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      (null, 'Tous'),
      (OfficerStatus.active, 'En service'),
      (OfficerStatus.inactive, 'Hors service'),
      (OfficerStatus.suspended, 'Suspendus'),
    ];

    return Container(
      height: 44,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: filters.map((f) {
          final isSelected = _filterStatus == f.$1;
          return GestureDetector(
            onTap: () => setState(() => _filterStatus = f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.info : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.info : AppColors.cardBorder),
              ),
              child: Center(
                child: Text(f.$2,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textTertiary,
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final all = OfficerModel.mockOfficers;
    final active = all.where((o) => o.status == OfficerStatus.active).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _SummaryChip(label: 'Total', value: '${all.length}', color: AppColors.textTertiary),
          const SizedBox(width: 12),
          _SummaryChip(label: 'Actifs', value: '$active', color: AppColors.success),
          const SizedBox(width: 12),
          _SummaryChip(label: 'Hors service', value: '${all.length - active}', color: AppColors.warning),
        ],
      ),
    );
  }
}

class _OfficerCard extends StatelessWidget {
  final OfficerModel officer;
  const _OfficerCard({required this.officer});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(officer.avatarInitials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(officer.fullName, style: AppTextStyles.titleSmall),
                    const SizedBox(height: 2),
                    Text(officer.rank, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 2),
                    Text(officer.badgeNumber,
                        style: AppTextStyles.mono.copyWith(fontSize: 10, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge.fromOfficerStatus(officer.status),
                  const SizedBox(height: 4),
                  if (officer.lastActivity != null)
                    Text(
                      _formatLastActivity(officer.lastActivity!),
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          Row(
            children: [
              _OfficerStat(label: 'Total', value: '${officer.totalInfractions}', icon: Icons.gavel_rounded),
              _OfficerStat(
                label: 'Aujourd\'hui',
                value: '${officer.todayInfractions}',
                icon: Icons.today_rounded,
                color: AppColors.primary,
              ),
              _OfficerStat(
                label: 'Revenus',
                value: '${(officer.totalRevenue / 1000000).toStringAsFixed(1)}M',
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(officer.zone, style: AppTextStyles.caption),
              const Spacer(),
              const Icon(Icons.phone_outlined, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(officer.phone, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  String _formatLastActivity(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }
}

class _OfficerStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  const _OfficerStat({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.textTertiary),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.labelSmall.copyWith(color: color ?? AppColors.textPrimary)),
              Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppTextStyles.labelSmall.copyWith(color: color)),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
