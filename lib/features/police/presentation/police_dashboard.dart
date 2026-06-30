import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/models/officer_model.dart';
import '../../../data/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../data/providers.dart';
import '../../../shared/models/fine_model.dart';
import '../../../data/sync_service.dart';

// Stitch Design System Colors
class _StitchColors {
  static const Color primary = Color(0xFF006B2E);
  static const Color primaryContainer = Color(0xFF00873C);
  static const Color secondary = Color(0xFF6D5E00);
  static const Color secondaryContainer = Color(0xFFFCDF4B);
  static const Color tertiary = Color(0xFFBB0014);
  static const Color background = Color(0xFFF9F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1A1C1E);
  static const Color onSurfaceVariant = Color(0xFF3E4A3E);
  static const Color outlineVariant = Color(0xFFBDCABA);
  static const Color surfaceContainerHigh = Color(0xFFE8E8EA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
}

String _firstName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return 'Agent';
  final parts = fullName.trim().split(RegExp(r'\s+'));
  return parts.first;
}

String _lastName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return '';
  final parts = fullName.trim().split(RegExp(r'\s+'));
  return parts.length > 1 ? parts.sublist(1).join(' ') : '';
}

class PoliceDashboard extends ConsumerStatefulWidget {
  const PoliceDashboard({super.key});

  @override
  ConsumerState<PoliceDashboard> createState() => _PoliceDashboardState();
}

class _PoliceDashboardState extends ConsumerState<PoliceDashboard> {
  bool _onDuty = true;
  bool _statusLoading = false;
  Timer? _gpsTimer;
  Timer? _timeTimer;
  String _timeString = '12:00';

  @override
  void initState() {
    super.initState();
    // GPS updates
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendGpsHeartbeat());
    _gpsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_onDuty) _sendGpsHeartbeat();
    });

    // Time updates for Stitch status bar
    _updateTime();
    _timeTimer = Timer.periodic(const Duration(seconds: 10), (_) => _updateTime());
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _timeTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    if (mounted) {
      setState(() {
        _timeString = '$hh:$mm';
      });
    }
  }

  Future<void> _sendGpsHeartbeat() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await ApiClient.instance.patch(
        '/api/officers/me/location',
        body: {'lat': pos.latitude, 'lng': pos.longitude},
      );
    } catch (_) {
      // Silencieux — pas d'affichage d'erreur pour le heartbeat
    }
  }

  Future<void> _toggleDutyStatus() async {
    final newStatus = !_onDuty;
    setState(() => _statusLoading = true);
    try {
      double? lat;
      double? lng;

      if (newStatus) {
        try {
          var permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final pos = await Geolocator.getCurrentPosition(
              locationSettings:
                  const LocationSettings(accuracy: LocationAccuracy.high),
            );
            lat = pos.latitude;
            lng = pos.longitude;
          }
        } catch (_) {}
      }

      await ApiClient.instance.post(
        '/api/officers/me/status',
        body: {
          'onDuty': newStatus,
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        },
      );
      setState(() => _onDuty = newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'Vous êtes maintenant en service' : 'Vous êtes hors service',
            ),
            backgroundColor: newStatus ? _StitchColors.primary : _StitchColors.onSurfaceVariant,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: _StitchColors.tertiary,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour du statut.'),
            backgroundColor: _StitchColors.tertiary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _statusLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final statsAsync = ref.watch(officerStatsProvider);
    final recentFinesAsync = ref.watch(myFinesProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    final pendingCount = ref.watch(pendingFinesCountProvider).valueOrNull ?? 0;

    final stats = statsAsync.valueOrNull;
    final officer = OfficerModel(
      id: auth.userId ?? '',
      badgeNumber: auth.badgeNumber ?? '—',
      firstName: _firstName(auth.userName),
      lastName: _lastName(auth.userName),
      rank: 'Agent PNC',
      unit: 'Police Nationale du Congo',
      zone: '—',
      phone: auth.telephone ?? '',
      avatarInitials: auth.initials,
      status: OfficerStatus.active,
      totalInfractions: (stats?['totalInfractions'] as num?)?.toInt() ?? 0,
      todayInfractions: (stats?['monthInfractions'] as num?)?.toInt() ?? 0,
      totalRevenue: (stats?['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      joinedDate: DateTime.now(),
    );

    return Scaffold(
      backgroundColor: _StitchColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/police/scan'),
        backgroundColor: _StitchColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        icon: const Icon(Icons.add_circle, size: 24),
        label: Text(
          'NOUVELLE INTERPELLATION',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(officer, _onDuty, unreadCount),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 24),
                _buildWelcomeBanner(officer),
                const SizedBox(height: 24),
                _buildStatsRow(
                  officer,
                  paymentRate: (stats?['paymentRate'] as num?)?.toInt(),
                ),
                const SizedBox(height: 24),
                _buildActivityFeed(recentFinesAsync.valueOrNull ?? []),
                const SizedBox(height: 24),
                _buildStatusIndicators(pendingCount),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStatusBar() {
    return Container(
      color: _StitchColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.signal_cellular_alt, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                '4G+',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.location_on, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                'GPS Fix',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.sync, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                'Cloud Sync',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _timeString,
                style: GoogleFonts.courierPrime(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(OfficerModel officer, bool onDuty, int unreadCount) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    return SliverAppBar(
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      backgroundColor: _StitchColors.surface,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: _StitchColors.surface,
          border: Border(
            bottom: BorderSide(color: _StitchColors.outlineVariant, width: 1),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: statusBarHeight),
            _buildTopStatusBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: _StitchColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Circulation+',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _StitchColors.primary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _statusLoading ? null : _toggleDutyStatus,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: onDuty
                              ? _StitchColors.primary.withOpacity(0.1)
                              : _StitchColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: onDuty
                                ? _StitchColors.primary.withOpacity(0.4)
                                : _StitchColors.outlineVariant,
                          ),
                        ),
                        child: _statusLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _StitchColors.primary,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: onDuty
                                          ? _StitchColors.primary
                                          : Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    onDuty ? 'En service' : 'Hors service',
                                    style: GoogleFonts.inter(
                                      color: onDuty
                                          ? _StitchColors.primary
                                          : _StitchColors.onSurfaceVariant,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => context.push('/police/notifications'),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            color: _StitchColors.onSurfaceVariant,
                            size: 24,
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: _StitchColors.tertiary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _StitchColors.surface, width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => context.push('/police/settings'),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: _StitchColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            officer.avatarInitials,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(OfficerModel officer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Poste de Brazzaville Nord'.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _StitchColors.onSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Bonjour, Agent ${officer.lastName}',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _StitchColors.onSurface,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildStatsRow(OfficerModel officer, {int? paymentRate}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _StitchColors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL INTERPELLATIONS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatNumber(officer.totalInfractions),
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+12% vs mois dernier',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _StitchColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _StitchColors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REVENUS (CFA)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _StitchColors.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatRevenue(officer.totalRevenue),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _StitchColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _StitchColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _StitchColors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PV DU MOIS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _StitchColors.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${officer.todayInfractions}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _StitchColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.1),
        
        const SizedBox(height: 12),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _StitchColors.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _StitchColors.secondary.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _StitchColors.secondary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.payments_outlined,
                      color: _StitchColors.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TAUX DE PAIEMENT',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _StitchColors.secondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        paymentRate == null ? '—' : '$paymentRate%',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _StitchColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: (paymentRate ?? 88.5) / 100,
                  strokeWidth: 4,
                  backgroundColor: _StitchColors.secondary.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(_StitchColors.secondary),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildActivityFeed(List<FineModel> fines) {
    final recent = fines.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activité Récente',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _StitchColors.onSurface,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/police/history'),
              child: Text(
                'Voir tout',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _StitchColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: _StitchColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _StitchColors.outlineVariant),
            ),
            child: Column(
              children: [
                const Icon(Icons.history_rounded, size: 36, color: Colors.grey),
                const SizedBox(height: 10),
                Text(
                  'Aucune activité pour le moment',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _StitchColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vos verbalisations apparaîtront ici.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _StitchColors.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms)
        else
          ...recent.asMap().entries.map((e) {
            final fine = e.value;
            final isPaid = fine.status == FineStatus.paid;
            
            IconData leadingIcon = Icons.directions_car_outlined;
            Color iconColor = _StitchColors.primary;
            
            if (fine.infractionLabel.toLowerCase().contains('casque') ||
                fine.infractionLabel.toLowerCase().contains('moto') ||
                fine.infractionLabel.toLowerCase().contains('deux roues')) {
              leadingIcon = Icons.two_wheeler_outlined;
            } else if (fine.status == FineStatus.overdue) {
              leadingIcon = Icons.minor_crash_outlined;
              iconColor = _StitchColors.tertiary;
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _StitchColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _StitchColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _StitchColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(leadingIcon, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                fine.vehiclePlate,
                                style: GoogleFonts.courierPrime(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _StitchColors.onSurface,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isPaid
                                      ? _StitchColors.primary.withOpacity(0.1)
                                      : _StitchColors.errorContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isPaid ? 'PAYÉ' : 'EN ATTENTE',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isPaid
                                        ? _StitchColors.primary
                                        : _StitchColors.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fine.infractionLabel,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: _StitchColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${fine.issuedAt.day}/${fine.issuedAt.month}/${fine.issuedAt.year} · ${fine.amount} CFA',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: _StitchColors.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _StitchColors.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ).animate(delay: Duration(milliseconds: 400 + e.key * 80))
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.05, end: 0);
          }),
      ],
    );
  }

  Widget _buildStatusIndicators(int pendingCount) {
    final hasPending = pendingCount > 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'État du système',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _StitchColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _StitchColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _StitchColors.outlineVariant),
          ),
          child: Column(
            children: [
              _buildStatusRow(
                label: 'Connexion réseau',
                status: true,
                detail: '4G LTE',
                statusColor: _StitchColors.primary,
              ),
              const Divider(height: 20, color: _StitchColors.outlineVariant),
              _buildStatusRow(
                label: 'GPS actif',
                status: true,
                detail: 'Précision: 3m',
                statusColor: _StitchColors.primary,
              ),
              const Divider(height: 20, color: _StitchColors.outlineVariant),
              _buildStatusRow(
                label: 'Serveur central',
                status: true,
                detail: 'En ligne',
                statusColor: _StitchColors.primary,
              ),
              const Divider(height: 20, color: _StitchColors.outlineVariant),
              InkWell(
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tentative de synchronisation forcée...')),
                  );
                  final synced = await SyncService.instance.syncNow();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(synced > 0
                            ? '$synced PV synchronisé(s) avec succès !'
                            : 'Aucun PV à synchroniser ou réseau indisponible.'),
                        backgroundColor: synced > 0
                            ? _StitchColors.primary
                            : _StitchColors.onSurfaceVariant,
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _buildStatusRow(
                    label: 'Synchronisation',
                    status: !hasPending,
                    statusColor: hasPending ? _StitchColors.secondary : _StitchColors.primary,
                    detail: hasPending
                        ? '$pendingCount en attente ↻'
                        : 'À jour ✓',
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms),
      ],
    );
  }

  Widget _buildStatusRow({
    required String label,
    required bool status,
    required String detail,
    required Color statusColor,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _StitchColors.onSurface,
            ),
          ),
        ),
        Text(
          detail,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: _StitchColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    final str = number.toString();
    if (str.length <= 3) return str;
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      buffer.write(str[i]);
      final remaining = str.length - 1 - i;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  String _formatRevenue(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    } else {
      return '${amount.toStringAsFixed(0)}';
    }
  }
}
