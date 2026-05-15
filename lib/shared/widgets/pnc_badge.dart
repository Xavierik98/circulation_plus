import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

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
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [AppColors.gold.withValues(alpha: 0.25), Colors.transparent],
        ).createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, glowPaint);
    }

    // Outer gold ring
    canvas.drawCircle(
      center,
      r - w * 0.02,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045,
    );

    // Navy fill
    canvas.drawCircle(
      center,
      r - w * 0.065,
      Paint()..color = AppColors.policeNavy,
    );

    // Thin inner gold ring
    canvas.drawCircle(
      center,
      r - w * 0.15,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012,
    );

    // Congo flag stripe (3-color arc at bottom)
    _drawCongoStripe(canvas, center, r - w * 0.165);

    // Shield
    final shieldCenterY = center.dy + r * 0.06;
    _drawShield(canvas, Offset(center.dx, shieldCenterY), r * 0.44);

    // 5 stars in arc above shield
    final starPaint = Paint()..color = AppColors.gold;
    for (int i = 0; i < 5; i++) {
      final angle = -pi * 0.88 + (pi * 0.76) * i / 4;
      final starCenter = Offset(
        center.dx + (r * 0.6) * cos(angle),
        center.dy + (r * 0.6) * sin(angle) - r * 0.08,
      );
      _drawStar(canvas, starCenter, r * 0.055, starPaint);
    }
  }

  void _drawCongoStripe(Canvas canvas, Offset center, double r) {
    const sweepAngle = pi * 0.5;
    const startAngle = pi * 0.65;
    final rect = Rect.fromCircle(center: center, radius: r);
    const strokeWidth = 3.0;

    for (int i = 0; i < 3; i++) {
      final colors = [AppColors.congoGreen, AppColors.congoYellow, AppColors.congoRed];
      canvas.drawArc(
        rect,
        startAngle + (sweepAngle / 3) * i,
        sweepAngle / 3,
        false,
        Paint()
          ..color = colors[i].withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
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
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.08,
    );

    // "PNC" on shield
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
      final angle = (i * pi / 5) - pi / 2;
      final len = i.isEven ? radius : radius * 0.4;
      final pt = Offset(center.dx + len * cos(angle), center.dy + len * sin(angle));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
