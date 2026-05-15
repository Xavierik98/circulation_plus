import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/models/officer_model.dart';
import '../../../shared/widgets/pnc_badge.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
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
                _buildKpiGrid(),
                const SizedBox(height: 24),
                _buildRevenueChart(),
                const SizedBox(height: 24),
                _buildInfractionTrend(),
                const SizedBox(height: 24),
                _buildTopOfficers(context),
                const SizedBox(height: 24),
                _buildCategoryBreakdown(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.5), blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 6),
                Text('Système actif', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/admin/settings'),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(Icons.settings_outlined, size: 20, color: AppColors.textSecondary),
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
        Text(
          'Vue nationale',
          style: AppTextStyles.headlineSmall,
        ),
        Text(
          'Rapport du ${now.day}/${now.month}/${now.year} — République du Congo',
          style: AppTextStyles.bodySmall,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildKpiGrid() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.45,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        LargeStatCard(
          label: 'Infractions nationales',
          value: '24 847',
          description: 'Ce mois',
          icon: Icons.gavel_rounded,
          gradient: AppColors.primaryGradient,
          trend: '+14.2%',
        ),
        LargeStatCard(
          label: 'Revenus collectés',
          value: '372M',
          description: 'FCFA — Ce mois',
          icon: Icons.account_balance_outlined,
          gradient: AppColors.successGradient,
          trend: '+8.7%',
        ),
        StatCard(
          label: 'Taux de paiement',
          value: '78.4%',
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppColors.success,
          trend: '+3.1%',
          animationDelay: 200,
        ),
        StatCard(
          label: 'Agents actifs',
          value: '247',
          subtitle: 'sur 312 au total',
          icon: Icons.badge_outlined,
          iconColor: AppColors.info,
          trend: '+12',
          animationDelay: 300,
        ),
        StatCard(
          label: 'Zones surveillées',
          value: '89',
          icon: Icons.location_on_outlined,
          iconColor: AppColors.warning,
          animationDelay: 400,
        ),
        StatCard(
          label: 'Amendes en retard',
          value: '1 247',
          icon: Icons.schedule_rounded,
          iconColor: AppColors.error,
          trend: '-5.2%',
          trendPositive: false,
          animationDelay: 500,
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    final data = [180, 220, 195, 310, 280, 340, 295, 372, 0, 0, 0, 0].map((v) => v.toDouble()).toList();
    final currentMonth = DateTime.now().month - 1;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Revenus mensuels', style: AppTextStyles.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text('2024', style: AppTextStyles.caption),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 420,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final val = rod.toY.toInt();
                      if (val == 0) return null;
                      return BarTooltipItem(
                        '${val}M FCFA',
                        AppTextStyles.caption.copyWith(color: Colors.white),
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
                        if (i >= months.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(months[i],
                              style: AppTextStyles.caption.copyWith(fontSize: 9)),
                        );
                      },
                      reservedSize: 20,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  final isActive = e.key <= currentMonth;
                  final isCurrent = e.key == currentMonth;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        gradient: isActive
                            ? LinearGradient(
                                colors: isCurrent
                                    ? [AppColors.primary, AppColors.accent]
                                    : [AppColors.primary.withValues(alpha: 0.6), AppColors.primary.withValues(alpha: 0.3)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              )
                            : null,
                        color: isActive ? null : AppColors.surfaceVariant,
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

  Widget _buildInfractionTrend() {
    final spots = List.generate(30, (i) {
      final base = 700.0 + (i * 8) + (i % 7 == 0 ? -50 : 0);
      return FlSpot(i.toDouble(), base + (i * 3.5));
    });

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Tendance des infractions (30j)', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) =>
                      const FlLine(color: AppColors.divider, strokeWidth: 0.5),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 29,
                minY: 600,
                maxY: 1100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.accent,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.2),
                          AppColors.accent.withValues(alpha: 0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildTopOfficers(BuildContext context) {
    final officers = OfficerModel.mockOfficers.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Agents les plus actifs', style: AppTextStyles.titleMedium),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go('/admin/officers'),
              child: Text('Voir tous', style: AppTextStyles.labelSmall.copyWith(color: AppColors.info)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...officers.asMap().entries.map((entry) {
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
                        color: entry.key == 0 ? AppColors.warning : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(officer.avatarInitials,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(officer.fullName, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                      Text(officer.zone, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${officer.totalInfractions}',
                        style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
                    Text('interpellations', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ).animate(delay: Duration(milliseconds: entry.key * 80)).fadeIn().slideX(begin: 0.05);
        }),
      ],
    );
  }

  Widget _buildCategoryBreakdown() {
    final data = [
      ('Vitesse', 0.32, AppColors.error),
      ('Documents', 0.24, AppColors.info),
      ('Comportement', 0.20, AppColors.warning),
      ('Sécurité', 0.16, AppColors.success),
      ('Parking', 0.08, AppColors.textTertiary),
    ];
    const total = 24847;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.donut_large_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Répartition par catégorie', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 35,
                    sections: data.map((d) => PieChartSectionData(
                      color: d.$3,
                      value: d.$2,
                      radius: 25,
                      showTitle: false,
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: data.map((d) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(color: d.$3, borderRadius: BorderRadius.circular(3)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(d.$1, style: AppTextStyles.bodySmall)),
                        Text(
                          '${(d.$2 * total).round()}',
                          style: AppTextStyles.labelSmall.copyWith(color: d.$3),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}
