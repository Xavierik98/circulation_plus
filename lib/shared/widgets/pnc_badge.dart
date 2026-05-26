import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PncArmoirie — armoirie complète de la Police Nationale du Congo
// Cercle or → fond marine → étoiles → bouclier bicolore → lauriers → texte
// Utilisation : PncArmoirie(size: 120)
// ─────────────────────────────────────────────────────────────────────────────
class PncArmoirie extends StatelessWidget {
  final double size;
  final bool showGlow;
  const PncArmoirie({super.key, this.size = 100, this.showGlow = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: PncArmoiriePainter(showGlow: showGlow)),
    );
  }
}

/// Peintre public pour l'armoirie PNC (accessible dans les autres écrans).
class PncArmoiriePainter extends CustomPainter {
  final bool showGlow;
  const PncArmoiriePainter({this.showGlow = true});

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
        Paint()..color = AppColors.gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.055);

    // ── Fond marine ───────────────────────────────────────────────────────
    canvas.drawCircle(Offset(cx, cy), r * 0.88,
        Paint()..color = AppColors.policeNavy);

    // ── Anneau intérieur or fin ───────────────────────────────────────────
    canvas.drawCircle(Offset(cx, cy), r * 0.80,
        Paint()..color = AppColors.gold.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.013);

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
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.butt,
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

    // Fond bicolore vert/rouge (drapeau Congo)
    canvas.drawPath(path, Paint()..shader = LinearGradient(
      colors: [AppColors.congoGreen.withValues(alpha: 0.85),
               AppColors.congoRed.withValues(alpha: 0.85)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(Rect.fromLTWH(c.dx - r, c.dy - r, r * 2, r * 2)));

    // Bande jaune diagonale
    final diagPath = Path()
      ..moveTo(c.dx - r * 0.15, c.dy - r * 0.9)
      ..lineTo(c.dx + r * 0.15, c.dy - r * 0.9)
      ..lineTo(c.dx + r * 0.6,  c.dy + r * 0.9)
      ..lineTo(c.dx - r * 0.6,  c.dy + r * 0.9)
      ..close();
    canvas.drawPath(diagPath,
        Paint()..color = AppColors.congoYellow.withValues(alpha: 0.70));

    // Bordure or
    canvas.drawPath(path,
        Paint()..color = AppColors.gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.10);

    // Texte "PNC"
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
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2 + r * 0.10));
  }

  void _drawLaurel(Canvas canvas, Offset c, double r, {required bool isLeft}) {
    final paint = Paint()
      ..color = AppColors.congoGreen.withValues(alpha: 0.70)
      ..style = PaintingStyle.fill;
    final side = isLeft ? -1.0 : 1.0;
    for (int i = 0; i < 6; i++) {
      final angle = isLeft
          ? math.pi * 0.35 + (math.pi * 0.55) * i / 5
          : math.pi * 0.10 - (math.pi * 0.55) * i / 5;
      final leafC = Offset(
        c.dx + side * r * (0.65 + i * 0.02) * math.cos(angle),
        c.dy + r * 0.65 * math.sin(angle) + r * 0.15,
      );
      final leafPath = Path()
        ..addOval(Rect.fromCenter(center: leafC, width: r * 0.18, height: r * 0.10));
      canvas
        ..save()
        ..translate(leafC.dx, leafC.dy)
        ..rotate(angle + (isLeft ? -math.pi / 4 : math.pi / 4))
        ..translate(-leafC.dx, -leafC.dy)
        ..drawPath(leafPath, paint)
        ..restore();
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
      canvas
        ..save()
        ..translate(charOffset.dx, charOffset.dy)
        ..rotate(angle + math.pi / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: text[i],
          style: TextStyle(
            color: AppColors.gold.withValues(alpha: 0.80),
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

// ─────────────────────────────────────────────────────────────────────────────
// PncBadge — badge simplifié (login screen, AppBar, cartes)
// ─────────────────────────────────────────────────────────────────────────────
class PncBadge extends StatelessWidget {
  final double size;
  final bool showGlow;
  const PncBadge({super.key, this.size = 72, this.showGlow = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PncBadgePainter(showGlow: showGlow)),
    );
  }
}

class _PncBadgePainter extends CustomPainter {
  final bool showGlow;
  const _PncBadgePainter({this.showGlow = true});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final center = Offset(w / 2, size.height / 2);
    final r = w / 2;

    if (showGlow) {
      canvas.drawCircle(center, r,
        Paint()..shader = RadialGradient(
          colors: [AppColors.gold.withValues(alpha: 0.25), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: r)));
    }

    // Outer gold ring
    canvas.drawCircle(center, r - w * 0.02,
        Paint()..color = AppColors.gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.045);

    // Navy fill
    canvas.drawCircle(center, r - w * 0.065,
        Paint()..color = AppColors.policeNavy);

    // Inner gold ring
    canvas.drawCircle(center, r - w * 0.15,
        Paint()..color = AppColors.gold.withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.012);

    // Congo flag stripe
    _drawCongoStripe(canvas, center, r - w * 0.165);

    // Shield
    _drawShield(canvas, Offset(center.dx, center.dy + r * 0.06), r * 0.44);

    // 5 stars
    final starPaint = Paint()..color = AppColors.gold;
    for (int i = 0; i < 5; i++) {
      final angle = -math.pi * 0.88 + (math.pi * 0.76) * i / 4;
      final sc = Offset(
        center.dx + (r * 0.6) * math.cos(angle),
        center.dy + (r * 0.6) * math.sin(angle) - r * 0.08,
      );
      _drawStar(canvas, sc, r * 0.055, starPaint);
    }
  }

  void _drawCongoStripe(Canvas canvas, Offset center, double r) {
    const sweepAngle = math.pi * 0.5;
    const startAngle = math.pi * 0.65;
    final rect = Rect.fromCircle(center: center, radius: r);
    final colors = [AppColors.congoGreen, AppColors.congoYellow, AppColors.congoRed];
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(rect,
        startAngle + (sweepAngle / 3) * i,
        sweepAngle / 3,
        false,
        Paint()..color = colors[i].withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0
            ..strokeCap = StrokeCap.butt,
      );
    }
  }

  void _drawShield(Canvas canvas, Offset center, double r) {
    final path = Path()
      ..moveTo(center.dx - r * 0.9, center.dy - r)
      ..lineTo(center.dx + r * 0.9, center.dy - r)
      ..lineTo(center.dx + r * 0.9, center.dy + r * 0.1)
      ..quadraticBezierTo(
          center.dx + r * 0.9, center.dy + r * 1.1, center.dx, center.dy + r)
      ..quadraticBezierTo(
          center.dx - r * 0.9, center.dy + r * 1.1, center.dx - r * 0.9, center.dy + r * 0.1)
      ..close();

    canvas.drawPath(path, Paint()..color = AppColors.policeBlue);
    canvas.drawPath(path,
        Paint()..color = AppColors.gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.08);

    final tp = TextPainter(
      text: TextSpan(
        text: 'PNC',
        style: TextStyle(
          color: AppColors.gold,
          fontSize: r * 0.58,
          fontWeight: FontWeight.w900,
          letterSpacing: r * 0.1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2 + r * 0.12));
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
      final len = i.isEven ? radius : radius * 0.4;
      final pt = Offset(
          center.dx + len * math.cos(angle), center.dy + len * math.sin(angle));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
