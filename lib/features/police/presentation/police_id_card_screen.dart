import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';

// ── Carte d'identité professionnelle PNC ─────────────────────────────────────
// Format : ISO/IEC 7810 ID-1 (85,6 × 54 mm) — proportions respectées.
// Recto : informations agent, photo, sceau PNC, drapeau Congo.
// Verso  : informations de sécurité, code de vérification matriciel.

class PoliceIdCardScreen extends ConsumerStatefulWidget {
  const PoliceIdCardScreen({super.key});

  @override
  ConsumerState<PoliceIdCardScreen> createState() => _PoliceIdCardScreenState();
}

class _PoliceIdCardScreenState extends ConsumerState<PoliceIdCardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _flipCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _hologramCtrl;
  bool _showBack = false;
  final GlobalKey _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _hologramCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _shimmerCtrl.dispose();
    _hologramCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    setState(() => _showBack = !_showBack);
    if (_showBack) {
      _flipCtrl.forward();
    } else {
      _flipCtrl.reverse();
    }
  }

  Future<void> _downloadPdf() async {
    final auth = ref.read(authProvider);
    // Capturer la carte recto comme image
    Uint8List? cardImageBytes;
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        cardImageBytes = data?.buffer.asUint8List();
      }
    } catch (_) {}

    final doc = pw.Document();
    final cardNumber = _cardNumber(auth.userId ?? 'UNKNOWN');
    final validUntil = DateFormat('dd/MM/yyyy').format(
      DateTime.now().add(const Duration(days: 730)),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'REPUBLIQUE DU CONGO',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 18,
                color: PdfColors.green800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'POLICE NATIONALE CONGOLAISE',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
                color: PdfColors.blue900,
              ),
            ),
            pw.Divider(color: PdfColors.amber700, thickness: 2),
            pw.SizedBox(height: 16),
            pw.Text('CARTE PROFESSIONNELLE D\'AGENT DE POLICE',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.SizedBox(height: 24),
            if (cardImageBytes != null) ...[
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(cardImageBytes),
                  width: 380,
                  height: 240,
                ),
              ),
              pw.SizedBox(height: 24),
            ],
            _pdfField('Nom complet', auth.userName ?? '—'),
            _pdfField('Matricule', auth.badgeNumber ?? '—'),
            _pdfField('Téléphone', auth.telephone ?? '—'),
            _pdfField('Email', auth.email ?? '—'),
            _pdfField('Numéro de carte', cardNumber),
            _pdfField('Valide jusqu\'au', validUntil),
            pw.SizedBox(height: 24),
            pw.Text(
              'Ce document est une propriété de la Police Nationale Congolaise. '
              'Toute reproduction non autorisée est formellement interdite.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'carte-pnc-${auth.badgeNumber ?? 'agent'}.pdf',
    );
  }

  static pw.Widget _pdfField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              '$label :',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static String _cardNumber(String userId) {
    const prefix = 'PNC';
    final year = DateTime.now().year;
    final suffix = userId.replaceAll('-', '').substring(0, min(6, userId.replaceAll('-', '').length)).toUpperCase();
    return '$prefix-$year-$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    // Card width = 92% of screen, max 400; height via ratio
    final cardW = min(size.width * 0.92, 400.0);
    final cardH = cardW / 1.586; // ISO ID-1 ratio

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Carte Professionnelle', style: AppTextStyles.titleSmall),
            Text('Police Nationale Congolaise',
                style: AppTextStyles.caption.copyWith(color: AppColors.gold, fontSize: 10)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.gold),
            tooltip: 'Télécharger PDF',
            onPressed: _downloadPdf,
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
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Card with 3D flip ──────────────────────────────────────
                  GestureDetector(
                    onTap: _flip,
                    child: AnimatedBuilder(
                      animation: _flipCtrl,
                      builder: (_, __) {
                        final angle = _flipCtrl.value * pi;
                        final isFront = angle < pi / 2;
                        final transform = Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle);
                        return Transform(
                          transform: transform,
                          alignment: Alignment.center,
                          child: isFront
                              ? RepaintBoundary(
                                  key: _cardKey,
                                  child: _CardFront(
                                    auth: auth,
                                    width: cardW,
                                    height: cardH,
                                    shimmer: _shimmerCtrl,
                                    hologram: _hologramCtrl,
                                  ),
                                )
                              : Transform(
                                  transform: Matrix4.identity()..rotateY(pi),
                                  alignment: Alignment.center,
                                  child: _CardBack(
                                    auth: auth,
                                    width: cardW,
                                    height: cardH,
                                    shimmer: _shimmerCtrl,
                                  ),
                                ),
                        );
                      },
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.88, 0.88), duration: 500.ms, curve: Curves.easeOutBack),

                  const SizedBox(height: 20),

                  // Flip hint
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _shimmerCtrl,
                        builder: (_, child) => Opacity(
                          opacity: 0.5 + 0.5 * sin(_shimmerCtrl.value * 2 * pi),
                          child: child,
                        ),
                        child: const Icon(Icons.touch_app_rounded,
                            size: 14, color: AppColors.gold),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Appuyer pour retourner',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary, fontSize: 11),
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 8),
                  // Security badge
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.congoGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.congoGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 13, color: AppColors.congoGreen),
                        const SizedBox(width: 6),
                        Text(
                          'Document officiel — PNC ${DateTime.now().year}',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.congoGreen, fontSize: 10),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1000.ms),
                ],
              ),
            ),
          ),

          // ── Bottom actions ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.flip_rounded, size: 16),
                    label: Text(_showBack ? 'Voir Recto' : 'Voir Verso'),
                    onPressed: _flip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      side: const BorderSide(color: AppColors.gold),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_rounded,
                        size: 16, color: Colors.white),
                    label: const Text('Télécharger',
                        style: TextStyle(color: Colors.white)),
                    onPressed: _downloadPdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.policeBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

// ─────────────────────────────────────────────────────────────────────────────
// RECTO — Face principale
// ─────────────────────────────────────────────────────────────────────────────

class _CardFront extends StatelessWidget {
  final AuthState auth;
  final double width;
  final double height;
  final Animation<double> shimmer;
  final Animation<double> hologram;

  const _CardFront({
    required this.auth,
    required this.width,
    required this.height,
    required this.shimmer,
    required this.hologram,
  });

  static String _cardNumber(String? userId) {
    if (userId == null) return 'PNC-XXXX-XXXXXX';
    final clean = userId.replaceAll('-', '');
    final suffix = clean.substring(0, min(6, clean.length)).toUpperCase();
    return 'PNC-${DateTime.now().year}-$suffix';
  }

  static String _validUntil() => DateFormat('MM/yyyy')
      .format(DateTime.now().add(const Duration(days: 730)));

  @override
  Widget build(BuildContext context) {
    final cardNum = _cardNumber(auth.userId);
    final validUntil = _validUntil();
    final name = auth.userName ?? '—';
    final badge = auth.badgeNumber ?? '—';
    final tel = auth.telephone ?? '—';

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1F3E), Color(0xFF0A1628), Color(0xFF112040)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Background micro-pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _HexPatternPainter(),
              ),
            ),

            // Congo flag diagonal (top-right corner)
            Positioned.fill(
              child: CustomPaint(
                painter: _CongoFlagDiagonalPainter(),
              ),
            ),

            // Gold border
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            // ── HEADER BAND ────────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: height * 0.26,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.policeBlue.withValues(alpha: 0.9),
                      AppColors.policeNavy.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(width: width * 0.04),
                    // PNC Seal
                    SizedBox(
                      width: height * 0.42,
                      height: height * 0.42,
                      child: CustomPaint(
                        painter: _PncSealPainter(),
                      ),
                    ),
                    SizedBox(width: width * 0.025),
                    // Titles
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REPUBLIQUE DU CONGO',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: height * 0.072,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            'Police Nationale Congolaise',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: height * 0.057,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: height * 0.02),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.025,
                              vertical: height * 0.018,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'CARTE PROFESSIONNELLE',
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: height * 0.046,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: width * 0.03),
                  ],
                ),
              ),
            ),

            // ── BODY ────────────────────────────────────────────────────────
            Positioned(
              top: height * 0.26,
              left: 0,
              right: 0,
              bottom: height * 0.22,
              child: Row(
                children: [
                  // Left: data fields
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.04,
                        vertical: height * 0.04,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _DataRow(
                            label: 'NOM',
                            value: name.toUpperCase(),
                            fontSize: height * 0.066,
                            valueColor: Colors.white,
                            bold: true,
                          ),
                          _DataRow(
                            label: 'MATRICULE',
                            value: badge,
                            fontSize: height * 0.064,
                            valueColor: AppColors.gold,
                            bold: true,
                          ),
                          if (tel.isNotEmpty && tel != '—')
                            _DataRow(
                              label: 'TEL',
                              value: tel,
                              fontSize: height * 0.056,
                              valueColor: AppColors.textSecondary,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Right: officer photo
                  Padding(
                    padding: EdgeInsets.only(right: width * 0.04, top: height * 0.04),
                    child: _OfficerPhoto(
                      photoUrl: auth.photoUrl,
                      initials: auth.initials,
                      size: height * 0.52,
                    ),
                  ),
                ],
              ),
            ),

            // ── FOOTER BAND ─────────────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: height * 0.22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0D1F3E).withValues(alpha: 0.95),
                      AppColors.policeNavy.withValues(alpha: 0.98),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    top: BorderSide(
                        color: AppColors.gold.withValues(alpha: 0.25), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(width: width * 0.04),

                    // Verification matrix (QR-like)
                    SizedBox(
                      width: height * 0.16,
                      height: height * 0.16,
                      child: CustomPaint(
                        painter: _VerificationMatrixPainter(
                          '${auth.userId ?? ""}${auth.badgeNumber ?? ""}',
                        ),
                      ),
                    ),

                    SizedBox(width: width * 0.03),

                    // Card info
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'N° $cardNum',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: height * 0.053,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: height * 0.015),
                          Text(
                            'VALIDE JUSQU\'AU  $validUntil',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: height * 0.044,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: height * 0.012),
                          Text(
                            'SERVIR · PROTEGER · INTEGRITE',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: height * 0.038,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Valid badge
                    Container(
                      margin: EdgeInsets.only(right: width * 0.04),
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.025,
                        vertical: height * 0.025,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.congoGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.congoGreen.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: AppColors.congoGreen, size: height * 0.1),
                          SizedBox(height: height * 0.01),
                          Text(
                            'VALIDE',
                            style: TextStyle(
                              color: AppColors.congoGreen,
                              fontSize: height * 0.042,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── HOLOGRAPHIC SHIMMER OVERLAY ──────────────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: hologram,
                builder: (_, __) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CustomPaint(
                      painter: _HologramPainter(hologram.value),
                    ),
                  );
                },
              ),
            ),

            // ── SHIMMER SWEEP ────────────────────────────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: shimmer,
                builder: (_, __) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CustomPaint(
                      painter: _ShimmerSweepPainter(shimmer.value),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VERSO — Face sécurité
// ─────────────────────────────────────────────────────────────────────────────

class _CardBack extends StatelessWidget {
  final AuthState auth;
  final double width;
  final double height;
  final Animation<double> shimmer;

  const _CardBack({
    required this.auth,
    required this.width,
    required this.height,
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    final cardNumber = auth.userId != null
        ? 'PNC-${DateTime.now().year}-${auth.userId!.replaceAll('-', '').substring(0, min(6, auth.userId!.replaceAll('-', '').length)).toUpperCase()}'
        : 'PNC-XXXX-XXXXXX';

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E1930), Color(0xFF0A1628), Color(0xFF0D2040)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Watermark PNC (large, centered, ghost)
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.04,
                  child: SizedBox(
                    width: height * 1.2,
                    height: height * 1.2,
                    child: CustomPaint(painter: _PncSealPainter()),
                  ),
                ),
              ),
            ),

            // Background pattern
            Positioned.fill(
              child: CustomPaint(painter: _HexPatternPainter()),
            ),

            // Gold border
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35), width: 1.5),
                ),
              ),
            ),

            // Magnetic stripe (top band)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: height * 0.18,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Center(
                  child: Container(
                    height: height * 0.1,
                    margin: EdgeInsets.symmetric(horizontal: width * 0.04),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.brown.shade900,
                          Colors.brown.shade700,
                          Colors.brown.shade900,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            // Security content
            Positioned(
              top: height * 0.2,
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: height * 0.03),

                    // Top row: signature zone + large matrix
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Signature zone
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SIGNATURE',
                                style: TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: height * 0.042,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              SizedBox(height: height * 0.015),
                              Container(
                                height: height * 0.14,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: AppColors.gold.withValues(alpha: 0.2)),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: width * 0.03),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(bottom: height * 0.02),
                                      child: Text(
                                        '✦ ${(auth.userName ?? '').split(' ').first}',
                                        style: TextStyle(
                                          color: AppColors.gold.withValues(alpha: 0.7),
                                          fontSize: height * 0.065,
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: height * 0.01),
                              Text(
                                auth.userName?.toUpperCase() ?? '',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: height * 0.044,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: width * 0.04),

                        // Large verification matrix
                        Column(
                          children: [
                            Text(
                              'CODE VERIFICATEUR',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: height * 0.038,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: height * 0.015),
                            SizedBox(
                              width: height * 0.25,
                              height: height * 0.25,
                              child: CustomPaint(
                                painter: _VerificationMatrixPainter(
                                  '${auth.userId ?? ""}${auth.badgeNumber ?? ""}',
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Security text bands
                    _SecurityBand(
                      text: 'POLICE NATIONALE CONGOLAISE · REPUBLIQUE DU CONGO · '
                          'POLICE NATIONALE CONGOLAISE · REPUBLIQUE DU CONGO · ',
                      height: height,
                    ),
                    SizedBox(height: height * 0.015),

                    // Card number & info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cardNumber,
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: height * 0.052,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Row(
                          children: [
                            _CongoMiniFlag(size: height * 0.09),
                            SizedBox(width: width * 0.02),
                            Text(
                              'COG',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: height * 0.05,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.04),
                  ],
                ),
              ),
            ),

            // Shimmer sweep
            Positioned.fill(
              child: AnimatedBuilder(
                animation: shimmer,
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CustomPaint(
                    painter: _ShimmerSweepPainter(shimmer.value),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final double fontSize;
  final Color valueColor;
  final bool bold;

  const _DataRow({
    required this.label,
    required this.value,
    required this.fontSize,
    required this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.gold.withValues(alpha: 0.7),
            fontSize: fontSize * 0.72,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: fontSize,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            letterSpacing: 0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _OfficerPhoto extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final double size;

  const _OfficerPhoto({
    required this.photoUrl,
    required this.initials,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.goldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.policeNavy,
        ),
        clipBehavior: Clip.antiAlias,
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _AvatarFallback(
                    initials: initials, size: size),
              )
            : _AvatarFallback(initials: initials, size: size),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;
  final double size;
  const _AvatarFallback({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.policeBlue,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppColors.gold,
            fontSize: size * 0.34,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CongoMiniFlag extends StatelessWidget {
  final double size;
  const _CongoMiniFlag({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.5,
      height: size,
      child: CustomPaint(painter: _CongoMiniPainter()),
    );
  }
}

class _SecurityBand extends StatelessWidget {
  final String text;
  final double height;
  const _SecurityBand({required this.text, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height * 0.075,
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        border: Border.symmetric(
          horizontal: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.2), width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Opacity(
          opacity: 0.4,
          child: Text(
            text * 3,
            style: TextStyle(
              color: AppColors.gold,
              fontSize: height * 0.038,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters
// ─────────────────────────────────────────────────────────────────────────────

/// Sceau PNC (Police Nationale Congolaise) — vectoriel, reproduit fidèlement.
class _PncSealPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = min(w, h) / 2;

    // ── Outer glow ───────────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );

    // ── Outer gold ring ──────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.97,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFE8C870),
            Color(0xFFC9A84C),
            Color(0xFF9A7830),
            Color(0xFFC9A84C),
            Color(0xFFE8C870),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r))
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07,
    );

    // ── Navy fill ────────────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.9,
      Paint()..color = AppColors.policeNavy,
    );

    // ── Inner ring ───────────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.82,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.018,
    );

    // ── Congo flag arc (bottom) ───────────────────────────────────────────────
    final arcRect =
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.815);
    const sweepA = pi * 0.52;
    const startA = pi * 0.64;
    final stripeW = r * 0.055;
    final colors = [
      AppColors.congoGreen,
      AppColors.congoYellow,
      AppColors.congoRed,
    ];
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(
        arcRect,
        startA + (sweepA / 3) * i,
        sweepA / 3,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = stripeW
          ..strokeCap = StrokeCap.butt,
      );
    }

    // ── Stars (5, in arc above shield) ───────────────────────────────────────
    final starPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE8C870), Color(0xFFC9A84C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    for (int i = 0; i < 5; i++) {
      final angle = -pi * 0.85 + (pi * 0.70) * i / 4;
      final sc = Offset(
        cx + (r * 0.62) * cos(angle),
        cy + (r * 0.62) * sin(angle) - r * 0.06,
      );
      _star(canvas, sc, r * 0.07, starPaint);
    }

    // ── Shield ───────────────────────────────────────────────────────────────
    final sCx = cx;
    final sCy = cy + r * 0.06;
    final sr = r * 0.42;
    final shieldPath = Path()
      ..moveTo(sCx - sr * 0.85, sCy - sr)
      ..lineTo(sCx + sr * 0.85, sCy - sr)
      ..lineTo(sCx + sr * 0.85, sCy + sr * 0.1)
      ..quadraticBezierTo(sCx + sr * 0.85, sCy + sr, sCx, sCy + sr * 1.05)
      ..quadraticBezierTo(sCx - sr * 0.85, sCy + sr, sCx - sr * 0.85, sCy + sr * 0.1)
      ..close();

    canvas.drawPath(shieldPath, Paint()..color = AppColors.policeBlue);
    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = sr * 0.1,
    );

    // "PNC" text on shield
    final tp = TextPainter(
      text: TextSpan(
        text: 'PNC',
        style: TextStyle(
          color: AppColors.gold,
          fontSize: sr * 0.55,
          fontWeight: FontWeight.w900,
          letterSpacing: sr * 0.07,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(sCx - tp.width / 2, sCy - tp.height / 2 + sr * 0.1));
  }

  void _star(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final a = (i * pi / 5) - pi / 2;
      final len = i.isEven ? r : r * 0.42;
      final pt = Offset(c.dx + len * cos(a), c.dy + len * sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Drapeau Congo diagonal (coin supérieur droit de la carte).
class _CongoFlagDiagonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Triangle supérieur droit avec les 3 couleurs du drapeau congolais
    // Drapeau Congo : diagonale de bas-gauche à haut-droit
    // Vert (haut-gauche), Jaune (bande centrale diagonale), Rouge (bas-droit)

    final stripeW = w * 0.28; // largeur de la zone drapeau

    // Zone drapeau = triangle coin supérieur droit
    final clip = Path()
      ..moveTo(w - stripeW * 3, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.38)
      ..close();
    canvas.save();
    canvas.clipPath(clip);

    // Fond vert
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = AppColors.congoGreen.withValues(alpha: 0.85),
    );

    // Bande jaune diagonale
    final yellow = Paint()..color = AppColors.congoYellow;
    final yPath = Path()
      ..moveTo(w - stripeW * 2.2, 0)
      ..lineTo(w - stripeW * 1.4, 0)
      ..lineTo(w, h * 0.28)
      ..lineTo(w, h * 0.42)
      ..close();
    canvas.drawPath(yPath, yellow);

    // Zone rouge (bas-droit du drapeau)
    final red = Paint()..color = AppColors.congoRed.withValues(alpha: 0.9);
    final rPath = Path()
      ..moveTo(w - stripeW * 1.4, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.28)
      ..close();
    canvas.drawPath(rPath, red);

    canvas.restore();

    // Subtle edge shadow to blend with card
    canvas.drawRect(
      Rect.fromLTWH(w - stripeW * 3 - 1, 0, 2, h),
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.2)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ).createShader(Rect.fromLTWH(w - stripeW * 3 - 1, 0, 2, h)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Mini drapeau Congo pour le verso.
class _CongoMiniPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 3 bandes diagonales : vert, jaune, rouge (bas-gauche → haut-droite)
    final Path green = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.55, 0)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(green, Paint()..color = AppColors.congoGreen);

    final Path yellow = Path()
      ..moveTo(w * 0.55, 0)
      ..lineTo(w * 0.78, 0)
      ..lineTo(w * 0.22, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(yellow, Paint()..color = AppColors.congoYellow);

    final Path red = Path()
      ..moveTo(w * 0.78, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(w * 0.22, h)
      ..close();
    canvas.drawPath(red, Paint()..color = AppColors.congoRed);

    // Border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Pattern hexagonal de fond (micro-sécurité).
class _HexPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const cellR = 14.0;
    final colW = cellR * sqrt(3);
    const rowH = cellR * 1.5;

    int row = 0;
    for (double y = 0; y < size.height + rowH; y += rowH) {
      final offsetX = (row % 2 == 0) ? 0.0 : colW / 2;
      for (double x = -colW + offsetX; x < size.width + colW; x += colW) {
        _drawHex(canvas, Offset(x, y), cellR, paint);
      }
      row++;
    }
  }

  void _drawHex(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = (i * pi / 3) - pi / 6;
      final pt = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Code de vérification matriciel unique par agent (basé sur son ID).
class _VerificationMatrixPainter extends CustomPainter {
  final String data;
  final Color color;

  _VerificationMatrixPainter(this.data, {this.color = AppColors.gold});

  static const int _n = 11; // 11×11 modules

  List<bool> _generateBits() {
    // Hash déterministe djb2
    int h = 5381;
    for (final c in data.codeUnits) {
      h = ((h << 5) + h + c) & 0x7FFFFFFF;
    }
    // LFSR pour étendre les bits
    final bits = <bool>[];
    int val = h == 0 ? 1 : h;
    for (int i = 0; i < _n * _n; i++) {
      bits.add((val & 1) == 1);
      final bit = (val ^ (val >> 1) ^ (val >> 3) ^ (val >> 4)) & 1;
      val = ((val >> 1) | (bit << 30)) & 0x7FFFFFFF;
    }
    return bits;
  }

  bool _isFinderCorner(int r, int c) {
    // 3×3 finder patterns aux 3 coins
    return (r < 3 && c < 3) ||
        (r < 3 && c >= _n - 3) ||
        (r >= _n - 3 && c < 3);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bits = _generateBits();
    final cellW = size.width / _n;
    final cellH = size.height / _n;
    final quietZone = cellW * 0.12;

    final paint = Paint()..color = color;
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.08);

    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    for (int row = 0; row < _n; row++) {
      for (int col = 0; col < _n; col++) {
        final x = col * cellW;
        final y = row * cellH;

        if (_isFinderCorner(row, col)) {
          // Finder pattern : toujours plein dans le coin, vide au centre 1×1
          final inner = (row >= 1 && row <= 1 && col >= 1 && col <= 1) ||
              (row >= 1 && row <= 1 && col >= _n - 2 && col <= _n - 2) ||
              (row >= _n - 2 && row <= _n - 2 && col >= 1 && col <= 1);
          canvas.drawRect(
            Rect.fromLTWH(x + quietZone, y + quietZone,
                cellW - quietZone * 2, cellH - quietZone * 2),
            inner ? (Paint()..color = color.withValues(alpha: 0.1)) : paint,
          );
        } else if (bits[row * _n + col]) {
          canvas.drawRect(
            Rect.fromLTWH(x + quietZone, y + quietZone,
                cellW - quietZone * 2, cellH - quietZone * 2),
            paint,
          );
        }
      }
    }

    // Border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(_VerificationMatrixPainter old) => old.data != data;
}

/// Hologramme animé (arc-en-ciel diagonal, très subtil).
class _HologramPainter extends CustomPainter {
  final double t; // 0..1

  _HologramPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Bandes arc-en-ciel qui défilent diagonalement
    const stripeCount = 6;
    for (int i = 0; i < stripeCount; i++) {
      final phase = (i / stripeCount + t) % 1.0;
      final hue = (phase * 360) % 360;
      final color = HSVColor.fromAHSV(0.04, hue, 0.8, 1.0).toColor();

      final x = -w * 0.3 + (w * 1.6) * phase;
      final path = Path()
        ..moveTo(x - w * 0.08, 0)
        ..lineTo(x + w * 0.08, 0)
        ..lineTo(x + w * 0.12 + h * 0.3, h)
        ..lineTo(x - w * 0.04 + h * 0.3, h)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_HologramPainter old) => old.t != t;
}

/// Balayage de lumière (shimmer) sur la carte.
class _ShimmerSweepPainter extends CustomPainter {
  final double t;

  _ShimmerSweepPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final sweepX = -size.width * 0.3 + size.width * 1.6 * t;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
          begin: Alignment(
              (sweepX / size.width) * 2 - 1, -0.5),
          end: Alignment(
              (sweepX / size.width) * 2 - 1 + 0.4, 0.5),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ShimmerSweepPainter old) => old.t != t;
}
