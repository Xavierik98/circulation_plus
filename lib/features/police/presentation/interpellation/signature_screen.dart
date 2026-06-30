import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/stitch_colors.dart';
import '../../../../shared/models/interpellation_state.dart';

/// Design Stitch "Signature PV".
class SignatureScreen extends ConsumerStatefulWidget {
  const SignatureScreen({super.key});

  @override
  ConsumerState<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends ConsumerState<SignatureScreen> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _hasSignature = false;
  bool _refusedToSign = false;

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = [details.localPosition];
      _hasSignature = true;
      _refusedToSign = false;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _currentStroke.add(details.localPosition));
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _strokes.add(List.from(_currentStroke));
      _currentStroke = [];
    });
  }

  void _clearSignature() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
      _hasSignature = false;
    });
  }

  String _fmt(int amount) {
    if (amount < 1000) return amount.toString();
    final thousands = amount ~/ 1000;
    final remainder = amount % 1000;
    if (remainder == 0) return '$thousands.000';
    return '$thousands.${remainder.toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(interpellationProvider);
    return Scaffold(
      backgroundColor: StitchColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: StitchColors.surface,
                border: Border(bottom: BorderSide(color: StitchColors.outlineVariant)),
              ),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: StitchColors.onSurface, size: 20), onPressed: () => context.pop()),
                  const Icon(Icons.security, color: StitchColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Circulation+', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: StitchColors.primary)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.more_vert, color: StitchColors.onSurface, size: 20), onPressed: () {}),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(s),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: _identityBox('Agent', '—')),
                        const SizedBox(width: 8),
                        Expanded(child: _identityBox('Contrevenant', s.driverName.isNotEmpty ? s.driverName : '—')),
                      ],
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text('Signature Électronique', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: StitchColors.onSurface)),
                        const Spacer(),
                        const Icon(Icons.verified_user, color: StitchColors.primary, size: 16),
                        const SizedBox(width: 4),
                        Text('Sécurisé', style: GoogleFonts.inter(fontSize: 11, color: StitchColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text("Signature de l'Agent verbalisateur", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: StitchColors.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Container(
                      height: 128,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: StitchColors.outlineVariant, width: 2),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: StitchColors.primary),
                            const SizedBox(width: 8),
                            Text('Signé électroniquement', style: GoogleFonts.inter(fontSize: 13, color: StitchColors.primary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Signature du Contrevenant', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: StitchColors.onSurfaceVariant)),
                        GestureDetector(
                          onTap: () => setState(() {
                            _refusedToSign = !_refusedToSign;
                            if (_refusedToSign) _clearSignature();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _refusedToSign ? StitchColors.onSurfaceVariant : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _refusedToSign ? StitchColors.onSurfaceVariant : StitchColors.tertiary),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_refusedToSign ? Icons.edit : Icons.block, size: 14, color: _refusedToSign ? Colors.white : StitchColors.tertiary),
                                const SizedBox(width: 4),
                                Text(_refusedToSign ? 'Annuler le refus' : 'Refus de signer',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _refusedToSign ? Colors.white : StitchColors.tertiary)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: StitchColors.outlineVariant, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                if (!_hasSignature && !_refusedToSign)
                                  const Center(child: Icon(Icons.draw_outlined, size: 28, color: StitchColors.outlineVariant)),
                                GestureDetector(
                                  onPanStart: _refusedToSign ? null : _onPanStart,
                                  onPanUpdate: _refusedToSign ? null : _onPanUpdate,
                                  onPanEnd: _refusedToSign ? null : _onPanEnd,
                                  child: CustomPaint(
                                    painter: _SignaturePainter(strokes: _strokes, currentStroke: _currentStroke),
                                    size: Size.infinite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_refusedToSign)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: StitchColors.surfaceContainerHigh.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.gavel, color: StitchColors.tertiary, size: 40),
                                    const SizedBox(height: 6),
                                    Text('LE CONTREVENANT A REFUSÉ DE SIGNER',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: StitchColors.tertiary)),
                                    const SizedBox(height: 4),
                                    Text('Mention portée d\'office au procès-verbal',
                                        style: GoogleFonts.inter(fontSize: 10, color: StitchColors.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (_hasSignature && !_refusedToSign)
                          Positioned(
                            right: 4, top: 4,
                            child: IconButton(icon: const Icon(Icons.history, size: 18, color: StitchColors.onSurfaceVariant), onPressed: _clearSignature),
                          ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_hasSignature || _refusedToSign)
                            ? () => context.push(_refusedToSign ? '/police/refusal' : '/police/confirmation')
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StitchColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('GÉNÉRER LE PV', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(width: 8),
                            const Icon(Icons.assignment_turned_in, size: 18),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 12),
                    Text(
                      "En validant, un certificat numérique infalsifiable sera généré et transmis au centre de traitement national.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant),
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

  Widget _buildSummaryCard(InterpellationState s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StitchColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StitchColors.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RÉFÉRENCE PROVISOIRE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: StitchColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('#PV-${s.vehiclePlate.isNotEmpty ? s.vehiclePlate : "EN-COURS"}',
              style: GoogleFonts.courierPrime(fontSize: 16, fontWeight: FontWeight.bold, color: StitchColors.onSurface)),
          const SizedBox(height: 12),
          const Divider(color: StitchColors.outlineVariant),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Montant Total à Payer', style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant)),
                    Text('${_fmt(s.totalAmount)} FCFA', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: StitchColors.primary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: StitchColors.tertiaryFixed, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning, size: 13, color: StitchColors.onTertiaryFixed),
                    const SizedBox(width: 4),
                    Text('Délai 15j', style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onTertiaryFixed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _identityBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: StitchColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12), border: Border.all(color: StitchColors.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: StitchColors.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  _SignaturePainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF002109)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset> stroke) {
      if (stroke.length < 2) return;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }

    for (final stroke in strokes) {
      drawStroke(stroke);
    }
    drawStroke(currentStroke);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
