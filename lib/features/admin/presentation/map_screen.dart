import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/providers.dart';
import '../../../shared/models/officer_model.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Zones de référence (heatmap / zones view)
// ─────────────────────────────────────────────────────────────────────────────
class _Zone {
  final String name;
  final LatLng center;
  final double riskLevel;
  final int count;
  final String risk;
  const _Zone(this.name, this.center, this.riskLevel, this.count, this.risk);
}

const _baseZones = [
  _Zone('Brazzaville Centre', LatLng(-4.2634, 15.2429), 0, 0, 'low'),
  _Zone('Brazzaville Nord',   LatLng(-4.2100, 15.2800), 0, 0, 'low'),
  _Zone('Brazzaville Sud',    LatLng(-4.3200, 15.2200), 0, 0, 'low'),
  _Zone('Pointe-Noire',       LatLng(-4.7769, 11.8635), 0, 0, 'low'),
  _Zone('Dolisie',            LatLng(-4.1980, 12.6690), 0, 0, 'low'),
  _Zone('Nkayi',              LatLng(-4.1700, 13.2800), 0, 0, 'low'),
  _Zone('Brazzaville Est',    LatLng(-4.2500, 15.3100), 0, 0, 'low'),
  _Zone('Ouesso',             LatLng( 1.6136, 16.0483), 0, 0, 'low'),
  _Zone('Impfondo',           LatLng( 1.6171, 18.0613), 0, 0, 'low'),
];

List<_Zone> _enrichZones(List<dynamic> pts) {
  final total =
      pts.fold<int>(0, (s, p) => s + ((p as Map)['count'] as num? ?? 1).toInt());
  return _baseZones.map((z) {
    int count = 0;
    for (final p in pts) {
      final m = p as Map<String, dynamic>;
      final lat = (m['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (m['longitude'] as num?)?.toDouble() ?? 0;
      final c   = (m['count'] as num?)?.toInt() ?? 1;
      final dLat = lat - z.center.latitude;
      final dLng = lng - z.center.longitude;
      if (dLat * dLat + dLng * dLng < 0.25) count += c;
    }
    final ratio  = total == 0 ? 0.0 : count / total;
    final avg    = total == 0 ? 1.0 : total / _baseZones.length;
    final risk   = count > avg * 1.5 ? 'high' : count > 0 ? 'medium' : 'low';
    return _Zone(z.name, z.center, ratio.clamp(0, 1), count, risk);
  }).toList()
    ..sort((a, b) => b.count.compareTo(a.count));
}

// ─────────────────────────────────────────────────────────────────────────────
// MapScreen
// ─────────────────────────────────────────────────────────────────────────────
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  final _mapController = MapController();
  String _selectedView = 'agents'; // agents | heatmap | zones
  OfficerModel? _selectedOfficer;

  // Centre Congo + zoom initial
  static const _congoCenter = LatLng(-2.8, 14.5);
  static const _defaultZoom = 5.5;

  // ── Contrôleurs d'animation pour le pulsing GPS ───────────────────────────
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Rafraîchissement automatique toutes les 30s pour la quasi-temps-réel
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) ref.invalidate(officersProvider(''));
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color _riskColor(String risk) => switch (risk) {
        'high'   => AppColors.error,
        'medium' => AppColors.warning,
        _        => AppColors.success,
      };

  void _centerOnOfficer(OfficerModel o) {
    _mapController.move(LatLng(o.lastLat!, o.lastLng!), 14);
  }

  void _resetView() {
    _mapController.move(_congoCenter, _defaultZoom);
    setState(() => _selectedOfficer = null);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final officersAsync = ref.watch(officersProvider(''));
    final heatmapAsync  = ref.watch(heatmapProvider);

    final allOfficers = officersAsync.valueOrNull ?? [];
    final gpsOfficers = allOfficers
        .where((o) => o.lastLat != null && o.lastLng != null)
        .toList();
    final heatmapPts = heatmapAsync.valueOrNull ?? [];
    final zones      = heatmapPts.isEmpty ? _baseZones : _enrichZones(heatmapPts);
    final isLoading  = officersAsync.isLoading || heatmapAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(isLoading, gpsOfficers),
      body: Stack(
        children: [
          // ── Carte principale ──────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _congoCenter,
              initialZoom:   _defaultZoom,
              minZoom: 4,
              maxZoom: 18,
              onTap: (_, __) => setState(() => _selectedOfficer = null),
            ),
            children: [
              // Fond de carte professionnel Dark Mode (CartoDB Dark Matter)
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'cg.gouv.circulation_plus',
              ),

              // Heatmap view — cercles colorés par intensité
              if (_selectedView == 'heatmap')
                CircleLayer(
                  circles: _buildHeatCircles(heatmapPts, zones),
                ),

              // Zones view — cercles nommés
              if (_selectedView == 'zones')
                CircleLayer(circles: _buildZoneCircles(zones)),

              // Agents view — marqueurs GPS précis
              if (_selectedView == 'agents')
                MarkerLayer(
                  markers: _buildOfficerMarkers(gpsOfficers),
                ),
            ],
          ),

          // ── Onglets de vue ────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildViewTabs(),
          ),

          // ── Badge stats (vue agents) ──────────────────────────────────────
          if (_selectedView == 'agents')
            Positioned(
              top: 52, left: 12,
              child: _buildStatsBadge(gpsOfficers),
            ),

          // ── Noms de zones (vue zones) ─────────────────────────────────────
          if (_selectedView == 'zones')
            ..._buildZoneLabels(zones),

          // ── Légende (heatmap) ─────────────────────────────────────────────
          if (_selectedView == 'heatmap')
            Positioned(
              bottom: 16, right: 12,
              child: _buildLegend(),
            ),

          // ── Bouton recentrer ──────────────────────────────────────────────
          Positioned(
            bottom: _selectedOfficer != null ? 216 : 16,
            right: 12,
            child: _buildFab(),
          ),

          // ── Panel détail agent ────────────────────────────────────────────
          if (_selectedOfficer != null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _buildOfficerPanel(_selectedOfficer!),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AppBar
  // ─────────────────────────────────────────────────────────────────────────
  AppBar _buildAppBar(bool isLoading, List<OfficerModel> gpsOfficers) {
    return AppBar(
      backgroundColor: AppColors.surface,
      title: Text('Carte nationale — GPS terrain',
          style: AppTextStyles.titleMedium),
      actions: [
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2)),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              ref.invalidate(heatmapProvider);
              ref.invalidate(officersProvider(''));
            },
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(
            height: 3,
            decoration:
                const BoxDecoration(gradient: AppColors.congoFlagGradient)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Onglets
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildViewTabs() {
    final tabs = [
      ('agents',  Icons.location_on_rounded,  'Agents GPS'),
      ('heatmap', Icons.whatshot_rounded,      'Infractions'),
      ('zones',   Icons.map_rounded,           'Zones'),
    ];
    return Container(
      height: 44,
      color: AppColors.surface.withValues(alpha: 0.95),
      child: Row(
        children: tabs.map((t) {
          final sel = _selectedView == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedView = t.$1;
                _selectedOfficer = null;
              }),
              child: AnimatedContainer(
                duration: 200.ms,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: sel ? AppColors.primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.$2,
                        size: 14,
                        color:
                            sel ? AppColors.primary : AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      t.$3,
                      style: AppTextStyles.caption.copyWith(
                        color: sel ? AppColors.primary : AppColors.textTertiary,
                        fontWeight:
                            sel ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Marqueurs agents GPS
  // ─────────────────────────────────────────────────────────────────────────
  List<Marker> _buildOfficerMarkers(List<OfficerModel> officers) {
    return officers.map((o) {
      final isSelected = _selectedOfficer?.id == o.id;

      return Marker(
        point:  LatLng(o.lastLat!, o.lastLng!),
        width:  isSelected ? 52 : 40,
        height: isSelected ? 52 : 40,
        child:  GestureDetector(
          onTap: () => setState(() {
            _selectedOfficer = isSelected ? null : o;
            if (!isSelected) _centerOnOfficer(o);
          }),
          child: _AgentMarker(
            officer:    o,
            isSelected: isSelected,
            pulseCtrl:  _pulseCtrl,
          ),
        ),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cercles heatmap
  // ─────────────────────────────────────────────────────────────────────────
  List<CircleMarker> _buildHeatCircles(
      List<dynamic> pts, List<_Zone> zones) {
    if (pts.isNotEmpty) {
      final maxC = pts.fold<int>(1, (m, p) {
        final c = ((p as Map<String, dynamic>)['count'] as num? ?? 1).toInt();
        return c > m ? c : m;
      });
      return pts.map((p) {
        final m         = p as Map<String, dynamic>;
        final lat       = (m['latitude'] as num?)?.toDouble() ?? 0;
        final lng       = (m['longitude'] as num?)?.toDouble() ?? 0;
        final count     = (m['count'] as num?)?.toInt() ?? 1;
        final intensity = (count / maxC).clamp(0.0, 1.0);
        final color     = intensity > 0.6
            ? AppColors.error
            : intensity > 0.3
                ? AppColors.warning
                : AppColors.success;
        return CircleMarker(
          point:              LatLng(lat, lng),
          radius:             30 + intensity * 40,
          useRadiusInMeter:   false,
          color:              color.withValues(alpha: intensity * 0.38),
          borderColor:        color.withValues(alpha: intensity * 0.6),
          borderStrokeWidth:  1.2,
        );
      }).toList();
    }

    // fallback zones
    return zones.map((z) {
      final c = _riskColor(z.risk);
      return CircleMarker(
        point:             z.center,
        radius:            28 + z.riskLevel * 45,
        useRadiusInMeter:  false,
        color:             c.withValues(alpha: 0.18),
        borderColor:       c.withValues(alpha: 0.45),
        borderStrokeWidth: 1.2,
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cercles zones
  // ─────────────────────────────────────────────────────────────────────────
  List<CircleMarker> _buildZoneCircles(List<_Zone> zones) {
    return zones.map((z) {
      final c = _riskColor(z.risk);
      return CircleMarker(
        point:             z.center,
        radius:            36 + z.riskLevel * 50,
        useRadiusInMeter:  false,
        color:             c.withValues(alpha: 0.15),
        borderColor:       c.withValues(alpha: 0.5),
        borderStrokeWidth: 1.5,
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Labels zones (Positioned sur la carte simulée via LayoutBuilder)
  // ─────────────────────────────────────────────────────────────────────────
  List<Widget> _buildZoneLabels(List<_Zone> zones) {
    // Les labels sont affichés via des Markers flutter_map dans la zone view
    // → on retourne une liste vide ici car flutter_map gère le positionnement
    return [];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Badge stats agents
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStatsBadge(List<OfficerModel> gpsOfficers) {
    final enService = gpsOfficers.where((o) => o.onDuty).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:        AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                  color:  AppColors.success, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.5), blurRadius: 4)])),
          const SizedBox(width: 7),
          Text('$enService en service',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Container(width: 1, height: 12, color: AppColors.divider),
          const SizedBox(width: 8),
          Icon(Icons.location_on_rounded, size: 12, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text('${gpsOfficers.length} localisés',
              style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.3);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Légende heatmap
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:        AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Infractions', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _LegendItem(color: AppColors.error,   label: 'Élevé'),
          const SizedBox(height: 4),
          _LegendItem(color: AppColors.warning, label: 'Moyen'),
          const SizedBox(height: 4),
          _LegendItem(color: AppColors.success, label: 'Faible'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FAB recentrer
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFab() {
    return FloatingActionButton.small(
      heroTag: 'map_recenter',
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.primary,
      elevation: 4,
      onPressed: _resetView,
      child: const Icon(Icons.my_location_rounded, size: 18),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Panel détail agent (bottom sheet)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildOfficerPanel(OfficerModel o) {
    final color = o.onDuty ? AppColors.success : AppColors.textDisabled;
    final initials = o.avatarInitials.isNotEmpty ? o.avatarInitials : '??';
    final lastSeen = o.lastSeenAt != null
        ? _formatDuration(DateTime.now().difference(o.lastSeenAt!))
        : 'Inconnu';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 16, spreadRadius: 2),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                // En-tête agent
                Row(
                  children: [
                    // Avatar avec halo de status
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.policeNavy,
                        border: Border.all(color: color, width: 2),
                        boxShadow: [
                          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
                        ],
                      ),
                      child: Center(
                        child: Text(initials,
                            style: TextStyle(color: color, fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.fullName,
                              style: AppTextStyles.titleSmall
                                  .copyWith(color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: AppColors.gold.withValues(alpha: 0.4)),
                                ),
                                child: Text(o.badgeNumber,
                                    style: AppTextStyles.mono
                                        .copyWith(fontSize: 10, color: AppColors.gold)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                o.onDuty ? 'En service' : 'Hors service',
                                style: AppTextStyles.caption
                                    .copyWith(color: color, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Bouton fermer
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: AppColors.textTertiary,
                      onPressed: () => setState(() => _selectedOfficer = null),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Infos GPS + activité
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.location_on_rounded,
                        color: AppColors.primary,
                        label: 'Position GPS',
                        value: '${o.lastLat!.toStringAsFixed(4)}°, '
                            '${o.lastLng!.toStringAsFixed(4)}°',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.schedule_rounded,
                        color: AppColors.accent,
                        label: 'Vu il y a',
                        value: lastSeen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.location_city_rounded,
                        color: AppColors.gold,
                        label: 'Unité',
                        value: o.unit,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.gavel_rounded,
                        color: AppColors.warning,
                        label: "Aujourd'hui",
                        value: '${o.todayInfractions} PV',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Bouton centrer sur cet agent
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _centerOnOfficer(o),
                    icon: const Icon(Icons.center_focus_strong_rounded, size: 16),
                    label: const Text('Centrer la carte sur cet agent'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 1, duration: 250.ms, curve: Curves.easeOut);
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) return 'À l\'instant';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 24) return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
    return '${d.inDays}j';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget marqueur agent (avec animation pulse pour on-duty)
// ─────────────────────────────────────────────────────────────────────────────
class _AgentMarker extends AnimatedWidget {
  final OfficerModel officer;
  final bool isSelected;

  const _AgentMarker({
    required this.officer,
    required this.isSelected,
    required AnimationController pulseCtrl,
  }) : super(listenable: pulseCtrl);

  @override
  Widget build(BuildContext context) {
    final pulse  = (listenable as Animation<double>).value;
    final color  = officer.onDuty ? AppColors.success : AppColors.textDisabled;
    final size   = isSelected ? 52.0 : 40.0;
    final initials = officer.avatarInitials.isNotEmpty
        ? officer.avatarInitials[0]
        : '?';

    return Stack(
      alignment: Alignment.center,
      children: [
        // Anneau pulsant (agents en service uniquement)
        if (officer.onDuty)
          Container(
            width:  size + 12 + pulse * 8,
            height: size + 12 + pulse * 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12 * (1 - pulse * 0.5)),
            ),
          ),

        // Cercle principal
        Container(
          width:  size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? color.withValues(alpha: 0.25)
                : AppColors.policeNavy.withValues(alpha: 0.9),
            border: Border.all(
              color: color,
              width: isSelected ? 2.5 : 1.8,
            ),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: isSelected ? 0.55 : 0.3),
                  blurRadius: isSelected ? 14 : 6,
                  spreadRadius: isSelected ? 2 : 0),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  initials,
                  style: TextStyle(
                    color:      color,
                    fontSize:   isSelected ? 15 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.location_on_rounded, color: color, size: 10),
              ],
            ),
          ),
        ),

        // Pin pointeur (en bas du cercle)
        Positioned(
          bottom: 0,
          child: CustomPaint(
            size: Size(8, 6),
            painter: _PinTipPainter(color: color),
          ),
        ),
      ],
    );
  }
}

class _PinTipPainter extends CustomPainter {
  final Color color;
  const _PinTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path  = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tuiles UI secondaires
// ─────────────────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:        AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color:        color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textTertiary, fontSize: 9)),
                const SizedBox(height: 1),
                Text(value,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
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
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.7), shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}
