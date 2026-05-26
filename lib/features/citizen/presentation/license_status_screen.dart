import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';

class LicenseStatusScreen extends ConsumerStatefulWidget {
  const LicenseStatusScreen({super.key});

  @override
  ConsumerState<LicenseStatusScreen> createState() => _LicenseStatusScreenState();
}

class _LicenseStatusScreenState extends ConsumerState<LicenseStatusScreen> {
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final hasProfile = (auth.userName?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Permis de conduire', style: AppTextStyles.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_rounded, color: AppColors.primary),
            tooltip: 'Retourner le permis',
            onPressed: () => setState(() => _showBack = !_showBack),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // License card with flip animation
            GestureDetector(
              onTap: () => setState(() => _showBack = !_showBack),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, anim) => _FlipTransition(
                  animation: anim,
                  child: child,
                ),
                child: _showBack
                    ? _LicenseBackCard(key: const ValueKey('back'), auth: auth)
                    : _LicenseFrontCard(key: const ValueKey('front'), auth: auth),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Appuyez sur la carte pour retourner',
              style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 24),
            if (!hasProfile) ...[
              _buildCompleteProfileCta(context),
              const SizedBox(height: 24),
            ],
            _buildStatusDetails(auth),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteProfileCta(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/citizen/profile'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Profil incomplet',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 2),
                  Text('Complétez votre profil pour afficher vos informations sur le permis.',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatusDetails(AuthState auth) {
    return PremiumCard(
      child: Column(
        children: [
          _Row(label: 'Nom complet', value: auth.userName?.isNotEmpty == true ? auth.userName! : '—', icon: Icons.person_outline_rounded),
          const Divider(height: 20, color: AppColors.divider),
          _Row(label: 'Téléphone', value: auth.telephone?.isNotEmpty == true ? auth.telephone! : '—', icon: Icons.phone_outlined),
          const Divider(height: 20, color: AppColors.divider),
          _Row(label: 'Email', value: auth.email?.isNotEmpty == true ? auth.email! : '—', icon: Icons.email_outlined),
          const Divider(height: 20, color: AppColors.divider),
          _Row(
            label: 'Statut compte',
            value: auth.emailVerified ? 'VÉRIFIÉ ✓' : 'EN ATTENTE',
            icon: Icons.verified_rounded,
            valueColor: auth.emailVerified ? AppColors.success : AppColors.warning,
          ),
          const Divider(height: 20, color: AppColors.divider),
          _Row(
            label: 'Permis numérique',
            value: 'Non lié',
            icon: Icons.credit_card_outlined,
            valueColor: AppColors.textTertiary,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}

// ── Front face of the Congo DL ─────────────────────────────────────────────
class _LicenseFrontCard extends StatelessWidget {
  final AuthState auth;
  const _LicenseFrontCard({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    final name = auth.userName ?? '';
    final parts = name.trim().split(RegExp(r'\s+'));
    final lastName  = parts.isNotEmpty ? parts.first.toUpperCase() : '—';
    final firstName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.congoGreen.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background — Congo green
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF006E30), Color(0xFF009A44)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Diagonal yellow stripe (Congo flag)
            CustomPaint(painter: _DiagonalStripePainter(), size: Size.infinite),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      // Congo emblem placeholder
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.congoYellow, width: 2),
                        ),
                        child: const Center(
                          child: Text('🇨🇬', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('RÉPUBLIQUE DU CONGO',
                                style: TextStyle(color: Colors.white, fontSize: 8,
                                    fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                            const Text('MINISTÈRE DE L\'INTÉRIEUR',
                                style: TextStyle(color: Colors.white70, fontSize: 7, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('PERMIS',
                            style: TextStyle(color: Color(0xFF006E30), fontSize: 8,
                                fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo area
                      Container(
                        width: 52, height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white38),
                        ),
                        child: auth.photoUrl != null && auth.photoUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Image.network(auth.photoUrl!, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _photoPlaceholder()),
                              )
                            : _photoPlaceholder(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Field('1. NOM', lastName),
                            const SizedBox(height: 4),
                            _Field('2. PRÉNOMS', firstName.isNotEmpty ? firstName : '—'),
                            const SizedBox(height: 4),
                            _Field('3. DATE DE NAISSANCE', '—'),
                            const SizedBox(height: 4),
                            _Field('10. NUMÉRO', 'CG-2024-00000'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // QR code placeholder
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: CustomPaint(painter: _SmallQrPainter()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Categories row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final cat in ['A', 'B', 'C', 'D', 'E'])
                        _CategoryBadge(category: cat, active: cat == 'B'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _photoPlaceholder() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.person_rounded, color: Colors.white54, size: 24),
          SizedBox(height: 2),
          Text('PHOTO', style: TextStyle(color: Colors.white38, fontSize: 7, letterSpacing: 0.5)),
        ],
      );
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 7, letterSpacing: 0.8)),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  final bool active;
  const _CategoryBadge({required this.category, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: active ? AppColors.congoYellow : Colors.white38, width: 1.5),
      ),
      child: Center(
        child: Text(category,
            style: TextStyle(
              color: active ? const Color(0xFF006E30) : Colors.white60,
              fontSize: 10,
              fontWeight: active ? FontWeight.w900 : FontWeight.w400,
            )),
      ),
    );
  }
}

// ── Back face of the Congo DL ──────────────────────────────────────────────
class _LicenseBackCard extends StatelessWidget {
  final AuthState auth;
  const _LicenseBackCard({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.congoRed.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A0A00), Color(0xFF2C1208)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Red stripe top
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(height: 4, color: AppColors.congoRed),
            ),
            // Green stripe bottom
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(height: 4, color: AppColors.congoGreen),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CATÉGORIES ET CONDITIONS',
                      style: TextStyle(color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  // Category table
                  Row(
                    children: [
                      _BackCat('A', 'Motocycles'),
                      const SizedBox(width: 8),
                      _BackCat('B', 'Véhicules légers ≤ 3,5 t', active: true),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _BackCat('C', 'Poids lourds > 3,5 t'),
                      const SizedBox(width: 8),
                      _BackCat('D', 'Transport en commun'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Validity info
                  Row(
                    children: [
                      Expanded(
                        child: _InfoBox(
                          label: '4a. DATE DE DÉLIVRANCE',
                          value: '—',
                          icon: Icons.calendar_today_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoBox(
                          label: '4b. DATE D\'EXPIRATION',
                          value: '—',
                          icon: Icons.event_busy_rounded,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Magnetic stripe simulation
                  Container(
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Center(
                      child: Text('|||||||||||||||||||||||||||||||||||||||||||||||||||||||',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.2), fontSize: 10,
                              letterSpacing: -1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _BackCat extends StatelessWidget {
  final String code;
  final String label;
  final bool active;
  const _BackCat(this.code, this.label, {this.active = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? AppColors.congoGreen.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: active ? AppColors.congoGreen : Colors.white12),
        ),
        child: Row(
          children: [
            Text(code, style: TextStyle(
                color: active ? AppColors.congoGreen : Colors.white54,
                fontWeight: FontWeight.w800, fontSize: 11)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 8),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoBox({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 10, color: Colors.white38),
            const SizedBox(width: 4),
            Expanded(child: Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 7, letterSpacing: 0.5),
                overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  const _Row({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
        Text(value,
            style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Painters ───────────────────────────────────────────────────────────────
class _DiagonalStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Yellow diagonal stripe (Congo flag middle band)
    final path = Path();
    path.moveTo(size.width * 0.55, 0);
    path.lineTo(size.width * 0.75, 0);
    path.lineTo(size.width * 0.45, size.height);
    path.lineTo(size.width * 0.25, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = AppColors.congoYellow.withValues(alpha: 0.25));

    // Red diagonal stripe (right side — Congo flag)
    final path2 = Path();
    path2.moveTo(size.width * 0.78, 0);
    path2.lineTo(size.width, 0);
    path2.lineTo(size.width, size.height * 0.3);
    path2.lineTo(size.width * 0.48, size.height);
    path2.lineTo(size.width * 0.28, size.height);
    path2.close();
    canvas.drawPath(path2, Paint()..color = AppColors.congoRed.withValues(alpha: 0.3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _SmallQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black..style = PaintingStyle.fill;
    final cell = size.width / 7;
    // Simplified QR-like pattern
    const pat = [
      [1,1,1,0,1,1,1],
      [1,0,1,0,1,0,1],
      [1,1,1,0,1,1,1],
      [0,0,0,1,0,0,0],
      [1,1,0,1,0,1,1],
      [0,0,1,0,1,0,0],
      [1,0,1,1,0,1,1],
    ];
    for (int r = 0; r < 7; r++) {
      for (int c = 0; c < 7; c++) {
        if (pat[r][c] == 1) {
          canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell, cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Flip animation ─────────────────────────────────────────────────────────
class _FlipTransition extends AnimatedWidget {
  final Widget child;
  const _FlipTransition({required Animation<double> animation, required this.child})
      : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final anim = listenable as Animation<double>;
    final angle = (1 - anim.value) * math.pi;
    return Transform(
      transform: Matrix4.rotationY(angle),
      alignment: Alignment.center,
      child: child,
    );
  }
}
