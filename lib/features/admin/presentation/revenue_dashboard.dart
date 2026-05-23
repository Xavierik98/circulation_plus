import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/animated_counter.dart';
import '../../../data/providers.dart';

class RevenueDashboard extends ConsumerWidget {
  const RevenueDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(revenueStatsProvider);
    final stats = statsAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Tableau des revenus', style: AppTextStyles.titleMedium),
        actions: [
          if (statsAsync.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2)),
            )
          else ...[
            IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: () => ref.invalidate(revenueStatsProvider)),
            IconButton(
                icon: const Icon(Icons.download_outlined, size: 20),
                onPressed: () {}),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
              height: 3,
              decoration: const BoxDecoration(
                  gradient: AppColors.congoFlagGradient)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildYTDCard(stats),
            const SizedBox(height: 20),
            _buildMonthlyChart(stats),
            const SizedBox(height: 20),
            _buildByInfraction(stats),
            const SizedBox(height: 20),
            _buildPendingRevenue(stats),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildYTDCard(Map<String, dynamic>? stats) {
    final totalCollected = (stats?['totalCollected'] as num?)?.toInt() ?? 0;
    final totalFines = (stats?['totalFines'] as num?)?.toInt() ?? 0;
    final paidFines = (stats?['paidFines'] as num?)?.toInt() ?? 0;
    final pendingFines = (stats?['pendingFines'] as num?)?.toInt() ?? 0;
    final paymentRate = totalFines > 0
        ? ((paidFines / totalFines) * 100).toStringAsFixed(1)
        : '0.0';

    final collectedM = (totalCollected / 1000000);
    final collectedInt = (totalCollected / 1000000 * 10).round(); // for AnimatedCounter

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1A12), Color(0xFF0C2015)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: AppColors.success.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Revenus collectés — Tout temps',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.success),
              ),
              const Spacer(),
              if (stats == null)
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: AppColors.success, strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              stats == null
                  ? Text('—',
                      style: AppTextStyles.displaySmall
                          .copyWith(color: AppColors.textPrimary))
                  : AnimatedCounter(
                      end: collectedInt,
                      suffix: collectedM >= 1000
                          ? 'G'
                          : collectedM >= 1
                              ? 'M'
                              : 'K',
                      style: AppTextStyles.displaySmall
                          .copyWith(color: AppColors.textPrimary),
                    ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(' FCFA',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.success)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _YtdStat(
                  label: 'Payées',
                  value: stats == null ? '—' : '$paidFines',
                  color: AppColors.success),
              Container(
                  width: 1, height: 32, color: AppColors.divider),
              _YtdStat(
                  label: 'En attente',
                  value: stats == null ? '—' : '$pendingFines',
                  color: AppColors.warning),
              Container(
                  width: 1, height: 32, color: AppColors.divider),
              _YtdStat(
                  label: 'Taux',
                  value: stats == null ? '—' : '$paymentRate%',
                  color: AppColors.primary),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.97, 0.97));
  }

  Widget _buildMonthlyChart(Map<String, dynamic>? stats) {
    // Grouper byDay par mois
    final byDay =
        (stats?['byDay'] as List<dynamic>? ?? [])
            .map((d) => d as Map<String, dynamic>)
            .toList();

    // Agréger par mois (YYYY-MM)
    final Map<String, double> monthMap = {};
    for (final d in byDay) {
      final date = d['date'] as String? ?? '';
      if (date.length >= 7) {
        final ym = date.substring(0, 7);
        monthMap[ym] =
            (monthMap[ym] ?? 0) + ((d['amount'] as num?)?.toDouble() ?? 0) / 1000000;
      }
    }

    final sorted = monthMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final last8 = sorted.length > 8 ? sorted.sublist(sorted.length - 8) : sorted;

    final labels = last8.map((e) {
      final parts = e.key.split('-');
      const mois = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
      final m = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0;
      return m > 0 ? mois[m] : e.key;
    }).toList();
    final values = last8.map((e) => e.value).toList();
    final maxY = values.isEmpty ? 10.0 : values.reduce((a, b) => a > b ? a : b) * 1.3;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Revenus récents (M FCFA)',
                  style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          stats == null || byDay.isEmpty
              ? const SizedBox(
                  height: 140,
                  child: Center(
                    child: Text(
                      'Aucune donnée disponible\n(aucun paiement confirmé)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  ),
                )
              : SizedBox(
                  height: 160,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY.clamp(1.0, double.infinity),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final val = rod.toY;
                            return BarTooltipItem(
                              '${val.toStringAsFixed(1)}M',
                              AppTextStyles.caption
                                  .copyWith(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, _) {
                              final i = val.toInt();
                              if (i >= labels.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(labels[i],
                                    style: AppTextStyles.caption
                                        .copyWith(fontSize: 9)),
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
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => const FlLine(
                            color: AppColors.divider, strokeWidth: 0.5),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: values.asMap().entries.map((e) {
                        final isLast = e.key == values.length - 1;
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value,
                              width: 18,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(5)),
                              gradient: LinearGradient(
                                colors: isLast
                                    ? [AppColors.primary, AppColors.accent]
                                    : [
                                        AppColors.primary
                                            .withValues(alpha: 0.6),
                                        AppColors.primary
                                            .withValues(alpha: 0.3)
                                      ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildByInfraction(Map<String, dynamic>? stats) {
    final byInfraction = (stats?['byInfraction'] as List<dynamic>? ?? [])
        .map((d) => d as Map<String, dynamic>)
        .toList();

    byInfraction.sort((a, b) =>
        ((b['amount'] as num?)?.toInt() ?? 0)
            .compareTo((a['amount'] as num?)?.toInt() ?? 0));

    final topItems = byInfraction.take(5).toList();
    final totalAmount = byInfraction.fold<int>(
        0, (s, d) => s + ((d['amount'] as num?)?.toInt() ?? 0));

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_rounded,
                  size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Revenus par infraction',
                  style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          if (topItems.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Aucune infraction payée',
                  style: TextStyle(color: AppColors.textTertiary),
                ),
              ),
            )
          else
            ...topItems.asMap().entries.map((entry) {
              final item = entry.value;
              final label = item['libelle'] as String? ?? '—';
              final amount = (item['amount'] as num?)?.toInt() ?? 0;
              final count = (item['count'] as num?)?.toInt() ?? 0;
              final share = totalAmount > 0 ? amount / totalAmount : 0.0;
              final color =
                  AppColors.chartColors[entry.key % AppColors.chartColors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label.length > 28 ? '${label.substring(0, 28)}…' : label,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                        Text('$count PV',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textTertiary)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 55,
                          child: Text(
                            _fmtXaf(amount),
                            style: AppTextStyles.labelSmall
                                .copyWith(color: color),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: share),
                      duration:
                          Duration(milliseconds: 700 + entry.key * 80),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: v,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildPendingRevenue(Map<String, dynamic>? stats) {
    final pendingFines = (stats?['pendingFines'] as num?)?.toInt() ?? 0;
    final overdueFines = (stats?['overdueFines'] as num?)?.toInt() ?? 0;
    final totalPending = pendingFines + overdueFines;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pending_actions_rounded,
                color: AppColors.warning, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amendes en attente',
                    style: AppTextStyles.titleSmall),
                Text(
                  stats == null
                      ? 'Chargement...'
                      : '$pendingFines en attente · $overdueFines en retard',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stats == null ? '—' : '$totalPending',
                style: AppTextStyles.headlineSmall
                    .copyWith(color: AppColors.warning),
              ),
              Text('PV',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.warning)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  String _fmtXaf(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toString();
  }
}

class _YtdStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _YtdStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.titleMedium.copyWith(color: color)),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
