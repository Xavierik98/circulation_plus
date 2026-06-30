import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/stitch_colors.dart';
import '../../../shared/widgets/password_strength_indicator.dart';
import '../../../core/utils/congo_phone.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController       = TextEditingController();
  final _emailController      = TextEditingController();
  final _phoneController      = TextEditingController();
  final _pinController        = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isLoading  = false;
  bool _pinVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_pinController.text != _confirmPinController.text) {
      _showSnack('Les mots de passe ne correspondent pas');
      return;
    }

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final fullName = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final verificationUrl = await ref.read(authProvider.notifier).register(
      name:      fullName,
      email:     email,
      telephone: phone.isEmpty ? null : phone,
      pin:       _pinController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (verificationUrl == null) {
      _showSnack(ref.read(authProvider).error ?? 'Erreur lors de l\'inscription');
    } else if (ref.read(authProvider).emailVerified) {
      context.go('/citizen');
    } else {
      context.go('/verify-email', extra: {'email': email, 'devUrl': verificationUrl});
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: StitchColors.error));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StitchColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: StitchColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: StitchColors.outlineVariant),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: StitchColors.onSurface),
                      ),
                    ),
                  ],
                ).animate().fadeIn(),

                const SizedBox(height: 24),

                Transform.rotate(
                  angle: 0.05,
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: StitchColors.primary, borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 6))]),
                    child: const Icon(Icons.security, color: Colors.white, size: 32),
                  ),
                ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.7, 0.7)),

                const SizedBox(height: 16),

                Text('Circulation+', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: StitchColors.primary))
                    .animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 4),
                Text(
                  'Portail Citoyen Officiel de la République du Congo. Sécurité, Transparence, Modernité.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: StitchColors.onSurfaceVariant),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 28),

                // Carte d'inscription
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: StitchColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: StitchColors.outlineVariant),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(left: 12),
                        decoration: const BoxDecoration(border: Border(left: BorderSide(color: StitchColors.primary, width: 4))),
                        child: Text('Créer un compte', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: StitchColors.onSurface)),
                      ),
                      const SizedBox(height: 20),

                      _label('Nom complet'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurface),
                        decoration: _fieldDecoration(hint: 'Ex: Jean Mukoko', icon: Icons.person_outline),
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Nom requis' : null,
                      ).animate().fadeIn(delay: 250.ms),
                      const SizedBox(height: 16),

                      _label('Adresse Email'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurface),
                        decoration: _fieldDecoration(hint: 'nom@exemple.cg', icon: Icons.mail_outline),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email requis';
                          if (!v.contains('@') || !v.contains('.')) return 'Format email invalide';
                          return null;
                        },
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 16),

                      _label('Numéro de téléphone'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: StitchColors.surfaceContainerHigh,
                              border: Border.all(color: StitchColors.outlineVariant),
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                            ),
                            alignment: Alignment.center,
                            child: Text('+242', style: GoogleFonts.inter(color: StitchColors.onSurfaceVariant)),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: CongoPhone.inputFormatters,
                              style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurface),
                              decoration: InputDecoration(
                                hintText: '06 000 0000 (optionnel)',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                enabledBorder: OutlineInputBorder(borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)), borderSide: const BorderSide(color: StitchColors.outlineVariant)),
                                border: OutlineInputBorder(borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)), borderSide: const BorderSide(color: StitchColors.outlineVariant)),
                                focusedBorder: OutlineInputBorder(borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)), borderSide: const BorderSide(color: StitchColors.primary, width: 2)),
                              ),
                              validator: CongoPhone.validator(required: false),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 350.ms),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Mot de passe'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _pinController,
                                  obscureText: !_pinVisible,
                                  onChanged: (_) => setState(() {}),
                                  style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurface),
                                  decoration: _fieldDecoration(
                                    hint: '••••••••',
                                    icon: Icons.lock_outline,
                                    suffix: GestureDetector(
                                      onTap: () => setState(() => _pinVisible = !_pinVisible),
                                      child: Icon(_pinVisible ? Icons.visibility_off : Icons.visibility, size: 18, color: StitchColors.onSurfaceVariant),
                                    ),
                                  ),
                                  validator: const PasswordPolicy().validate,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Confirmation'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _confirmPinController,
                                  obscureText: !_pinVisible,
                                  style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurface),
                                  decoration: _fieldDecoration(hint: '••••••••', icon: Icons.verified_user_outlined),
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _register(),
                                  validator: (v) => (v != _pinController.text) ? 'Ne correspond pas' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms),

                      PasswordStrengthIndicator(password: _pinController.text),

                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
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
                                    Text("S'inscrire", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                        ),
                      ).animate().fadeIn(delay: 450.ms),

                      const SizedBox(height: 20),
                      const Divider(color: StitchColors.outlineVariant),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => context.pop(),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(fontSize: 13),
                              children: [
                                TextSpan(text: 'Déjà un compte ? ', style: TextStyle(color: StitchColors.onSurfaceVariant)),
                                TextSpan(text: 'Se connecter', style: TextStyle(color: StitchColors.primary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(child: _InfoBox(icon: Icons.shield, color: StitchColors.primary, title: 'Données sécurisées', body: 'Cryptage AES-256 conforme DGPN.')),
                    const SizedBox(width: 12),
                    Expanded(child: _InfoBox(icon: Icons.gavel, color: StitchColors.secondary, title: 'Usage Officiel', body: 'Accès réglementé par la loi congolaise.')),
                  ],
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Container(height: 6, color: StitchColors.congoGreen)),
                    Expanded(child: Container(height: 6, color: StitchColors.congoYellow)),
                    Expanded(child: Container(height: 6, color: StitchColors.congoRed)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: StitchColors.onSurfaceVariant));

  InputDecoration _fieldDecoration({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: StitchColors.outline),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: StitchColors.outlineVariant)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: StitchColors.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: StitchColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: StitchColors.error)),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _InfoBox({required this.icon, required this.color, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: StitchColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: StitchColors.onSurface)),
                Text(body, style: GoogleFonts.inter(fontSize: 10, color: StitchColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
