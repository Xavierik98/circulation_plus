import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../shared/models/department_model.dart';
import '../../../../shared/models/interpellation_state.dart';
import '../../../../shared/widgets/premium_button.dart';

class InterpellationLocationScreen extends ConsumerStatefulWidget {
  const InterpellationLocationScreen({super.key});

  @override
  ConsumerState<InterpellationLocationScreen> createState() =>
      _InterpellationLocationScreenState();
}

class _InterpellationLocationScreenState
    extends ConsumerState<InterpellationLocationScreen> {
  CongoDepartement? _selectedDept;
  final _lieuController = TextEditingController();
  String? _selectedSuggestion;

  // GPS state
  bool _loadingGps = false;
  double? _gpsLat;
  double? _gpsLng;
  String? _gpsError;
  final MapController _mapController = MapController();
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(interpellationProvider);
    _selectedDept = state.departement;
    _lieuController.text = state.lieuPrecis;
    if (state.gpsLat != null) {
      _gpsLat = state.gpsLat;
      _gpsLng = state.gpsLng;
    }
  }

  @override
  void dispose() {
    _lieuController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _selectedDept != null && _lieuController.text.trim().isNotEmpty;

  // ── GPS ────────────────────────────────────────────────────────────────────

  Future<void> _getGpsLocation() async {
    setState(() {
      _loadingGps = true;
      _gpsError = null;
    });

    try {
      // Vérifier/demander les permissions
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        setState(() {
          _gpsError = 'Permission GPS refusée. Activez-la dans les paramètres.';
          _loadingGps = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _gpsLat = pos.latitude;
        _gpsLng = pos.longitude;
        _loadingGps = false;
      });

      // Centrer la carte sur la position
      if (_mapReady) {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 16);
      }

      // Auto-remplir le lieu avec les coordonnées
      if (_lieuController.text.isEmpty) {
        _lieuController.text =
            '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      }
    } catch (e) {
      setState(() {
        _gpsError = 'Impossible d\'obtenir la position GPS.';
        _loadingGps = false;
      });
    }
  }

  Future<void> _openInGoogleMaps() async {
    if (_gpsLat == null || _gpsLng == null) return;
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$_gpsLat,$_gpsLng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _onContinue() {
    ref.read(interpellationProvider.notifier).updateLocation(
          departement: _selectedDept,
          lieuPrecis: _lieuController.text.trim(),
          gpsLat: _gpsLat,
          gpsLng: _gpsLng,
        );
    context.push('/police/infractions');
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _selectedDept != null
        ? (lieuxParDepartement[_selectedDept] ?? [])
        : <String>[];

    // Coordonnées par défaut : Brazzaville centre
    final mapCenter = (_gpsLat != null && _gpsLng != null)
        ? LatLng(_gpsLat!, _gpsLng!)
        : const LatLng(-4.2661, 15.2832);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lieu de l\'infraction', style: AppTextStyles.titleSmall),
            Text('Étape 3 sur 6', style: AppTextStyles.caption),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.5,
            backgroundColor: AppColors.surfaceVariant,
            color: AppColors.primary,
            minHeight: 3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Carte GPS ─────────────────────────────────────────
            _buildMapSection(mapCenter),

            const SizedBox(height: 20),

            // ── Département ───────────────────────────────────────
            Text('Département', style: AppTextStyles.titleMedium),
            const SizedBox(height: 10),
            _buildDepartementGrid(),

            const SizedBox(height: 20),

            // ── Lieu précis ───────────────────────────────────────
            Text('Lieu précis', style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Quartier, rue, carrefour ou axe routier',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 10),

            // Suggestions rapides
            if (suggestions.isNotEmpty) ...[
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final s = suggestions[i];
                    final isSelected = _selectedSuggestion == s;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _lieuController.text = s;
                        _selectedSuggestion = s;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.cardBorder,
                          ),
                        ),
                        child: Text(
                          s,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Champ texte libre
            TextField(
              controller: _lieuController,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary),
              onChanged: (_) => setState(() => _selectedSuggestion = null),
              decoration: InputDecoration(
                hintText: 'Ex : Carrefour Moungali, Avenue de France...',
                hintStyle: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textDisabled),
                filled: true,
                fillColor: AppColors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary),
                ),
                prefixIcon: const Icon(Icons.edit_location_alt_outlined,
                    size: 18, color: AppColors.textTertiary),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
              ),
              maxLines: 2,
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 28),

            PremiumButton(
              label: 'Continuer',
              icon: Icons.arrow_forward_rounded,
              onPressed: _canContinue ? _onContinue : null,
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Carte + bouton GPS ──────────────────────────────────────────────────────
  Widget _buildMapSection(LatLng center) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carte OpenStreetMap
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 220,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: _gpsLat != null ? 16 : 11,
                onMapReady: () => setState(() => _mapReady = true),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.circulationplus.app',
                ),
                if (_gpsLat != null && _gpsLng != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_gpsLat!, _gpsLng!),
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.location_pin,
                          color: AppColors.error,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ).animate().fadeIn(),

        const SizedBox(height: 10),

        // Boutons GPS
        Row(
          children: [
            Expanded(
              child: _loadingGps
                  ? Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _getGpsLocation,
                      icon: const Icon(Icons.my_location_rounded, size: 16),
                      label: Text(
                        _gpsLat != null
                            ? 'Mettre à jour GPS'
                            : 'Localiser ma position',
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
            ),
            if (_gpsLat != null) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _openInGoogleMaps,
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('Maps', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),

        if (_gpsLat != null) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed_rounded,
                    size: 14, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  '${_gpsLat!.toStringAsFixed(6)}, ${_gpsLng!.toStringAsFixed(6)}',
                  style: AppTextStyles.mono.copyWith(
                      fontSize: 11, color: AppColors.success),
                ),
              ],
            ),
          ),
        ],

        if (_gpsError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_gpsError!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.warning)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Grille des 12 départements ──────────────────────────────────────────────
  Widget _buildDepartementGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.6, // Plus compact
      ),
      itemCount: CongoDepartement.values.length,
      itemBuilder: (_, i) {
        final dept = CongoDepartement.values[i];
        final isSelected = _selectedDept == dept;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedDept = dept;
            _selectedSuggestion = null;
            // Ne pas effacer le lieu si déjà rempli manuellement
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.cardBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dept.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      dept.platePrefix,
                      style: AppTextStyles.mono.copyWith(
                        fontSize: 9,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
            .animate(delay: Duration(milliseconds: i * 25))
            .fadeIn(duration: 200.ms);
      },
    );
  }
}
