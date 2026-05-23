import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/pnc_badge.dart';
import '../../../data/providers.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final stats = statsAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 20),
                _buildKpiGrid(stats),
                const SizedBox(height: 24),
                _buildRevenueChart(stats),
                const SizedBox(height: 24),
                _buildGlobalRates(stats),
                const SizedBox(height: 24),
                _buildTopOfficers(context),
                const SizedBox(height: 24),
                _buildQuickLinks(context),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(
        children: [
          const PncBadge(size: 36, showGlow: false),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Circulation+', style: AppTextStyles.titleSmall),
              Text(
                'ADMINISTRATION NATIONALE',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.gold,
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.5),
                          blurRadius: 6)
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text('Système actif',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.success)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/admin/settings'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(Icons.settings_outlined,
                  size: 20, color: AppColors.textSecondary),
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

  Widget _buildHeader() {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vue nationale', style: AppTextStyles.headlineSmall),
        Text(
          'Rapport du ${now.day}/${now.month}/${now.year} — République du Congo',
          style: AppTextStyles.bodySmall,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildKpiGrid(Map<String, dynamic>? stats) {
    final totalFines = (stats?['totalFinesThisMonth'] as num?)?.toInt() ?? 0;
    final revenue = (stats?['totalRevenueThisMonth'] as num?)?.toDouble() ?? 0.0;
    final paymentRate = (stats?['paymentRate'] as num?)?.toInt() ?? 0;
    final activeOfficers = (stats?['activeOfficers'] as num?)?.toInt() ?? 0;
    final totalOfficers = (stats?['totalOfficers'] as num?)?.toInt() ?? 0;
    final overdueFines = (stats?['overdueFines'] as num?)?.toInt() ?? 0;

    final revStr = revenue >= 1000000
        ? '${(revenue / 1000000).toStringAsFixed(1)}M'
        : revenue >= 1000
            ? '${(revenue / 1000).toStringAsFixed(0)}K'
            : revenue.toStringAsFixed(0);

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.45,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        LargeStatCard(
          label: 'Infractions ce mois',
          value: stats == null ? '—' : _fmtNum(totalFines),
          description: 'Ce mois',
          icon: Icons.gavel_rounded,
          gradient: AppColors.primaryGradient,
        ),
        LargeStatCard(
          label: 'Revenus collectés',
          value: stats == null ? '—' : revStr,
          description: 'FCFA — Ce mois',
          icon: Icons.account_balance_outlined,
          gradient: AppColors.successGradient,
        ),
        StatCard(
          label: 'Taux de paiement',
          value: stats == null ? '—' : '$paymentRate%',
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppColors.success,
          animationDelay: 200,
        ),
        StatCard(
          label: 'Agents en service',
          value: stats == null ? '—' : '$activeOfficers',
          subtitle: stats == null ? null : 'sur $totalOfficers au total',
          icon: Icons.badge_outlined,
          iconColor: AppColors.info,
          animationDelay: 300,
        ),
        StatCard(
          label: 'Agents enregistrés',
          value: stats == null ? '—' : '$totalOfficers',
          icon: Icons.people_outline_rounded,
          iconColor: AppColors.warning,
          animationDelay: 400,
        ),
        StatCard(
          label: 'Amendes en retard',
          value: stats == null ? '—' : _fmtNum(overdueFines),
          icon: Icons.schedule_rounded,
          iconColor: AppColors.error,
          trendPositive: false,
          animationDelay: 500,
        ),
      ],
    );
  }

  Widget _buildRevenueChart(Map<String, dynamic>? stats) {
    final rawMonthly = stats?['monthlyRevenue'] as List<dynamic>?;
    final months = rawMonthly?.map((m) => m as Map<String, dynamic>).toList() ??
        List.generate(
          12,
          (i) => {'month': '?', 'amount': 0},
        );

    final labels = months.map((m) => m['month'] as String? ?? '').toList();
    final data = months
        .map((m) => ((m['amount'] as num?)?.toDouble() ?? 0.0) / 1000000)
        .toList();
    final maxY = data.isEmpty
        ? 10.0
        : (data.reduce((a, b) => a > b ? a : b) * 1.3).clamp(1.0, double.infinity);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Revenus mensuels (M FCFA)',
                  style: AppTextStyles.titleMedium),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                    DateTime.now().year.toString(),
                    style: AppTextStyles.caption),
              ),
            ],
          ),
          const SizedBox(height: 20),
          stats == null
              ? const SizedBox(
                  height: 180,
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary)),
                )
              : SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final val = rod.toY;
                            if (val == 0) return null;
                            return BarTooltipItem(
                              '${val.toStringAsFixed(1)}M FCFA',
                              AppTextStyles.caption
                                  .copyWith(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final i = val.toInt();
                              if (i >= labels.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(labels[i],
                                    style: AppTextStyles.caption
                                        .copyWith(fontSize: 8)),
                              );
                            },
                            reservedSize: 20,
                          ),
                        ),
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (val) => const FlLine(
                          color: AppColors.divider,
                          strokeWidth: 0.5,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: data.asMap().entries.map((e) {
                        final isCurrent = e.key == data.length - 1;
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(5)),
                              gradient: e.value > 0
                                  ? LinearGradient(
                                      colors: isCurrent
                                          ? [AppColors.primary, AppColors.accent]
                                          : [
                                              AppColors.primary
                                                  .withValues(alpha: 0.6),
                                              AppColors.primary
                                                  .withValues(alpha: 0.3)
                                            ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    )
                                  : null,
                              color: e.value > 0 ? null : AppColors.surfaceVariant,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildGlobalRates(Map<String, dynamic>? stats) {
    final paymentRate = (stats?['paymentRate'] as num?)?.toDouble() ?? 0.0;
    final totalOfficers = (stats?['totalOfficers'] as num?)?.toInt() ?? 1;
    final activeOfficers = (stats?['activeOfficers'] as num?)?.toInt() ?? 0;
    final activeRate =
        totalOfficers > 0 ? (activeOfficers / totalOfficers) * 100 : 0.0;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.analytics_outlined,
                size: 18, color: AppColors.accent),
            const SizedBox(width: 8),
            Text('Indicateurs de performance', style: AppTextStyles.titleMedium),
          ]),
          const SizedBox(height: 20),
          _RateBar(
            label: 'Taux de paiement des amendes',
            rate: paymentRate / 100,
            color: paymentRate >= 70 ? AppColors.success : AppColors.warning,
            valueLabel: '${paymentRate.toInt()}%',
          ),
          const SizedBox(height: 16),
          _RateBar(
            label: 'Agents actuellement en service',
            rate: activeRate / 100,
            color: AppColors.info,
            valueLabel: '$activeOfficers / $totalOfficers',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildTopOfficers(BuildContext context) {
    // Toujours depuis la liste réelle via l'écran Agents
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Agents les plus actifs', style: AppTextStyles.titleMedium),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go('/admin/officers'),
              child: Text('Voir tous',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.info)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TopOfficersList(),
      ],
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    final links = [
      (
        icon: Icons.receipt_long_rounded,
        label: 'Toutes les amendes',
        subtitle: 'Consulter & filtrer',
        gradient: AppColors.primaryGradient,
        route: '/admin/fines',
      ),
      (
        icon: Icons.person_add_alt_1_rounded,
        label: 'Ajouter un agent',
        subtitle: 'Enregistrement PNC',
        gradient: AppColors.successGradient,
        route: '/admin/add-agent',
      ),
      (
        icon: Icons.map_rounded,
        label: 'Carte nationale',
        subtitle: 'Zones & agents',
        gradient: const LinearGradient(
          colors: [AppColors.info, Color(0xFF0097A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: '/admin/map',
      ),
      (
        icon: Icons.bar_chart_rounded,
        label: 'Revenus détaillés',
        subtitle: 'Analyse financière',
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.gold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        route: '/admin/revenue',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Accès rapides', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: links.asMap().entries.map((entry) {
            final i = entry.key;
            final link = entry.value;
            return GestureDetector(
              onTap: () => context.push(link.route),
              child: Container(
                decoration: BoxDecoration(
                  gradient: link.gradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(link.icon, size: 18, color: Colors.white),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          link.label,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          link.subtitle,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
                .animate(delay: Duration(milliseconds: i * 60))
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.06, end: 0);
          }).toList(),
        ),
      ],
    );
  }

  String _fmtNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) {
      final s = n.toString();
      return '${s.substring(0, s.length - 3)} ${s.substring(s.length - 3)}';
    }
    return n.toString();
  }
}

// Barre de progression
class _RateBar extends StatelessWidget {
  final String label;
  final double rate; // 0.0 → 1.0
  final Color color;
  final String valueLabel;
  const _RateBar(
      {required this.label,
      required this.rate,
      required this.color,
      required this.valueLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
            Text(valueLabel,
                style: AppTextStyles.labelSmall
                    .copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rate.clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// Liste des top agents depuis l'API
class _TopOfficersList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final officersAsync = ref.watch(officersProvider(''));

    return officersAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (_, __) => Center(
        child: Text('Données indisponibles',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textTertiary)),
      ),
      data: (officers) {
        final top = officers
            .where((o) => o.totalInfractions > 0)
            .toList()
          ..sort((a, b) => b.totalInfractions.compareTo(a.totalInfractions));
        final display = top.take(3).toList();

        if (display.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Center(
              child: Text('Aucun agent avec des infractions pour le moment',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textTertiary),
                  textAlign: TextAlign.center),
            ),
          );
        }

        return Column(
          children: display.asMap().entries.map((entry) {
            final officer = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: entry.key == 0
                          ? AppColors.warning.withValues(alpha: 0.2)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '#${entry.key + 1}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: entry.key == 0
                              ? AppColors.warning
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        officer.avatarInitials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(officer.fullName,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textPrimary)),
                        Text(officer.zone,
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${officer.totalInfractions}',
                          style: AppTextStyles.titleSmall
                              .copyWith(color: AppColors.primary)),
                      Text('interpellations', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ).animate(delay: Duration(milliseconds: entry.key * 80)).fadeIn().slideX(begin: 0.05);
          }).toList(),
        );
      },
    );
  }
}
