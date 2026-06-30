import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/stitch_colors.dart';
import '../../../data/providers.dart';
import 'suspension_history_screen.dart';

/// Design Stitch "Tableau de bord Admin".
class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final stats = statsAsync.valueOrNull;

    return Scaffold(
      backgroundColor: StitchColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(),
                const SizedBox(height: 20),
                _buildKpiGrid(stats),
                const SizedBox(height: 24),
                _buildRevenueChartAndLinks(context, stats),
                const SizedBox(height: 24),
                _buildMapAndTopOfficers(context),
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
      elevation: 0,
      backgroundColor: StitchColors.surface,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(
        children: [
          const Icon(Icons.security, color: StitchColors.primary, size: 20),
          const SizedBox(width: 8),
          Text('Circulation+', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: StitchColors.primary)),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/admin/settings'),
            child: const Icon(Icons.search, color: StitchColors.onSurfaceVariant, size: 22),
          ),
        ],
      ),
      bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: StitchColors.outlineVariant)),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tableau de Bord', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: StitchColors.onSurface)),
              Text('Supervision Administrative · Brazzaville', style: GoogleFonts.inter(fontSize: 13, color: StitchColors.onSurfaceVariant)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: StitchColors.primaryContainer, borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text('${now.day}/${now.month}/${now.year}'.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
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
      childAspectRatio: 1.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _KpiTile(icon: Icons.report_problem, iconColor: StitchColors.primary, trend: totalOfficers > 0 ? null : null, label: 'Infractions', value: stats == null ? '—' : _fmtNum(totalFines), delay: 0),
        _KpiTile(icon: Icons.payments, iconColor: StitchColors.primary, label: 'Revenus (FCFA)', value: stats == null ? '—' : revStr, delay: 60),
        _KpiTile(icon: Icons.badge, iconColor: StitchColors.secondary, label: 'Agents en service', value: stats == null ? '—' : '$activeOfficers/$totalOfficers', delay: 120),
        _KpiTile(icon: Icons.schedule, iconColor: StitchColors.tertiary, label: 'En Retard', value: stats == null ? '—' : _fmtNum(overdueFines), delay: 180),
        _KpiTile(icon: Icons.check_circle_outline, iconColor: StitchColors.primary, label: 'Taux de paiement', value: stats == null ? '—' : '$paymentRate%', delay: 240),
        _KpiTile(icon: Icons.people_outline, iconColor: StitchColors.secondary, label: 'Total agents', value: stats == null ? '—' : '$totalOfficers', delay: 300),
      ],
    );
  }

  Widget _buildRevenueChartAndLinks(BuildContext context, Map<String, dynamic>? stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: Icons.bar_chart_rounded, title: 'Revenus Mensuels'),
        const SizedBox(height: 12),
        _buildRevenueChart(stats),
        const SizedBox(height: 24),
        _SectionTitle(icon: Icons.grid_view_rounded, title: 'Accès rapides'),
        const SizedBox(height: 12),
        _buildQuickLinks(context),
      ],
    );
  }

  Widget _buildRevenueChart(Map<String, dynamic>? stats) {
    final rawMonthly = stats?['monthlyRevenue'] as List<dynamic>?;
    final months = rawMonthly?.map((m) => m as Map<String, dynamic>).toList() ??
        List.generate(12, (i) => {'month': '?', 'amount': 0});

    final labels = months.map((m) => m['month'] as String? ?? '').toList();
    final data = months.map((m) => ((m['amount'] as num?)?.toDouble() ?? 0.0) / 1000000).toList();
    final maxY = data.isEmpty ? 10.0 : (data.reduce((a, b) => a > b ? a : b) * 1.3).clamp(1.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: StitchColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16), border: Border.all(color: StitchColors.outlineVariant)),
      child: stats == null
          ? const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: StitchColors.primary)))
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
                        return BarTooltipItem('${val.toStringAsFixed(1)}M FCFA', GoogleFonts.inter(fontSize: 11, color: Colors.white));
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
                          return Padding(padding: const EdgeInsets.only(top: 4), child: Text(labels[i], style: GoogleFonts.inter(fontSize: 8, color: StitchColors.onSurfaceVariant)));
                        },
                        reservedSize: 20,
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (val) => const FlLine(color: StitchColors.outlineVariant, strokeWidth: 0.5)),
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
                                  colors: isCurrent ? [StitchColors.primaryFixed, StitchColors.primary] : [StitchColors.primary.withValues(alpha: 0.6), StitchColors.primary.withValues(alpha: 0.3)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                )
                              : null,
                          color: e.value > 0 ? null : StitchColors.surfaceContainerHigh,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildQuickLinks(BuildContext context) {
    final links = [
      (icon: Icons.receipt_long_rounded, label: 'Amendes', subtitle: 'Consulter & filtrer', color: StitchColors.primary, route: '/admin/fines'),
      (icon: Icons.person_add_alt_1_rounded, label: 'Ajouter agent', subtitle: 'Enregistrement PNC', color: StitchColors.primaryContainer, route: '/admin/add-agent'),
      (icon: Icons.manage_accounts_rounded, label: 'Utilisateurs', subtitle: 'Comptes & accès', color: const Color(0xFF6366F1), route: '/admin/users'),
      (icon: Icons.block_rounded, label: 'Suspensions', subtitle: 'Historique & statuts', color: StitchColors.tertiary, route: '__suspensions__'),
      (icon: Icons.bar_chart_rounded, label: 'Revenus', subtitle: 'Analyse financière', color: StitchColors.secondary, route: '/admin/revenue'),
      (icon: Icons.shield_outlined, label: 'Sécurité', subtitle: 'IPs bloquées', color: const Color(0xFF7F1D1D), route: '/admin/security'),
    ];

    return GridView.count(
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
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SuspensionHistoryScreen()));
            } else {
              context.push(link.route);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: link.color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: link.color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
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
                    Text(link.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(link.subtitle, style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: i * 60)).fadeIn(duration: 300.ms).slideY(begin: 0.06);
      }).toList(),
    );
  }

  Widget _buildMapAndTopOfficers(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.go('/admin/map'),
          child: Container(
            height: 200,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: StitchColors.outlineVariant)),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(color: StitchColors.surfaceContainerHigh, child: CustomPaint(painter: _CongoMapMiniPainter())),
                  ),
                ),
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20), border: Border.all(color: StitchColors.outlineVariant)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: StitchColors.primary, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('LIVE: TERRITOIRE NATIONAL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: StitchColors.onSurface)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.06),

        const SizedBox(height: 24),

        Row(
          children: [
            _SectionTitle(icon: Icons.emoji_events_rounded, title: 'Agents Performants'),
            const Spacer(),
            GestureDetector(onTap: () => context.go('/admin/officers'), child: Text('Voir tous', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: StitchColors.primary))),
          ],
        ),
        const SizedBox(height: 12),
        const _TopOfficersList(),
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

class _KpiTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? trend;
  final int delay;
  const _KpiTile({required this.icon, required this.iconColor, required this.label, required this.value, this.trend, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StitchColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: StitchColors.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: StitchColors.onSurface)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    ).animate(delay: Duration(milliseconds: delay)).fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0);
  }
}

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
          decoration: BoxDecoration(color: StitchColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: StitchColors.primary),
        ),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: StitchColors.onSurface)),
      ],
    );
  }
}

class _TopOfficersList extends ConsumerWidget {
  const _TopOfficersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final officersAsync = ref.watch(officersProvider(''));

    return officersAsync.when(
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: StitchColors.primary))),
      error: (_, __) => Center(child: Text('Données indisponibles', style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant))),
      data: (officers) {
        final top = officers.where((o) => o.totalInfractions > 0).toList()..sort((a, b) => b.totalInfractions.compareTo(a.totalInfractions));
        final display = top.take(3).toList();

        if (display.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: StitchColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(14), border: Border.all(color: StitchColors.outlineVariant)),
            child: Center(child: Text('Aucun agent avec des infractions pour le moment', style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant), textAlign: TextAlign.center)),
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
                color: StitchColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isFirst ? StitchColors.secondaryContainer : StitchColors.outlineVariant),
                boxShadow: isFirst ? [BoxShadow(color: StitchColors.secondaryContainer.withValues(alpha: 0.3), blurRadius: 12)] : null,
              ),
              child: Row(
                children: [
                  Text(medals[entry.key], style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: StitchColors.primary, shape: BoxShape.circle),
                    child: Center(child: Text(officer.avatarInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(officer.fullName, style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurface)),
                      Text(officer.zone, style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${officer.totalInfractions}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: StitchColors.primary)),
                    Text('interpellations', style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant)),
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

// ── Congo Map Mini Painter — pour la carte GPS card ──────────────────────────
class _CongoMapMiniPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = StitchColors.onSurfaceVariant.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = StitchColors.primary.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = _buildPath(size);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, stroke);

    final dots = [
      (_geoToScreen(-4.26, 15.24, size), StitchColors.primary),
      (_geoToScreen(-4.77, 11.87, size), StitchColors.tertiary),
      (_geoToScreen(0.07, 16.05, size), StitchColors.secondaryContainer),
      (_geoToScreen(-4.18, 12.36, size), const Color(0xFF6366F1)),
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

  static const List<List<double>> _congoOutlineGeo = [
    [3.7, 16.0], [3.5, 17.5], [2.5, 18.0], [1.5, 18.1], [1.0, 17.8],
    [0.5, 17.5], [0.0, 17.0], [-0.5, 16.5], [-1.0, 16.2], [-1.5, 16.0],
    [-2.0, 16.5], [-2.5, 16.8], [-3.0, 16.2], [-3.5, 15.8], [-4.0, 15.5],
    [-4.5, 15.2], [-5.0, 14.8], [-5.0, 14.0], [-4.5, 13.5], [-4.0, 13.0],
    [-3.5, 12.5], [-3.0, 12.2], [-2.5, 11.8], [-2.0, 11.5], [-1.5, 11.5],
    [-1.0, 11.6], [-0.5, 11.8], [0.0, 11.7], [0.5, 11.5], [1.0, 11.3],
    [1.5, 11.4], [2.0, 11.8], [2.5, 12.3], [3.0, 13.0], [3.2, 14.0],
    [3.5, 15.0], [3.7, 16.0],
  ];

  Path _buildPath(Size size) {
    final pts = _congoOutlineGeo.map((p) => _geoToScreen(p[0], p[1], size)).toList();
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_) => false;
}
