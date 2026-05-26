import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';

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
                    Colors.transparent,
                    AppColors.policeNavy.withValues(alpha: 0.55),
                    AppColors.policeNavy.withValues(alpha: 0.92),
                    AppColors.policeNavy,
                  ],
                  stops: const [0.0, 0.25, 0.55, 1.0],
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
                        // Armoirie PNC grande
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CustomPaint(painter: _PncArmoiriePainter(showGlow: true)),
                        )
                            .animate()
                            .fadeIn(duration: 700.ms)
                            .scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),

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
      leading: SizedBox(
        width: 58,
        height: 58,
        child: CustomPaint(painter: _PncArmoiriePainter(showGlow: false)),
      ),
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

// ── Armoirie PNC (dessinée au CustomPainter) ──────────────────────────────────
// Représentation stylisée inspirée du blason de la Police Nationale du Congo :
// cercle or → fond marine → bouclier → étoiles → texte PNC → bandes Congo
class _PncArmoiriePainter extends CustomPainter {
  final bool showGlow;
  const _PncArmoiriePainter({this.showGlow = true});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r  = w / 2;

    // ── Halo extérieur ────────────────────────────────────────────────────
    if (showGlow) {
      canvas.drawCircle(
        Offset(cx, cy), r,
        Paint()..shader = RadialGradient(colors: [
          AppColors.congoYellow.withValues(alpha: 0.28),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
    }

    // ── Anneau extérieur or ───────────────────────────────────────────────
    canvas.drawCircle(Offset(cx, cy), r * 0.96,
        Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = w * 0.055);

    // ── Fond marine ───────────────────────────────────────────────────────
    canvas.drawCircle(Offset(cx, cy), r * 0.88,
        Paint()..color = AppColors.policeNavy);

    // ── Anneau intérieur or fin ───────────────────────────────────────────
    canvas.drawCircle(Offset(cx, cy), r * 0.80,
        Paint()..color = AppColors.gold.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke..strokeWidth = w * 0.013);

    // ── Bandes tricolores Congo (3 arcs en bas) ───────────────────────────
    _drawCongoArcs(canvas, Offset(cx, cy), r * 0.78);

    // ── 5 étoiles en arc au-dessus du bouclier ────────────────────────────
    final starPaint = Paint()..color = AppColors.congoYellow;
    for (int i = 0; i < 5; i++) {
      final angle = -math.pi * 0.82 + (math.pi * 0.64) * i / 4;
      final sc = Offset(cx + (r * 0.60) * math.cos(angle),
                        cy + (r * 0.60) * math.sin(angle) - r * 0.04);
      _drawStar(canvas, sc, r * 0.058, starPaint);
    }

    // ── Bouclier central ─────────────────────────────────────────────────
    _drawShield(canvas, Offset(cx, cy + r * 0.08), r * 0.42);

    // ── Lauriers de chaque côté ───────────────────────────────────────────
    _drawLaurel(canvas, Offset(cx, cy + r * 0.08), r * 0.75, isLeft: true);
    _drawLaurel(canvas, Offset(cx, cy + r * 0.08), r * 0.75, isLeft: false);

    // ── Texte circulaire "POLICE NATIONALE DU CONGO" ──────────────────────
    _drawCircularText(canvas, Offset(cx, cy), r * 0.88, size);
  }

  void _drawCongoArcs(Canvas canvas, Offset c, double r) {
    final colors = [AppColors.congoGreen, AppColors.congoYellow, AppColors.congoRed];
    const startAngle = math.pi * 0.62;
    const totalSweep = math.pi * 0.76;
    final rect = Rect.fromCircle(center: c, radius: r);
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(rect,
        startAngle + totalSweep / 3 * i,
        totalSweep / 3,
        false,
        Paint()..color = colors[i].withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.butt,
      );
    }
  }

  void _drawShield(Canvas canvas, Offset c, double r) {
    final path = Path()
      ..moveTo(c.dx - r,       c.dy - r * 0.9)
      ..lineTo(c.dx + r,       c.dy - r * 0.9)
      ..lineTo(c.dx + r,       c.dy + r * 0.1)
      ..quadraticBezierTo(c.dx + r, c.dy + r * 1.05, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - r, c.dy + r * 1.05, c.dx - r, c.dy + r * 0.1)
      ..close();

    // Fond bouclier bicolore (vert + rouge comme le drapeau Congo)
    final shieldPaint = Paint()..shader = LinearGradient(
      colors: [AppColors.congoGreen.withValues(alpha: 0.85),
               AppColors.congoRed.withValues(alpha: 0.85)],
      begin: Alignment.centerLeft, end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(c.dx - r, c.dy - r, r * 2, r * 2));
    canvas.drawPath(path, shieldPaint);

    // Bande jaune diagonale au centre du bouclier
    final diagPath = Path()
      ..moveTo(c.dx - r * 0.15, c.dy - r * 0.9)
      ..lineTo(c.dx + r * 0.15, c.dy - r * 0.9)
      ..lineTo(c.dx + r * 0.6,  c.dy + r * 0.9)
      ..lineTo(c.dx - r * 0.6,  c.dy + r * 0.9)
      ..close();
    canvas.drawPath(diagPath,
        Paint()..color = AppColors.congoYellow.withValues(alpha: 0.7));

    // Bordure or du bouclier
    canvas.drawPath(path,
        Paint()..color = AppColors.gold..style = PaintingStyle.stroke..strokeWidth = r * 0.1);

    // Texte "PNC" sur le bouclier
    final tp = TextPainter(
      text: TextSpan(
        text: 'PNC',
        style: TextStyle(
          color: Colors.white,
          fontSize: r * 0.52,
          fontWeight: FontWeight.w900,
          letterSpacing: r * 0.12,
          shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2 + r * 0.1));
  }

  void _drawLaurel(Canvas canvas, Offset c, double r, {required bool isLeft}) {
    final paint = Paint()
      ..color = AppColors.congoGreen.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    final side = isLeft ? -1.0 : 1.0;
    for (int i = 0; i < 6; i++) {
      final angle = (isLeft
          ? math.pi * 0.35 + (math.pi * 0.55) * i / 5
          : math.pi * 0.10 - (math.pi * 0.55) * i / 5);
      final leafC = Offset(
        c.dx + side * r * (0.65 + i * 0.02) * math.cos(angle),
        c.dy + r * 0.65 * math.sin(angle) + r * 0.15,
      );
      final leafPath = Path()
        ..addOval(Rect.fromCenter(center: leafC, width: r * 0.18, height: r * 0.10));
      canvas.save();
      canvas.translate(leafC.dx, leafC.dy);
      canvas.rotate(angle + (isLeft ? -math.pi / 4 : math.pi / 4));
      canvas.translate(-leafC.dx, -leafC.dy);
      canvas.drawPath(leafPath, paint);
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
      final len = i.isEven ? r : r * 0.4;
      final pt = Offset(c.dx + len * math.cos(angle), c.dy + len * math.sin(angle));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCircularText(Canvas canvas, Offset c, double r, Size size) {
    const text = 'POLICE NATIONALE DU CONGO • CIRCULATION+ •';
    final angleStep = (2 * math.pi) / text.length;
    final startAngle = -math.pi / 2 - text.length * angleStep / 2;

    for (int i = 0; i < text.length; i++) {
      final angle = startAngle + i * angleStep;
      final charOffset = Offset(
        c.dx + r * 0.90 * math.cos(angle),
        c.dy + r * 0.90 * math.sin(angle),
      );
      canvas.save();
      canvas.translate(charOffset.dx, charOffset.dy);
      canvas.rotate(angle + math.pi / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: text[i],
          style: TextStyle(
            color: AppColors.gold.withValues(alpha: 0.8),
            fontSize: size.width * 0.062,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
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

    // Remplissage — vert Congo transparent
    canvas.drawPath(
      path,
      Paint()..color = AppColors.congoGreen.withValues(alpha: 0.10),
    );

    // Contour — or pâle
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.congoYellow.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Points de villes principales
    _drawCity(canvas, Offset(0.55 * w, 0.87 * h), 'BZV', AppColors.congoYellow); // Brazzaville
    _drawCity(canvas, Offset(0.38 * w, 0.30 * h), 'PNR', AppColors.congoRed);   // Pointe-Noire (approx)
    _drawCity(canvas, Offset(0.55 * w, 0.50 * h), 'OUE', Colors.white38);       // Ouesso (nord)

    // Réseau routier stylisé (route nationale 1)
    final roadPath = Path()
      ..moveTo(0.55 * w, 0.87 * h)   // BZV
      ..cubicTo(0.50 * w, 0.70 * h,
                0.44 * w, 0.55 * h,
                0.42 * w, 0.38 * h)
      ..cubicTo(0.40 * w, 0.28 * h,
                0.38 * w, 0.22 * h,
                0.38 * w, 0.30 * h); // PNR (sortie côte)
    canvas.drawPath(roadPath,
        Paint()..color = AppColors.congoYellow.withValues(alpha: 0.12)
            ..style = PaintingStyle.stroke..strokeWidth = 1.0
            ..strokeCap = StrokeCap.round);
  }

  void _drawCity(Canvas canvas, Offset pos, String name, Color color) {
    // Anneau lumineux
    canvas.drawCircle(pos, 5,
        Paint()..color = color.withValues(alpha: 0.15));
    // Point central
    canvas.drawCircle(pos, 2.5,
        Paint()..color = color.withValues(alpha: 0.7));

    final tp = TextPainter(
      text: TextSpan(text: name, style: TextStyle(
        color: color.withValues(alpha: 0.6), fontSize: 8, fontWeight: FontWeight.w600,
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx + 7, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
