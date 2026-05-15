import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _selectedView = 'heatmap';
  int? _hoveredZone;

  static const _zones = [
    _Zone('Brazzaville Centre', -4.2634, 15.2429, 0.92, 847, 'high'),
    _Zone('Brazzaville Nord', -4.2100, 15.2800, 0.65, 512, 'medium'),
    _Zone('Brazzaville Sud', -4.3200, 15.2200, 0.48, 312, 'medium'),
    _Zone('Pointe-Noire', -4.7769, 11.8635, 0.78, 634, 'high'),
    _Zone('Dolisie', -4.1980, 12.6690, 0.35, 187, 'low'),
    _Zone('Nkayi', -4.1700, 13.2800, 0.22, 98, 'low'),
    _Zone('Brazzaville Est', -4.2500, 15.3100, 0.55, 423, 'medium'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Carte nationale', style: AppTextStyles.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_outlined, size: 20),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient)),
        ),
      ),
      body: Column(
        children: [
          _buildViewSelector(),
          Expanded(child: _buildMap()),
          _buildZoneList(),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    final views = [
      ('heatmap', 'Carte thermique', Icons.whatshot_rounded),
      ('zones', 'Zones actives', Icons.location_on_rounded),
      ('officers', 'Agents terrain', Icons.badge_outlined),
    ];

    return Container(
      height: 48,
      color: AppColors.surface,
      child: Row(
        children: views.map((v) {
          final isSelected = _selectedView == v.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedView = v.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(v.$3, size: 14,
                        color: isSelected ? AppColors.primary : AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(v.$2,
                        style: AppTextStyles.caption.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textTertiary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      color: const Color(0xFF0A1525),
      child: Stack(
        children: [
          // Map base
          Positioned.fill(
            child: CustomPaint(
              painter: _CongoMapPainter(
                selectedView: _selectedView,
                zones: _zones,
                hoveredZone: _hoveredZone,
              ),
            ),
          ),

          // Zone markers
          ..._zones.asMap().entries.map((entry) {
            final zone = entry.value;
            final pos = _geoToScreen(zone.lat, zone.lng);
            return Positioned(
              left: pos.dx - 20,
              top: pos.dy - 20,
              child: GestureDetector(
                onTap: () => setState(() => _hoveredZone = _hoveredZone == entry.key ? null : entry.key),
                child: _ZoneMarker(
                  zone: zone,
                  isSelected: _hoveredZone == entry.key,
                  viewMode: _selectedView,
                ),
              ),
            );
          }),

          // Legend
          Positioned(
            bottom: 16,
            right: 16,
            child: _buildLegend(),
          ),

          // Selected zone info
          if (_hoveredZone != null)
            Positioned(
              top: 12,
              left: 12,
              right: 80,
              child: _ZoneInfoCard(zone: _zones[_hoveredZone!]),
            ),
        ],
      ),
    );
  }

  Offset _geoToScreen(double lat, double lng) {
    const mapWidth = 400.0;
    const mapHeight = 300.0;
    const minLat = -5.5;
    const maxLat = 3.5;
    const minLng = 11.0;
    const maxLng = 18.5;

    final x = (lng - minLng) / (maxLng - minLng) * mapWidth;
    final y = (maxLat - lat) / (maxLat - minLat) * mapHeight;

    const screenWidth = 400.0;
    const screenHeight = 300.0;
    return Offset(
      x / mapWidth * screenWidth,
      y / mapHeight * screenHeight,
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Niveau risque', style: AppTextStyles.caption),
          const SizedBox(height: 6),
          const _LegendItem(color: AppColors.error, label: 'Élevé'),
          const SizedBox(height: 3),
          const _LegendItem(color: AppColors.warning, label: 'Moyen'),
          const SizedBox(height: 3),
          const _LegendItem(color: AppColors.success, label: 'Faible'),
        ],
      ),
    );
  }

  Widget _buildZoneList() {
    return Container(
      height: 140,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Zones actives', style: AppTextStyles.labelMedium),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _zones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final z = _zones[i];
                return _ZoneChip(zone: z)
                    .animate(delay: Duration(milliseconds: i * 60))
                    .fadeIn().slideX(begin: 0.1);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Zone {
  final String name;
  final double lat;
  final double lng;
  final double riskLevel;
  final int count;
  final String risk;
  const _Zone(this.name, this.lat, this.lng, this.riskLevel, this.count, this.risk);
}

class _ZoneMarker extends StatelessWidget {
  final _Zone zone;
  final bool isSelected;
  final String viewMode;
  const _ZoneMarker({required this.zone, required this.isSelected, required this.viewMode});

  Color get _color => switch (zone.risk) {
    'high' => AppColors.error,
    'medium' => AppColors.warning,
    _ => AppColors.success,
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isSelected ? 48 : 36,
      height: isSelected ? 48 : 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color.withValues(alpha: isSelected ? 0.3 : 0.15),
        border: Border.all(
          color: _color.withValues(alpha: isSelected ? 0.8 : 0.4),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: _color.withValues(alpha: 0.4), blurRadius: 12)]
            : null,
      ),
      child: Center(
        child: Text(
          '${zone.count}',
          style: TextStyle(
            color: _color,
            fontSize: isSelected ? 11 : 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ZoneInfoCard extends StatelessWidget {
  final _Zone zone;
  const _ZoneInfoCard({required this.zone});

  Color get _color => switch (zone.risk) {
    'high' => AppColors.error,
    'medium' => AppColors.warning,
    _ => AppColors.success,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone.name, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary)),
                Text('${zone.count} infractions ce mois', style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(
            '${(zone.riskLevel * 100).toStringAsFixed(0)}%',
            style: AppTextStyles.titleSmall.copyWith(color: _color),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _ZoneChip extends StatelessWidget {
  final _Zone zone;
  const _ZoneChip({required this.zone});

  Color get _color => switch (zone.risk) {
    'high' => AppColors.error,
    'medium' => AppColors.warning,
    _ => AppColors.success,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(zone.name.split(' ').first, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${zone.count} infractions', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.7), shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _CongoMapPainter extends CustomPainter {
  final String selectedView;
  final List<_Zone> zones;
  final int? hoveredZone;
  _CongoMapPainter({required this.selectedView, required this.zones, required this.hoveredZone});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(Offset.zero & size,
        Paint()..color = const Color(0xFF0A1525));

    // Grid
    final gridPaint = Paint()..color = AppColors.divider.withValues(alpha: 0.1)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += size.width / 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += size.height / 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Simulate Congo border (rough outline)
    final borderPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final pts = [
      Offset(size.width * 0.15, size.height * 0.2),
      Offset(size.width * 0.25, size.height * 0.1),
      Offset(size.width * 0.45, size.height * 0.08),
      Offset(size.width * 0.65, size.height * 0.15),
      Offset(size.width * 0.80, size.height * 0.25),
      Offset(size.width * 0.85, size.height * 0.45),
      Offset(size.width * 0.75, size.height * 0.65),
      Offset(size.width * 0.60, size.height * 0.75),
      Offset(size.width * 0.45, size.height * 0.85),
      Offset(size.width * 0.30, size.height * 0.80),
      Offset(size.width * 0.18, size.height * 0.65),
      Offset(size.width * 0.12, size.height * 0.45),
      Offset(size.width * 0.15, size.height * 0.2),
    ];
    path.moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();

    // Fill
    final fillPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    // Major rivers
    final riverPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final riverPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.4, size.height * 0.35,
        size.width * 0.65, size.height * 0.5,
      );
    canvas.drawPath(riverPath, riverPaint);

    // Heatmap circles for zones
    if (selectedView == 'heatmap') {
      for (final zone in zones) {
        final Color zoneColor = switch (zone.risk) {
          'high' => AppColors.error,
          'medium' => AppColors.warning,
          _ => AppColors.success,
        };
        final x = (zone.lng - 11.0) / (18.5 - 11.0) * size.width;
        final y = (3.5 - zone.lat) / (3.5 - (-5.5)) * size.height;

        final heatPaint = Paint()
          ..shader = RadialGradient(
            colors: [zoneColor.withValues(alpha: zone.riskLevel * 0.3), Colors.transparent],
          ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 60));
        canvas.drawCircle(Offset(x, y), 60, heatPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CongoMapPainter oldDelegate) =>
      oldDelegate.selectedView != selectedView || oldDelegate.hoveredZone != hoveredZone;
}
