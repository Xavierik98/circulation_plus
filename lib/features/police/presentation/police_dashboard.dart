import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/officer_model.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/animated_counter.dart';
import '../../../shared/widgets/pnc_badge.dart';
import '../../../data/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../data/providers.dart';

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
  bool _onDuty = false;
  bool _statusLoading = false;

  Future<void> _toggleDutyStatus() async {
    final newStatus = !_onDuty;
    setState(() => _statusLoading = true);
    try {
      double? lat;
      double? lng;

      if (newStatus) {
        // Demander/vérifier la permission GPS seulement quand on passe en service
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
        } catch (_) {
          // GPS indisponible : on met quand même à jour le statut sans coordonnées
        }
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
            backgroundColor: newStatus ? AppColors.success : AppColors.textTertiary,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour du statut.'),
            backgroundColor: AppColors.error,
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
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(officer, _onDuty),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                _buildWelcomeBanner(officer),
                const SizedBox(height: 24),
                _buildStatsRow(officer, paymentRate: (stats?['paymentRate'] as num?)?.toInt()),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildActivityFeed(),
                const SizedBox(height: 24),
                _buildStatusIndicators(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(OfficerModel officer, bool onDuty) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 0,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(
        children: [
          const PncBadge(size: 38, showGlow: false),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Circulation+',
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary)),
              Text(
                'PORTAIL AGENT — PNC',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.gold,
                  fontSize: 9,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // En service / Hors service toggle
          GestureDetector(
            onTap: _statusLoading ? null : _toggleDutyStatus,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: onDuty
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: onDuty
                      ? AppColors.success.withValues(alpha: 0.4)
                      : AppColors.cardBorder,
                ),
              ),
              child: _statusLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.success,
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
                                ? AppColors.success
                                : AppColors.textDisabled,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          onDuty ? 'En service' : 'Hors service',
                          style: AppTextStyles.caption.copyWith(
                            color: onDuty
                                ? AppColors.success
                                : AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge.fromOfficerStatus(officer.status),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/police/notifications'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      size: 20, color: AppColors.textSecondary),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
              ],
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

  Widget _buildWelcomeBanner(OfficerModel officer) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bonjour'
        : hour < 18
            ? 'Bon après-midi'
            : 'Bonsoir';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1F44), Color(0xFF0A1628), Color(0xFF0D1421)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                ),
                const SizedBox(height: 4),
                Text(
                  officer.fullName,
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.goldGlow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        officer.badgeNumber,
                        style: AppTextStyles.mono.copyWith(
                          fontSize: 11,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      officer.rank,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Text(officer.zone, style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              UserAvatar(
                size: 64,
                editable: true,
                photoUrl: ref.watch(authProvider).photoUrl,
                initials: officer.avatarInitials,
              ),
              const SizedBox(height: 8),
              Text(
                'Aujourd\'hui',
                style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
              ),
              AnimatedCounter(
                end: officer.todayInfractions,
                style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary),
              ),
              Text('interpellations', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2);
  }

  Widget _buildStatsRow(OfficerModel officer, {int? paymentRate}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statistiques', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            StatCard(
              label: 'Total Interpellations',
              value: '${officer.totalInfractions}',
              icon: Icons.gavel_rounded,
              iconColor: AppColors.primary,
              animationDelay: 0,
            ),
            StatCard(
              label: 'Revenus générés',
              value: officer.totalRevenue == 0
                  ? '0'
                  : '${(officer.totalRevenue / 1000000).toStringAsFixed(1)}M',
              subtitle: 'FCFA',
              icon: Icons.account_balance_wallet_outlined,
              iconColor: AppColors.success,
              animationDelay: 100,
            ),
            StatCard(
              label: 'Ce mois',
              value: '${officer.todayInfractions}',
              icon: Icons.calendar_month_outlined,
              iconColor: AppColors.warning,
              animationDelay: 200,
            ),
            StatCard(
              label: 'Taux paiement',
              value: paymentRate == null ? '—' : '$paymentRate%',
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.success,
              animationDelay: 300,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions rapides', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => context.push('/police/scan'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add_circle_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nouvelle Interpellation',
                        style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scanner permis · Sélectionner l\'infraction · Signer',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.search_rounded,
                label: 'Vérifier\nConducteur',
                color: AppColors.accent,
                onTap: () => context.push('/police/history'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.map_outlined,
                label: 'Zones\nActives',
                color: AppColors.warning,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scanner\nPlaque',
                color: AppColors.success,
                onTap: () => context.push('/police/scan'),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildActivityFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Activité récente', style: AppTextStyles.titleMedium),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go('/police/history'),
              child: Text(
                'Voir tout',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PremiumCard(
          child: Column(
            children: [
              const Icon(Icons.history_rounded,
                  size: 36, color: AppColors.textDisabled),
              const SizedBox(height: 10),
              Text(
                'Aucune activité pour le moment',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: 4),
              Text(
                'Vos verbalisations apparaîtront ici.',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildStatusIndicators() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('État du système', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        const PremiumCard(
          child: Column(
            children: [
              _StatusRow(label: 'Connexion réseau', status: true, detail: '4G LTE'),
              Divider(height: 20, color: AppColors.divider),
              _StatusRow(label: 'GPS actif', status: true, detail: 'Précision: 3m'),
              Divider(height: 20, color: AppColors.divider),
              _StatusRow(label: 'Serveur central', status: true, detail: 'En ligne'),
              Divider(height: 20, color: AppColors.divider),
              _StatusRow(
                  label: 'Synchronisation', status: true, detail: 'Il y a 2min'),
            ],
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool status;
  final String detail;

  const _StatusRow({required this.label, required this.status, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: status ? AppColors.success : AppColors.error,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (status ? AppColors.success : AppColors.error).withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
        ),
        Text(detail, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
