import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/animated_counter.dart';

class RevenueDashboard extends StatelessWidget {
  const RevenueDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Tableau des revenus', style: AppTextStyles.titleMedium),
        actions: [
          IconButton(icon: const Icon(Icons.download_outlined, size: 20), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildYTDCard(),
            const SizedBox(height: 20),
            _buildMonthlyComparison(),
            const SizedBox(height: 20),
            _buildRevenueByCity(),
            const SizedBox(height: 20),
            _buildPaymentMethods(),
            const SizedBox(height: 20),
            _buildPendingRevenue(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildYTDCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1A12), Color(0xFF0C2015)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: AppColors.success.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Revenus cumulés 2024', style: AppTextStyles.bodySmall.copyWith(color: AppColors.success)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('+14.7% vs 2023', style: AppTextStyles.caption.copyWith(color: AppColors.success)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedCounter(
                end: 2847,
                suffix: 'M',
                style: AppTextStyles.displaySmall.copyWith(color: AppColors.textPrimary),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(' FCFA', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const _YtdStat(label: 'Collecté', value: '2 847M', color: AppColors.success),
              Container(width: 1, height: 32, color: AppColors.divider),
              const _YtdStat(label: 'En attente', value: '847M', color: AppColors.warning),
              Container(width: 1, height: 32, color: AppColors.divider),
              const _YtdStat(label: 'Taux', value: '77.1%', color: AppColors.primary),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.97, 0.97));
  }

  Widget _buildMonthlyComparison() {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû'];
    final data2024 = [180.0, 220.0, 195.0, 310.0, 280.0, 340.0, 295.0, 372.0];
    final data2023 = [152.0, 190.0, 168.0, 275.0, 248.0, 298.0, 261.0, 320.0];

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Comparaison annuelle (M FCFA)', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              _ChartLegend(color: AppColors.primary, label: '2024'),
              SizedBox(width: 16),
              _ChartLegend(color: AppColors.textTertiary, label: '2023'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) =>
                      const FlLine(color: AppColors.divider, strokeWidth: 0.5),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final i = val.toInt();
                        if (i >= months.length) return const SizedBox.shrink();
                        return Text(months[i], style: AppTextStyles.caption.copyWith(fontSize: 9));
                      },
                      reservedSize: 20,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, _) => Text(
                        '${val.toInt()}',
                        style: AppTextStyles.caption.copyWith(fontSize: 9),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 100,
                maxY: 420,
                lineBarsData: [
                  LineChartBarData(
                    spots: data2024.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withValues(alpha: 0.15), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: data2023.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: AppColors.textTertiary,
                    barWidth: 1.5,
                    dashArray: [5, 5],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildRevenueByCity() {
    final cities = [
      ('Brazzaville', 1842, 0.647),
      ('Pointe-Noire', 724, 0.254),
      ('Dolisie', 156, 0.055),
      ('Autres', 125, 0.044),
    ];

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_city_outlined, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Revenus par ville (M FCFA)', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          ...cities.asMap().entries.map((entry) {
            final (city, amount, share) = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(city, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
                      Text('${amount}M', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${(share * 100).toStringAsFixed(1)}%',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: share),
                    duration: Duration(milliseconds: 800 + entry.key * 100),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceVariant,
                        color: AppColors.chartColors[entry.key % AppColors.chartColors.length],
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

  Widget _buildPaymentMethods() {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment_rounded, size: 18, color: AppColors.success),
              const SizedBox(width: 8),
              Text('Méthodes de paiement', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 100,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 28,
                      sections: [
                        PieChartSectionData(color: const Color(0xFFFFCC00), value: 52, radius: 22, showTitle: false),
                        PieChartSectionData(color: const Color(0xFFFF0000), value: 31, radius: 22, showTitle: false),
                        PieChartSectionData(color: AppColors.textTertiary, value: 17, radius: 22, showTitle: false),
                      ],
                    ),
                  ),
                ),
              ),
              const Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _PaymentRow('MTN Mobile Money', '52%', Color(0xFFFFCC00)),
                    SizedBox(height: 8),
                    _PaymentRow('Airtel Money', '31%', Color(0xFFFF0000)),
                    SizedBox(height: 8),
                    _PaymentRow('Espèces (Guichet)', '17%', AppColors.textTertiary),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildPendingRevenue() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pending_actions_rounded, color: AppColors.warning, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Revenus en attente', style: AppTextStyles.titleSmall),
                Text('1 247 amendes impayées', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('847M', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.warning)),
              Text('FCFA', style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}

class _YtdStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _YtdStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.titleMedium.copyWith(color: color)),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12, height: 3,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final String percent;
  final Color color;
  const _PaymentRow(this.label, this.percent, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
        Text(percent, style: AppTextStyles.labelSmall.copyWith(color: color)),
      ],
    );
  }
}
