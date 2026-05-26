import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PncArmoirie — armoirie complète de la Police Nationale du Congo
// Utilisation : PncArmoirie(size: 140)
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

/// Peintre public pour l'armoirie PNC.
class PncArmoiriePainter extends CustomPainter {
  final bool showGlow;
  const PncArmoiriePainter({this.showGlow = true});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cx = w / 2;
    final cy = size.height / 2;
    final r  = w / 2;

    // ── Halo extérieur ────────────────────────────────────────────────────
    if (showGlow) {
      canvas.drawCircle(
        Offset(cx, cy), r,
        Paint()..shader = RadialGradient(colors: [
          AppColors.gold.withValues(alpha: 0.35),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
    }

    // ── Anneau extérieur or (épais, bien visible) ─────────────────────────
    canvas.drawCircle(Offset(cx, cy), r * 0.95,
        Paint()
          ..color = AppColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.07);  // 8.4px @ 120 — visible

    // ── Fond marine foncé ─────────────────────────────────────────────────
    canvas.drawCircle(Offset(cx, cy), r * 0.855,
        Paint()..color = AppColors.policeNavy);

    // ── Anneau intérieur or (séparateur) ──────────────────────────────────
    canvas.drawCircle(Offset(cx, cy), r * 0.775,
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.018);  // 2.2px @ 120

    // ── Zone texte circulaire (bande entre les deux anneaux) ──────────────
    _drawCircularText(canvas, Offset(cx, cy), r * 0.815, size);

    // ── Bandes tricolores Congo (3 arcs en bas) ───────────────────────────
    _drawCongoArcs(canvas, Offset(cx, cy), r * 0.74);

    // ── 5 étoiles or en arc au-dessus du bouclier ─────────────────────────
    final starPaint = Paint()..color = AppColors.congoYellow;
    for (int i = 0; i < 5; i++) {
      final angle = -math.pi * 0.80 + (math.pi * 0.60) * i / 4;
      final sc = Offset(
        cx + (r * 0.55) * math.cos(angle),
        cy + (r * 0.55) * math.sin(angle) - r * 0.05,
      );
      _drawStar(canvas, sc, r * 0.10, starPaint);  // 6px @ 120 — visible !
    }

    // ── Bouclier central ──────────────────────────────────────────────────
    _drawShield(canvas, Offset(cx, cy + r * 0.06), r * 0.40);

    // ── Lauriers de chaque côté ───────────────────────────────────────────
    _drawLaurel(canvas, Offset(cx, cy + r * 0.06), r * 0.72, isLeft: true);
    _drawLaurel(canvas, Offset(cx, cy + r * 0.06), r * 0.72, isLeft: false);
  }

  // ─── Arcs tricolores Congo ─────────────────────────────────────────────────
  void _drawCongoArcs(Canvas canvas, Offset c, double r) {
    final colors = [AppColors.congoGreen, AppColors.congoYellow, AppColors.congoRed];
    const startAngle = math.pi * 0.60;
    const totalSweep = math.pi * 0.80;
    final rect = Rect.fromCircle(center: c, radius: r);
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(
        rect,
        startAngle + totalSweep / 3 * i,
        totalSweep / 3,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.095   // proportionnel au rayon
          ..strokeCap = StrokeCap.butt,
      );
    }
  }

  // ─── Bouclier bicolore vert/rouge + diagonale jaune + "PNC" ──────────────────
  void _drawShield(Canvas canvas, Offset c, double r) {
    final path = Path()
      ..moveTo(c.dx - r,       c.dy - r * 0.85)
      ..lineTo(c.dx + r,       c.dy - r * 0.85)
      ..lineTo(c.dx + r,       c.dy + r * 0.05)
      ..quadraticBezierTo(c.dx + r, c.dy + r * 1.0, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - r, c.dy + r * 1.0, c.dx - r, c.dy + r * 0.05)
      ..close();

    // Fond vert/rouge (drapeau Congo)
    canvas.drawPath(path, Paint()
      ..shader = LinearGradient(
        colors: [AppColors.congoGreen, AppColors.congoRed],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(c.dx - r, c.dy - r, r * 2, r * 2)));

    // Diagonale jaune
    canvas.save();
    canvas.clipPath(path);
    final diagPath = Path()
      ..moveTo(c.dx - r * 0.18, c.dy - r * 0.85)
      ..lineTo(c.dx + r * 0.18, c.dy - r * 0.85)
      ..lineTo(c.dx + r * 0.65, c.dy + r)
      ..lineTo(c.dx - r * 0.65, c.dy + r)
      ..close();
    canvas.drawPath(diagPath,
        Paint()..color = AppColors.congoYellow.withValues(alpha: 0.85));
    canvas.restore();

    // Bordure or épaisse
    canvas.drawPath(path,
        Paint()
          ..color = AppColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.12);

    // Texte "PNC" blanc en gras
    final fontSize = (r * 0.58).clamp(9.0, 36.0);
    final tp = TextPainter(
      text: TextSpan(
        text: 'PNC',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: fontSize * 0.18,
          shadows: const [
            Shadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1))
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(c.dx - tp.width / 2, c.dy - tp.height / 2 + r * 0.08));
  }

  // ─── Lauriers ──────────────────────────────────────────────────────────────
  void _drawLaurel(Canvas canvas, Offset c, double r, {required bool isLeft}) {
    final paint = Paint()
      ..color = AppColors.congoGreen.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    final side = isLeft ? -1.0 : 1.0;
    const leafCount = 7;
    for (int i = 0; i < leafCount; i++) {
      final t = i / (leafCount - 1);
      final angle = isLeft
          ? math.pi * 0.30 + (math.pi * 0.60) * t
          : math.pi * 0.10 - (math.pi * 0.60) * t;
      final dist = r * (0.62 + i * 0.015);
      final leafC = Offset(
        c.dx + side * dist * math.cos(angle),
        c.dy + dist * math.sin(angle) + r * 0.10,
      );
      final leafW = r * 0.26;
      final leafH = r * 0.14;
      canvas
        ..save()
        ..translate(leafC.dx, leafC.dy)
        ..rotate(angle + (isLeft ? -math.pi * 0.35 : math.pi * 0.35))
        ..drawOval(
            Rect.fromCenter(
                center: Offset.zero, width: leafW, height: leafH),
            paint)
        ..restore();
    }
    // Tige
    final stemPaint = Paint()
      ..color = AppColors.congoGreen.withValues(alpha: 0.6)
      ..strokeWidth = r * 0.03
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(c.dx + side * r * 0.62, c.dy + r * 0.55),
      Offset(c.dx + side * r * 0.72, c.dy - r * 0.12),
      stemPaint,
    );
  }

  // ─── Étoile à 5 branches ───────────────────────────────────────────────────
  void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
      final len = i.isEven ? r : r * 0.42;
      final pt = Offset(c.dx + len * math.cos(angle), c.dy + len * math.sin(angle));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
    // Contour léger pour le relief
    canvas.drawPath(path,
        Paint()
          ..color = AppColors.gold.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.15);
  }

  // ─── Texte circulaire entre les deux anneaux ──────────────────────────────
  void _drawCircularText(Canvas canvas, Offset c, double r, Size size) {
    // Texte court pour rester lisible — un seul tour complet
    const text = 'POLICE NATIONALE DU CONGO • CIRCULATION+ •';
    final fs = (size.width * 0.085).clamp(7.0, 14.0);  // 10.2px @ 120
    final angleStep = (2 * math.pi) / text.length;
    final startAngle = -math.pi / 2 - text.length * angleStep / 2;

    for (int i = 0; i < text.length; i++) {
      final angle = startAngle + i * angleStep;
      final charX = c.dx + r * math.cos(angle);
      final charY = c.dy + r * math.sin(angle);
      canvas
        ..save()
        ..translate(charX, charY)
        ..rotate(angle + math.pi / 2);
      final tp = TextPainter(
        text: TextSpan(
          text: text[i],
          style: TextStyle(
            color: AppColors.gold,
            fontSize: fs,
            fontWeight: FontWeight.w800,
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
// PncBadge — badge simplifié (AppBar, login, petits contextes)
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
            colors: [AppColors.gold.withValues(alpha: 0.30), Colors.transparent],
          ).createShader(Rect.fromCircle(center: center, radius: r)));
    }

    canvas.drawCircle(center, r * 0.95,
        Paint()..color = AppColors.gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.065);

    canvas.drawCircle(center, r * 0.855,
        Paint()..color = AppColors.policeNavy);

    canvas.drawCircle(center, r * 0.775,
        Paint()..color = AppColors.gold.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.015);

    _drawCongoStripe(canvas, center, r * 0.73);
    _drawShield(canvas, Offset(center.dx, center.dy + r * 0.06), r * 0.42);

    final starPaint = Paint()..color = AppColors.gold;
    for (int i = 0; i < 5; i++) {
      final angle = -math.pi * 0.82 + (math.pi * 0.64) * i / 4;
      final sc = Offset(
        center.dx + (r * 0.60) * math.cos(angle),
        center.dy + (r * 0.60) * math.sin(angle) - r * 0.08,
      );
      _drawStar(canvas, sc, r * 0.095, starPaint);
    }
  }

  void _drawCongoStripe(Canvas canvas, Offset center, double r) {
    const sweepAngle = math.pi * 0.55;
    const startAngle = math.pi * 0.60;
    final rect = Rect.fromCircle(center: center, radius: r);
    final colors = [AppColors.congoGreen, AppColors.congoYellow, AppColors.congoRed];
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(rect,
          startAngle + (sweepAngle / 3) * i,
          sweepAngle / 3,
          false,
          Paint()..color = colors[i]
              ..style = PaintingStyle.stroke
              ..strokeWidth = r * 0.10
              ..strokeCap = StrokeCap.butt);
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
          center.dx - r * 0.9, center.dy + r * 1.1,
          center.dx - r * 0.9, center.dy + r * 0.1)
      ..close();

    canvas.drawPath(path, Paint()..color = AppColors.policeBlue);
    canvas.drawPath(path,
        Paint()..color = AppColors.gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.09);

    final tp = TextPainter(
      text: TextSpan(
        text: 'PNC',
        style: TextStyle(
          color: AppColors.gold,
          fontSize: (r * 0.58).clamp(7.0, 28.0),
          fontWeight: FontWeight.w900,
          letterSpacing: r * 0.10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(center.dx - tp.width / 2,
               center.dy - tp.height / 2 + r * 0.12));
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
      final len = i.isEven ? radius : radius * 0.42;
      final pt = Offset(
          center.dx + len * math.cos(angle),
          center.dy + len * math.sin(angle));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
