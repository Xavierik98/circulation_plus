import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/stitch_colors.dart';
import '../providers/auth_provider.dart';

/// Étape 2 de connexion — code à 6 chiffres obligatoire pour POLICE/ADMIN,
/// envoyé par email (+ SMS si numéro renseigné). Design Stitch "Vérification 2FA".
class TwoFactorScreen extends ConsumerStatefulWidget {
  final String challengeToken;
  final String channel; // 'email' | 'email+sms'
  final String roleTitle;

  const TwoFactorScreen({
    super.key,
    required this.challengeToken,
    required this.channel,
    required this.roleTitle,
  });

  @override
  ConsumerState<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends ConsumerState<TwoFactorScreen> {
  final List<TextEditingController> _boxCtrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _boxFocus = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 0;

  @override
  void dispose() {
    for (final c in _boxCtrls) {
      c.dispose();
    }
    for (final f in _boxFocus) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _boxCtrls.map((c) => c.text).join();

  void _onBoxChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _boxFocus[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _boxFocus[index - 1].requestFocus();
    }
    if (_code.length == 6) _verify();
  }

  Future<void> _verify() async {
    final code = _code;
    if (code.length != 6) {
      _showSnack('Saisissez les 6 chiffres du code');
      return;
    }
    setState(() => _isLoading = true);
    final success = await ref.read(authProvider.notifier).verify2fa(widget.challengeToken, code);
    setState(() => _isLoading = false);

    if (!success && mounted) {
      _showSnack(ref.read(authProvider).error ?? 'Code invalide');
    }
    // Succès : le redirect global de GoRouter (basé sur authProvider.role)
    // bascule automatiquement vers le bon dashboard.
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0 || _isResending) return;
    setState(() => _isResending = true);
    final ok = await ref.read(authProvider.notifier).resend2fa(widget.challengeToken);
    setState(() => _isResending = false);
    if (!mounted) return;
    _showSnack(ok ? 'Nouveau code envoyé' : 'Échec de l\'envoi, réessayez');
    if (ok) _startCooldown();
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 30);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: StitchColors.tertiary));
  }

  String get _channelLabel =>
      widget.channel == 'email+sms' ? 'votre email et votre numéro de téléphone' : 'votre email';

  @override
  Widget build(BuildContext context) {
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
                  IconButton(icon: const Icon(Icons.arrow_back, size: 20), onPressed: () => context.pop()),
                  const SizedBox(width: 4),
                  const Icon(Icons.security, color: StitchColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Circulation+',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: StitchColors.primary)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(color: StitchColors.primaryContainer, shape: BoxShape.circle),
                        child: const Icon(Icons.verified_user, color: Colors.white, size: 40),
                      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.7, 0.7)),
                      const SizedBox(height: 20),
                      Text('Vérification de sécurité',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: StitchColors.onSurface))
                          .animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 8),
                      Text(
                        'Un code à 6 chiffres a été envoyé à $_channelLabel pour confirmer la connexion ${widget.roleTitle}.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurfaceVariant),
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (i) => _otpBox(i)),
                      ).animate().fadeIn(delay: 250.ms),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: StitchColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Vérifier', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.check_circle, size: 18),
                                  ],
                                ),
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _resendCooldown > 0 ? null : _resend,
                        child: _isResending
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.refresh, size: 16, color: StitchColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    _resendCooldown > 0 ? 'Renvoyer le code (${_resendCooldown}s)' : 'Renvoyer le code',
                                    style: GoogleFonts.inter(color: StitchColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                      ).animate().fadeIn(delay: 350.ms),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: StitchColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: StitchColors.outlineVariant),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info, color: StitchColors.secondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Besoin d'aide ?",
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: StitchColors.onSurface)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Si vous ne recevez pas de code, vérifiez vos courriers indésirables ou contactez le support technique de la DGPN.',
                                    style: GoogleFonts.inter(fontSize: 13, color: StitchColors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms),

                      const SizedBox(height: 40),
                      Text('GOUVERNEMENT DE LA RÉPUBLIQUE DU CONGO',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1, color: StitchColors.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('Portail de Sécurité Officiel • 2026',
                          style: GoogleFonts.inter(fontSize: 11, color: StitchColors.outline)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _otpBox(int i) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: _boxCtrls[i],
        focusNode: _boxFocus[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        autofocus: i == 0,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: StitchColors.onSurface),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: StitchColors.outline)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: StitchColors.outline)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: StitchColors.primary, width: 2)),
        ),
        onChanged: (v) => _onBoxChanged(i, v),
      ),
    );
  }
}
