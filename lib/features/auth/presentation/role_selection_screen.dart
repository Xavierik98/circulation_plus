import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/pnc_badge.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppColors.policeNavy,
      body: Stack(
        children: [
          // ── Carte Congo Brazzaville en fond plein écran ──────────────────
          Positioned.fill(
            child: CustomPaint(painter: _CongoMapBgPainter()),
          ),

          // ── Overlay gradient du bas ──────────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.policeNavy.withValues(alpha: 0.15),
                    AppColors.policeNavy.withValues(alpha: 0.40),
                    AppColors.policeNavy.withValues(alpha: 0.85),
                    AppColors.policeNavy,
                  ],
                  stops: const [0.0, 0.30, 0.60, 1.0],
                ),
              ),
            ),
          ),

          // ── Barre tricolore Congo en haut ────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 4,
              decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient),
            ),
          ),

          // ── Contenu ──────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── En-tête avec armoirie PNC ────────────────────────────
                SizedBox(
                  height: h * 0.38,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Armoirie PNC grande — fond lumineux derrière
                        Container(
                          width: 148,
                          height: 148,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.30),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: const PncArmoirie(size: 148, showGlow: true),
                        )
                            .animate()
                            .fadeIn(duration: 700.ms)
                            .scale(begin: const Offset(0.6, 0.6), curve: Curves.easeOutBack),

                        const SizedBox(height: 16),

                        // Nom officiel
                        Text(
                          'POLICE NATIONALE DU CONGO',
                          style: const TextStyle(
                            color: AppColors.congoYellow,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.5,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 4),

                        Text(
                          'Circulation+',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                        const SizedBox(height: 8),

                        // Bande tricolore décorative sous le titre
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Container(
                            height: 3,
                            width: 80,
                            decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient),
                          ),
                        ).animate().fadeIn(delay: 500.ms).scaleX(begin: 0.3),

                        const SizedBox(height: 6),

                        Text(
                          'Plateforme nationale de gestion du trafic routier',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 550.ms),
                      ],
                    ),
                  ),
                ),

                // ── Cartes de rôle ────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      children: [
                        const _PoliceRoleCard(delay: 500),
                        const SizedBox(height: 12),
                        const _CitizenRoleCard(delay: 620),
                        const SizedBox(height: 12),
                        const _AdminRoleCard(delay: 740),
                        const SizedBox(height: 24),

                        // Footer
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.verified_user_outlined,
                                    size: 12, color: AppColors.success),
                                const SizedBox(width: 6),
                                Text(
                                  'Connexion chiffrée TLS 1.3',
                                  style: TextStyle(
                                    color: AppColors.success.withValues(alpha: 0.8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppConstants.ministry,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.25),
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ).animate().fadeIn(delay: 900.ms),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte Police ──────────────────────────────────────────────────────────────
class _PoliceRoleCard extends StatelessWidget {
  final int delay;
  const _PoliceRoleCard({required this.delay});

  @override
  Widget build(BuildContext context) {
    return _RoleCard(
      delay: delay,
      onTap: () => context.push('/login/police'),
      gradient: const LinearGradient(
        colors: [Color(0xFF0F2045), Color(0xFF0A1428), Color(0xFF0C1830)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: AppColors.gold,
      glowColor: AppColors.gold,
      leading: const PncArmoirie(size: 58, showGlow: false),
      title: 'Agent de Police',
      badge: 'PNC',
      badgeColor: AppColors.gold,
      subtitle: 'Contrôle routier · Interpellations · Terrain',
      arrowColor: AppColors.gold,
    );
  }
}

// ── Carte Citoyen ─────────────────────────────────────────────────────────────
class _CitizenRoleCard extends StatelessWidget {
  final int delay;
  const _CitizenRoleCard({required this.delay});

  @override
  Widget build(BuildContext context) {
    return _RoleCard(
      delay: delay,
      onTap: () => context.push('/login/citizen'),
      gradient: const LinearGradient(
        colors: [Color(0xFF003D1A), Color(0xFF002910), Color(0xFF003318)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: AppColors.congoGreen,
      glowColor: AppColors.congoGreen,
      leading: Container(
        width: 58, height: 58,
        decoration: BoxDecoration(
          color: AppColors.congoGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.congoGreen.withValues(alpha: 0.4)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 8, left: 8, right: 8,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.congoGreen.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            const Icon(Icons.person_rounded, color: AppColors.congoGreen, size: 28),
          ],
        ),
      ),
      title: 'Citoyen',
      badge: 'RC',
      badgeColor: AppColors.congoGreen,
      subtitle: 'Amendes · Paiements · Suivi dossier',
      arrowColor: AppColors.congoGreen,
    );
  }
}

// ── Carte Administration ───────────────────────────────────────────────────────
class _AdminRoleCard extends StatelessWidget {
  final int delay;
  const _AdminRoleCard({required this.delay});

  static const _indigo = Color(0xFF818CF8);
  static const _indigoDark = Color(0xFF0E0C2A);

  @override
  Widget build(BuildContext context) {
    return _RoleCard(
      delay: delay,
      onTap: () => context.push('/login/admin'),
      gradient: const LinearGradient(
        colors: [_indigoDark, Color(0xFF0B0926), Color(0xFF100D2C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: _indigo,
      glowColor: _indigo,
      leading: Container(
        width: 58, height: 58,
        decoration: BoxDecoration(
          color: _indigo.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _indigo.withValues(alpha: 0.35)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _indigo.withValues(alpha: 0.25), width: 1.5),
              ),
            ),
            const Icon(Icons.account_balance_rounded, color: _indigo, size: 24),
          ],
        ),
      ),
      title: 'Administration',
      badge: 'DGST',
      badgeColor: _indigo,
      subtitle: 'Analytique · Agents · Revenus nationaux',
      arrowColor: _indigo,
    );
  }
}

// ── Widget carte de rôle générique ────────────────────────────────────────────
class _RoleCard extends StatefulWidget {
  final int delay;
  final VoidCallback onTap;
  final LinearGradient gradient;
  final Color borderColor;
  final Color glowColor;
  final Widget leading;
  final String title;
  final String badge;
  final Color badgeColor;
  final String subtitle;
  final Color arrowColor;

  const _RoleCard({
    required this.delay,
    required this.onTap,
    required this.gradient,
    required this.borderColor,
    required this.glowColor,
    required this.leading,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.subtitle,
    required this.arrowColor,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.borderColor.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              widget.leading,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(widget.title,
                            style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.badgeColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: widget.badgeColor.withValues(alpha: 0.45)),
                          ),
                          child: Text(widget.badge,
                              style: AppTextStyles.caption.copyWith(
                                  color: widget.badgeColor,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(widget.subtitle,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary)),
                    const SizedBox(height: 10),
                    // Bande tricolore Congo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Container(
                        height: 3,
                        width: 72,
                        decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: widget.arrowColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: widget.arrowColor.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: widget.arrowColor),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: widget.delay), duration: 400.ms)
        .slideY(begin: 0.12, end: 0, delay: Duration(milliseconds: widget.delay), duration: 400.ms);
  }
}

// ── Fond carte Congo Brazzaville (silhouette géographique réelle) ─────────────
class _CongoMapBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Points géographiques approximatifs de la frontière Congo-Brazzaville
    // transformés pour remplir l'écran (coordonnées normalisées 0-1)
    // Source: contour réel, adapté pour rendu CustomPainter
    final pts = <Offset>[
      Offset(0.42 * w, 0.02 * h), // Nord — frontière Centrafrique
      Offset(0.50 * w, 0.04 * h),
      Offset(0.60 * w, 0.03 * h),
      Offset(0.72 * w, 0.08 * h), // Sangha (NE)
      Offset(0.82 * w, 0.14 * h),
      Offset(0.90 * w, 0.22 * h),
      Offset(0.94 * w, 0.32 * h),
      Offset(0.96 * w, 0.40 * h),
      Offset(0.92 * w, 0.48 * h), // Congo River (Est)
      Offset(0.88 * w, 0.56 * h),
      Offset(0.82 * w, 0.62 * h),
      Offset(0.78 * w, 0.68 * h),
      Offset(0.74 * w, 0.74 * h),
      Offset(0.68 * w, 0.80 * h),
      Offset(0.60 * w, 0.85 * h),
      Offset(0.55 * w, 0.88 * h), // Brazzaville (SE)
      Offset(0.52 * w, 0.92 * h),
      Offset(0.44 * w, 0.96 * h), // Sud — frontière Angola
      Offset(0.36 * w, 0.95 * h),
      Offset(0.28 * w, 0.90 * h),
      Offset(0.22 * w, 0.84 * h),
      Offset(0.18 * w, 0.76 * h),
      Offset(0.16 * w, 0.66 * h),
      Offset(0.14 * w, 0.56 * h), // Ouest — frontière Gabon
      Offset(0.12 * w, 0.46 * h),
      Offset(0.10 * w, 0.36 * h),
      Offset(0.14 * w, 0.26 * h),
      Offset(0.20 * w, 0.18 * h),
      Offset(0.28 * w, 0.10 * h),
      Offset(0.36 * w, 0.05 * h),
      Offset(0.42 * w, 0.02 * h), // fermeture
    ];

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();

    // Remplissage — vert Congo (plus visible)
    canvas.drawPath(
      path,
      Paint()..color = AppColors.congoGreen.withValues(alpha: 0.22),
    );

    // Double contour pour l'effet cartographique
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.congoGreen.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.congoYellow.withValues(alpha: 0.50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Points de villes principales (plus grands)
    _drawCity(canvas, Offset(0.55 * w, 0.87 * h), 'BZV', AppColors.congoYellow, big: true); // Brazzaville (capitale)
    _drawCity(canvas, Offset(0.16 * w, 0.72 * h), 'PNR', AppColors.congoRed);               // Pointe-Noire (côte)
    _drawCity(canvas, Offset(0.60 * w, 0.48 * h), 'OUE', Colors.white54);                   // Ouesso (nord)
    _drawCity(canvas, Offset(0.45 * w, 0.65 * h), 'DOL', AppColors.primary.withValues(alpha: 0.7)); // Dolisie

    // Réseau routier (route nationale 1) — plus visible
    final roadPath = Path()
      ..moveTo(0.55 * w, 0.87 * h)   // BZV
      ..cubicTo(0.52 * w, 0.78 * h,
                0.50 * w, 0.70 * h,
                0.45 * w, 0.65 * h)  // Dolisie
      ..cubicTo(0.40 * w, 0.59 * h,
                0.30 * w, 0.68 * h,
                0.16 * w, 0.72 * h); // PNR
    canvas.drawPath(roadPath,
        Paint()..color = AppColors.congoYellow.withValues(alpha: 0.30)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round);

    // Route nord BZV → Ouesso
    final northRoad = Path()
      ..moveTo(0.55 * w, 0.87 * h)
      ..cubicTo(0.58 * w, 0.73 * h,
                0.60 * w, 0.60 * h,
                0.60 * w, 0.48 * h);
    canvas.drawPath(northRoad,
        Paint()..color = AppColors.congoYellow.withValues(alpha: 0.20)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round);
  }

  void _drawCity(Canvas canvas, Offset pos, String name, Color color, {bool big = false}) {
    final ringR  = big ? 9.0 : 6.0;
    final dotR   = big ? 4.5 : 3.0;
    final fs     = big ? 10.0 : 8.5;
    // Halo
    canvas.drawCircle(pos, ringR * 2,
        Paint()..color = color.withValues(alpha: 0.10));
    // Anneau
    canvas.drawCircle(pos, ringR,
        Paint()..color = color.withValues(alpha: 0.50)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    // Point central
    canvas.drawCircle(pos, dotR,
        Paint()..color = color.withValues(alpha: 0.90));

    final tp = TextPainter(
      text: TextSpan(text: name, style: TextStyle(
        color: color.withValues(alpha: 0.85),
        fontSize: fs,
        fontWeight: FontWeight.w700,
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx + ringR + 3, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
