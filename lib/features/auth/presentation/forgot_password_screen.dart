import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/stitch_colors.dart';
import '../../../data/api_client.dart';
import '../../../core/utils/congo_phone.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool _loading  = false;
  bool _sent     = false;
  bool _usePhone = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final identifier = _usePhone
        ? _phoneCtrl.text.trim()
        : _emailCtrl.text.trim().toLowerCase();
    try {
      await ApiClient.instance.post(
        '/api/auth/forgot-password',
        body: {'identifier': identifier},
      );
    } catch (_) {
      // Anti-enumeration : afficher succès même en erreur réseau
    } finally {
      if (mounted) setState(() { _sent = true; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StitchColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // TopAppBar
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: const BoxDecoration(
                color: StitchColors.surface,
                border: Border(bottom: BorderSide(color: StitchColors.outlineVariant)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: StitchColors.onSurface, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  Text('RÉCUPÉRATION',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: StitchColors.onSurface)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _sent ? _buildSuccess() : _buildForm(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: StitchColors.primaryContainer, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.security, color: Colors.white, size: 40),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 20),
          Text('Mot de passe oublié ?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: StitchColors.onSurface))
              .animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 8),
          Text(
            'Veuillez choisir une méthode pour réinitialiser votre accès sécurisé au portail Circulation+.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurfaceVariant),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 24),

          // Toggle email / téléphone
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: StitchColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: StitchColors.outlineVariant),
            ),
            child: Row(children: [
              _ModeTab(label: 'PAR EMAIL', icon: Icons.mail_outline, selected: !_usePhone, onTap: () => setState(() => _usePhone = false)),
              _ModeTab(label: 'PAR SMS', icon: Icons.smartphone, selected: _usePhone, onTap: () => setState(() => _usePhone = true)),
            ]),
          ).animate().fadeIn(delay: 180.ms),
          const SizedBox(height: 24),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _usePhone
                ? Column(
                    key: const ValueKey('phone'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('NUMÉRO DE TÉLÉPHONE ENREGISTRÉ'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: CongoPhone.inputFormatters,
                        autofocus: true,
                        style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurface),
                        validator: CongoPhone.validator(),
                        decoration: _fieldDecoration(hint: '+242 06 000 0000', icon: Icons.phone_android),
                      ),
                      const SizedBox(height: 8),
                      Text('Un code de vérification à 6 chiffres sera envoyé par SMS.',
                          style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant)),
                    ],
                  )
                : Column(
                    key: const ValueKey('email'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('ADRESSE EMAIL OFFICIELLE'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autofocus: true,
                        style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurface),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email requis';
                          if (!v.contains('@')) return 'Email invalide';
                          return null;
                        },
                        decoration: _fieldDecoration(hint: 'votre@email.com', icon: Icons.alternate_email),
                      ),
                      const SizedBox(height: 8),
                      Text('Un lien de réinitialisation sera envoyé à votre adresse.',
                          style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant)),
                    ],
                  ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: StitchColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_usePhone ? 'Envoyer le code par SMS' : 'Envoyer le lien de réinitialisation',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
            ),
          ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 24),
          Text('Vous avez encore des problèmes ?', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: StitchColors.onSurfaceVariant)),
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Retour à la connexion', style: GoogleFonts.inter(color: StitchColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    final identifier = _usePhone ? _phoneCtrl.text.trim() : _emailCtrl.text.trim();
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: const BoxDecoration(color: StitchColors.primaryContainer, shape: BoxShape.circle),
          child: const Icon(Icons.check_circle, color: Colors.white, size: 40),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.7, 0.7)),
        const SizedBox(height: 24),
        Text('Demande envoyée !', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: StitchColors.onSurface))
            .animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 12),
        Text(
          'Si un compte est associé à\n$identifier\nun lien de réinitialisation a été envoyé.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurfaceVariant),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 8),
        Text('Ce lien expire dans 1 heure.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: StitchColors.tertiary))
            .animate().fadeIn(delay: 350.ms),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => context.go('/role'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: StitchColors.primary, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('RETOUR À LA CONNEXION', style: GoogleFonts.inter(color: StitchColors.primary, fontWeight: FontWeight.w700)),
          ),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: StitchColors.onSurfaceVariant),
      );

  InputDecoration _fieldDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: StitchColors.surface,
      suffixIcon: Icon(icon, color: StitchColors.onSurfaceVariant, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: StitchColors.outline)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: StitchColors.outline)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: StitchColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: StitchColors.error)),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeTab({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 3)] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? StitchColors.primary : StitchColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? StitchColors.primary : StitchColors.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
