import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/stitch_colors.dart';
import '../../../shared/models/fine_model.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../data/providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/user_avatar.dart';

class CitizenDashboard extends ConsumerWidget {
  const CitizenDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finesAsync = ref.watch(myFinesProvider);
    final auth = ref.watch(authProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: StitchColors.background,
      body: RefreshIndicator(
        color: StitchColors.primary,
        onRefresh: () async {
          // ignore: unused_result
          ref.refresh(myFinesProvider);
        },
        child: finesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: StitchColors.primary)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Impossible de charger vos contraventions.\n$e',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: StitchColors.onSurfaceVariant),
              ),
            ),
          ),
          data: (fines) {
            final pending = fines.where((f) => f.status == FineStatus.pending || f.status == FineStatus.overdue).toList();
            final totalDebt = pending.fold<int>(0, (s, f) => s + f.amount);
            return CustomScrollView(
              slivers: [
                _buildAppBar(context, auth, unreadCount),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 16),
                      _buildLicenseStatus(context),
                      const SizedBox(height: 16),
                      _buildPaymentSummary(pending.length, totalDebt),
                      const SizedBox(height: 24),
                      _buildActiveFines(context, pending),
                      const SizedBox(height: 24),
                      _buildPaidHistory(context, fines),
                      const SizedBox(height: 24),
                      _buildAlerts(fines),
                      const SizedBox(height: 24),
                      _buildHelp(),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AuthState auth, int unreadCount) {
    return SliverAppBar(
      pinned: true,
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
            onTap: () => context.push('/citizen/notifications'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: StitchColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10), border: Border.all(color: StitchColors.outlineVariant)),
                  child: const Icon(Icons.notifications_outlined, size: 18, color: StitchColors.onSurfaceVariant),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -2, right: -2,
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(color: StitchColors.tertiary, shape: BoxShape.circle, border: Border.all(color: StitchColors.surface, width: 2)),
                      child: Center(child: Text(unreadCount > 9 ? '9+' : '$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700))),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          UserAvatar(size: 32, editable: false, photoUrl: auth.photoUrl, initials: auth.initials, gradient: const LinearGradient(colors: [StitchColors.primary, StitchColors.primaryContainer])),
        ],
      ),
      bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: StitchColors.outlineVariant)),
    );
  }

  Widget _buildLicenseStatus(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: StitchColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(12), border: Border.all(color: StitchColors.outlineVariant)),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: StitchColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.verified_user, color: StitchColors.primary, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statut de mon permis', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: StitchColors.onSurfaceVariant)),
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'VALIDE', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: StitchColors.primary)),
                ])),
              ],
            ),
          ),
          GestureDetector(onTap: () => context.push('/citizen/license'), child: const Icon(Icons.chevron_right, color: StitchColors.onSurfaceVariant)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPaymentSummary(int pendingCount, int totalDebt) {
    return Builder(builder: (context) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: StitchColors.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amendes à payer', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9))),
                      Text('${(totalDebt / 1000).toStringAsFixed(0)} 000 FCFA', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
                if (pendingCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                    child: Row(children: [
                      const Icon(Icons.warning, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text('$pendingCount en attente', style: GoogleFonts.inter(fontSize: 11, color: Colors.white)),
                    ]),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/citizen/history'),
                icon: const Icon(Icons.bolt, size: 18),
                label: Text('Paiement Rapide', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: StitchColors.secondaryContainer,
                  foregroundColor: StitchColors.onSecondaryContainer,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
    });
  }

  Widget _buildActiveFines(BuildContext context, List<FineModel> fines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Amendes en cours', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: StitchColors.onSurface)),
            const Spacer(),
            GestureDetector(onTap: () => context.push('/citizen/history'), child: Text('Tout voir', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: StitchColors.primary))),
          ],
        ),
        const SizedBox(height: 12),
        if (fines.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: StitchColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16), border: Border.all(color: StitchColors.outlineVariant)),
            child: Center(
              child: Column(children: [
                const Icon(Icons.check_circle_outline_rounded, size: 40, color: StitchColors.primary),
                const SizedBox(height: 8),
                Text('Aucune amende en attente', style: GoogleFonts.inter(color: StitchColors.primary)),
              ]),
            ),
          )
        else
          ...fines.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CitizenFineCard(fine: entry.value).animate(delay: Duration(milliseconds: entry.key * 100)).fadeIn(duration: 400.ms).slideY(begin: 0.1),
              )),
      ],
    );
  }

  Widget _buildPaidHistory(BuildContext context, List<FineModel> allFines) {
    final paid = allFines.where((f) => f.status == FineStatus.paid).toList();
    if (paid.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Historique récent', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: StitchColors.onSurface)),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: paid.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _PaidFineRow(fine: paid[i]),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildAlerts(List<FineModel> fines) {
    final overdue = fines.where((f) => f.status == FineStatus.overdue).toList();
    if (overdue.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alertes & rappels', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: StitchColors.onSurface)),
        const SizedBox(height: 12),
        ...overdue.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AlertCard(icon: Icons.gavel_rounded, title: 'Amende en retard', body: 'Le PV ${f.reference} est en retard. Pénalité +50% applicable.', color: StitchColors.tertiary),
            )),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildHelp() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: StitchColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.help_outline, color: StitchColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Un doute sur une amende ?', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: StitchColors.onSurface)),
                Text('Consultez nos guides ou contactez le support.', style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CitizenFineCard extends StatelessWidget {
  final FineModel fine;
  const _CitizenFineCard({required this.fine});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/citizen/fine/${fine.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: StitchColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: StitchColors.outlineVariant),
          boxShadow: fine.isOverdue ? [BoxShadow(color: StitchColors.error.withValues(alpha: 0.15), blurRadius: 0, offset: const Offset(4, 0))] : null,
        ),
        child: Row(
          children: [
            if (fine.isOverdue) Container(width: 4, height: 56, color: StitchColors.error, margin: const EdgeInsets.only(right: 10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(fine.isOverdue ? 'EN RETARD' : 'À RÉGLER',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: fine.isOverdue ? StitchColors.error : StitchColors.secondary)),
                    Text('  •  Réf: ${fine.reference}', style: GoogleFonts.inter(fontSize: 10, color: StitchColors.onSurfaceVariant)),
                  ]),
                  const SizedBox(height: 2),
                  Text(fine.infractionLabel, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: StitchColors.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${fine.deadline.day}/${fine.deadline.month}/${fine.deadline.year}', style: GoogleFonts.courierPrime(fontSize: 12, color: StitchColors.onSurfaceVariant)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${(fine.amount / 1000).toStringAsFixed(0)} 000', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: StitchColors.onSurface)),
                Text('FCFA', style: GoogleFonts.inter(fontSize: 10, color: StitchColors.onSurfaceVariant)),
                const SizedBox(height: 4),
                StatusBadge.fromFineStatus(fine.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaidFineRow extends StatelessWidget {
  final FineModel fine;
  const _PaidFineRow({required this.fine});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: fine.paymentId != null ? () => context.push('/citizen/receipt/${fine.paymentId}') : null,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: StitchColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: StitchColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('PAYÉ', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: StitchColors.primary)),
                ),
                const Icon(Icons.receipt_outlined, size: 14, color: StitchColors.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 8),
            Text(fine.infractionLabel, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: StitchColors.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(fine.paymentMethod ?? '', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: StitchColors.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
                Text('${(fine.amount / 1000).toStringAsFixed(0)}K', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: StitchColors.primary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _AlertCard({required this.icon, required this.title, required this.body, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 4),
                Text(body, style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
