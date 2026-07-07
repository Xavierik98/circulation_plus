import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../data/providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'suspension_history_screen.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final stats = statsAsync.valueOrNull;
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, auth),
          SliverToBoxAdapter(child: _buildHeroBanner(context, auth, stats)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                _buildKpiGrid(stats),
                const SizedBox(height: 24),
                _buildMapPreviewCard(context),
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

  // ── AppBar élégant avec drapeau Congo ───────────────────────────────────────
  SliverAppBar _buildAppBar(BuildContext context, AuthState auth) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0A1628),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // PNC Badge redesigné
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.congoGreen, AppColors.congoYellow, AppColors.congoRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: AppColors.congoYellow.withValues(alpha: 0.3), blurRadius: 8),
                ],
              ),
              child: const Center(
                child: Text('PNC', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Circulation+', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                const Text(
                  'POLICE NATIONALE DU CONGO',
                  style: TextStyle(color: AppColors.congoYellow, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                ),
              ],
            ),
            const Spacer(),
            // Indicateur système actif
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.6), blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('En ligne', style: TextStyle(color: AppColors.success, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.push('/admin/settings'),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: const Icon(Icons.settings_outlined, size: 18, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(
          height: 3,
          decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient),
        ),
      ),
    );
  }

  // ── Hero banner avec carte Congo Brazzaville en fond ────────────────────────
  Widget _buildHeroBanner(BuildContext context, AuthState auth, Map<String, dynamic>? stats) {
    final now = DateTime.now();
    final activeOfficers = (stats?['activeOfficers'] as num?)?.toInt() ?? 0;

    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1628), Color(0xFF0D2040), Color(0xFF0A1628)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Carte Congo en fond
          Positioned.fill(
            child: CustomPaint(
              painter: _CongoMapHeroPainter(),
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0A1628).withValues(alpha: 0.3),
                    Colors.transparent,
                    const Color(0xFF0A1628).withValues(alpha: 0.5),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          // Contenu
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Titre & date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.congoGreen.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.congoGreen.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'RÉPUBL. DU CONGO',
                            style: AppTextStyles.caption.copyWith(color: AppColors.congoGreen, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${now.day}/${now.month}/${now.year}',
                            style: AppTextStyles.caption.copyWith(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tableau de bord',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      auth.userName ?? 'Administration PNC',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.05),

                // Metric bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    backgroundBlendMode: BlendMode.screen,
                  ),
                  child: Row(
                    children: [
                      _HeroMetric(
                        icon: Icons.badge_rounded,
                        value: '$activeOfficers',
                        label: 'En service',
                        color: AppColors.congoGreen,
                      ),
                      _HeroDivider(),
                      _HeroMetric(
                        icon: Icons.gavel_rounded,
                        value: _fmtNum((stats?['totalFinesThisMonth'] as num?)?.toInt() ?? 0),
                        label: 'Ce mois',
                        color: AppColors.congoYellow,
                      ),
                      _HeroDivider(),
                      _HeroMetric(
                        icon: Icons.location_on_rounded,
                        value: '12',
                        label: 'Dép. couverts',
                        color: AppColors.congoRed,
                      ),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── KPI Grid ─────────────────────────────────────────────────────────────────
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: Icons.analytics_outlined, title: 'Indicateurs clés'),
        const SizedBox(height: 12),
        GridView.count(
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
              gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
            ),
            LargeStatCard(
              label: 'Revenus collectés',
              value: stats == null ? '—' : revStr,
              description: 'FCFA ce mois',
              icon: Icons.account_balance_outlined,
              gradient: const LinearGradient(colors: [Color(0xFF009A44), Color(0xFF00701F)]),
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
              subtitle: stats == null ? null : 'sur $totalOfficers',
              icon: Icons.badge_outlined,
              iconColor: AppColors.info,
              animationDelay: 300,
            ),
            StatCard(
              label: 'Total agents',
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
        ),
      ],
    );
  }

  // ── Carte GPS — accès prominent ───────────────────────────────────────────
  Widget _buildMapPreviewCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/admin/map'),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF0D2040), Color(0xFF0A3060)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: AppColors.info.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Stack(
          children: [
            // Mini Congo map in background
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CustomPaint(painter: _CongoMapMiniPainter()),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.congoGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.gps_fixed_rounded, color: AppColors.congoGreen, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text('Carte GPS nationale',
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Localisation en temps réel des agents en service sur tout le territoire',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.info.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new_rounded, color: AppColors.info, size: 13),
                              SizedBox(width: 6),
                              Text('Ouvrir la carte', style: TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Pulsing GPS icon
                  _PulsingGpsIcon(),
                ],
              ),
            ),
          ],
        ),
      ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.06),
    );
  }

  // ── Graphique revenus ─────────────────────────────────────────────────────
  Widget _buildRevenueChart(Map<String, dynamic>? stats) {
    final rawMonthly = stats?['monthlyRevenue'] as List<dynamic>?;
    final months = rawMonthly?.map((m) => m as Map<String, dynamic>).toList() ??
        List.generate(12, (i) => {'month': '?', 'amount': 0});

    final labels = months.map((m) => m['month'] as String? ?? '').toList();
    final data = months.map((m) => ((m['amount'] as num?)?.toDouble() ?? 0.0) / 1000000).toList();
    final maxY = data.isEmpty ? 10.0 : (data.reduce((a, b) => a > b ? a : b) * 1.3).clamp(1.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: Icons.bar_chart_rounded, title: 'Revenus mensuels (M FCFA)'),
        const SizedBox(height: 12),
        PremiumCard(
          child: stats == null
              ? const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
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
                            return BarTooltipItem('${val.toStringAsFixed(1)}M FCFA',
                                AppTextStyles.caption.copyWith(color: Colors.white));
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
                              if (i >= labels.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(labels[i], style: AppTextStyles.caption.copyWith(fontSize: 8)),
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
                        getDrawingHorizontalLine: (val) => const FlLine(color: AppColors.divider, strokeWidth: 0.5),
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
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                              gradient: e.value > 0
                                  ? LinearGradient(
                                      colors: isCurrent
                                          ? [AppColors.congoGreen, AppColors.congoYellow]
                                          : [AppColors.primary.withValues(alpha: 0.6), AppColors.primary.withValues(alpha: 0.3)],
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
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  // ── Indicateurs de performance ────────────────────────────────────────────
  Widget _buildGlobalRates(Map<String, dynamic>? stats) {
    final paymentRate = (stats?['paymentRate'] as num?)?.toDouble() ?? 0.0;
    final totalOfficers = (stats?['totalOfficers'] as num?)?.toInt() ?? 1;
    final activeOfficers = (stats?['activeOfficers'] as num?)?.toInt() ?? 0;
    final activeRate = totalOfficers > 0 ? (activeOfficers / totalOfficers) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: Icons.analytics_outlined, title: 'Performance opérationnelle'),
        const SizedBox(height: 12),
        PremiumCard(
          child: Column(
            children: [
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
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  // ── Top agents ───────────────────────────────────────────────────────────
  Widget _buildTopOfficers(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionTitle(icon: Icons.emoji_events_rounded, title: 'Agents les plus actifs'),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go('/admin/officers'),
              child: Text('Voir tous', style: AppTextStyles.labelSmall.copyWith(color: AppColors.info)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TopOfficersList(),
      ],
    );
  }

  // ── Accès rapides ─────────────────────────────────────────────────────────
  Widget _buildQuickLinks(BuildContext context) {
    final links = [
      (icon: Icons.receipt_long_rounded, label: 'Amendes',         subtitle: 'Consulter & filtrer',
       gradient: AppColors.primaryGradient, route: '/admin/fines'),
      (icon: Icons.person_add_alt_1_rounded, label: 'Ajouter agent', subtitle: 'Enregistrement PNC',
       gradient: AppColors.successGradient, route: '/admin/add-agent'),
      (icon: Icons.manage_accounts_rounded, label: 'Utilisateurs',  subtitle: 'Comptes & accès',
       gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4338CA)]), route: '/admin/users'),
      (icon: Icons.block_rounded, label: 'Suspensions',           subtitle: 'Historique & statuts',
       gradient: const LinearGradient(colors: [AppColors.error, Color(0xFFB71C1C)]), route: '__suspensions__'),
      (icon: Icons.bar_chart_rounded, label: 'Revenus',            subtitle: 'Analyse financière',
       gradient: const LinearGradient(colors: [AppColors.accent, AppColors.gold]), route: '/admin/revenue'),
      (icon: Icons.shield_outlined, label: 'Sécurité',             subtitle: 'IPs bloquées',
       gradient: const LinearGradient(colors: [Color(0xFF7F1D1D), Color(0xFF450A0A)]), route: '/admin/security'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: Icons.grid_view_rounded, title: 'Accès rapides'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: links.asMap().entries.map((entry) {
            final i = entry.key;
            final link = entry.value;
            return GestureDetector(
              onTap: () {
                if (link.route == '__suspensions__') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SuspensionHistoryScreen()),
                  );
                } else {
                  context.push(link.route);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: link.gradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                      child: Icon(link.icon, size: 18, color: Colors.white),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(link.label,
                            style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(link.subtitle,
                            style: AppTextStyles.caption.copyWith(color: Colors.white.withValues(alpha: 0.8))),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate(delay: Duration(milliseconds: i * 60)).fadeIn(duration: 300.ms).slideY(begin: 0.06);
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

// ── Métriques hero ────────────────────────────────────────────────────────────
class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _HeroMetric({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10)),
        ],
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

// ── Icône GPS qui pulse ───────────────────────────────────────────────────────
class _PulsingGpsIcon extends StatefulWidget {
  @override
  State<_PulsingGpsIcon> createState() => _PulsingGpsIconState();
}

class _PulsingGpsIconState extends State<_PulsingGpsIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.info.withValues(alpha: _anim.value * 0.15),
          border: Border.all(color: AppColors.info.withValues(alpha: _anim.value * 0.5), width: 2),
        ),
        child: const Icon(Icons.gps_fixed_rounded, color: AppColors.info, size: 32),
      ),
    );
  }
}

// ── Section title helper ──────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(title, style: AppTextStyles.titleMedium),
      ],
    );
  }
}

// ── Rate bar ──────────────────────────────────────────────────────────────────
class _RateBar extends StatelessWidget {
  final String label;
  final double rate;
  final Color color;
  final String valueLabel;
  const _RateBar({required this.label, required this.rate, required this.color, required this.valueLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
            Text(valueLabel, style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.w600)),
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

// ── Top officers list ─────────────────────────────────────────────────────────
class _TopOfficersList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final officersAsync = ref.watch(officersProvider(''));

    return officersAsync.when(
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
      error: (_, __) => Center(child: Text('Données indisponibles', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary))),
      data: (officers) {
        final top = officers.where((o) => o.totalInfractions > 0).toList()
          ..sort((a, b) => b.totalInfractions.compareTo(a.totalInfractions));
        final display = top.take(3).toList();

        if (display.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cardBorder)),
            child: Center(child: Text('Aucun agent avec des infractions pour le moment', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary), textAlign: TextAlign.center)),
          );
        }

        final medals = ['🥇', '🥈', '🥉'];

        return Column(
          children: display.asMap().entries.map((entry) {
            final officer = entry.value;
            final isFirst = entry.key == 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isFirst ? AppColors.congoYellow.withValues(alpha: 0.4) : AppColors.cardBorder,
                ),
                boxShadow: isFirst ? [BoxShadow(color: AppColors.congoYellow.withValues(alpha: 0.1), blurRadius: 12)] : null,
              ),
              child: Row(
                children: [
                  Text(medals[entry.key], style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                    child: Center(child: Text(officer.avatarInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(officer.fullName, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                      Text(officer.zone, style: AppTextStyles.caption),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${officer.totalInfractions}', style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
                    Text('interpellations', style: AppTextStyles.caption),
                  ]),
                ],
              ),
            ).animate(delay: Duration(milliseconds: entry.key * 80)).fadeIn().slideX(begin: 0.05);
          }).toList(),
        );
      },
    );
  }
}

// ── Congo Map Hero Painter — silhouette plein format ─────────────────────────
class _CongoMapHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = AppColors.congoGreen.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = _buildCongoPath(size);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, stroke);

    // Brazzaville dot
    final bzv = _geoToScreen(-4.26, 15.24, size);
    _drawCityDot(canvas, bzv, AppColors.congoYellow, 'BZV');

    // Pointe-Noire dot
    final pnr = _geoToScreen(-4.77, 11.87, size);
    _drawCityDot(canvas, pnr, AppColors.congoRed, 'PNR');

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 5; i++) {
      canvas.drawLine(Offset(size.width * i / 5, 0), Offset(size.width * i / 5, size.height), gridPaint);
      canvas.drawLine(Offset(0, size.height * i / 5), Offset(size.width, size.height * i / 5), gridPaint);
    }
  }

  void _drawCityDot(Canvas canvas, Offset pos, Color color, String label) {
    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
    final glowPaint = Paint()..color = color.withValues(alpha: 0.3)..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 8, glowPaint);
    canvas.drawCircle(pos, 4, dotPaint);

    final tp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos.translate(6, -5));
  }

  Offset _geoToScreen(double lat, double lng, Size size) {
    const latMin = -5.5; const latMax = 3.5;
    const lngMin = 11.0; const lngMax = 18.5;
    final x = (lng - lngMin) / (lngMax - lngMin) * size.width;
    final y = (latMax - lat) / (latMax - latMin) * size.height;
    return Offset(x.clamp(0, size.width), y.clamp(0, size.height));
  }

  Path _buildCongoPath(Size size) {
    final pts = _congoOutlineGeo.map((p) => _geoToScreen(p[0], p[1], size)).toList();
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) { path.lineTo(p.dx, p.dy); }
    path.close();
    return path;
  }

  // Approximate Congo Brazzaville border coordinates (lat, lng)
  static const List<List<double>> _congoOutlineGeo = [
    [3.7,  16.0], [3.5,  17.5], [2.5,  18.0], [1.5,  18.1], [1.0,  17.8],
    [0.5,  17.5], [0.0,  17.0], [-0.5, 16.5], [-1.0, 16.2], [-1.5, 16.0],
    [-2.0, 16.5], [-2.5, 16.8], [-3.0, 16.2], [-3.5, 15.8], [-4.0, 15.5],
    [-4.5, 15.2], [-5.0, 14.8], [-5.0, 14.0], [-4.5, 13.5], [-4.0, 13.0],
    [-3.5, 12.5], [-3.0, 12.2], [-2.5, 11.8], [-2.0, 11.5], [-1.5, 11.5],
    [-1.0, 11.6], [-0.5, 11.8], [0.0,  11.7], [0.5,  11.5], [1.0,  11.3],
    [1.5,  11.4], [2.0,  11.8], [2.5,  12.3], [3.0,  13.0], [3.2,  14.0],
    [3.5,  15.0], [3.7,  16.0],
  ];

  @override
  bool shouldRepaint(_) => false;
}

// ── Congo Map Mini Painter — pour la carte GPS card ──────────────────────────
class _CongoMapMiniPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = AppColors.info.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = _buildPath(size);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, stroke);

    // GPS dots animés (agents simulés)
    final dots = [
      (_geoToScreen(-4.26, 15.24, size), AppColors.congoGreen),
      (_geoToScreen(-4.77, 11.87, size), AppColors.congoRed),
      (_geoToScreen(0.07, 16.05, size),  AppColors.congoYellow),
      (_geoToScreen(-4.18, 12.36, size), AppColors.info),
    ];

    for (final (pos, color) in dots) {
      canvas.drawCircle(pos, 5, Paint()..color = color.withValues(alpha: 0.25));
      canvas.drawCircle(pos, 3, Paint()..color = color..style = PaintingStyle.fill);
    }
  }

  Offset _geoToScreen(double lat, double lng, Size size) {
    const latMin = -5.5; const latMax = 3.5;
    const lngMin = 11.0; const lngMax = 18.5;
    final x = (lng - lngMin) / (lngMax - lngMin) * size.width;
    final y = (latMax - lat) / (latMax - latMin) * size.height;
    return Offset(x.clamp(0, size.width), y.clamp(0, size.height));
  }

  Path _buildPath(Size size) {
    final pts = _CongoMapHeroPainter._congoOutlineGeo.map((p) => _geoToScreen(p[0], p[1], size)).toList();
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) { path.lineTo(p.dx, p.dy); }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_) => false;
}
