import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/stitch_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;

  late UserRole _userRole;
  late String _roleTitle;
  late IconData _roleIcon;
  late Color _roleColor;

  @override
  void initState() {
    super.initState();
    _userRole = switch (widget.role) {
      'police' => UserRole.police,
      'citizen' => UserRole.citizen,
      'admin' => UserRole.admin,
      _ => UserRole.citizen,
    };
    _roleTitle = switch (_userRole) {
      UserRole.police => 'Agent de Police',
      UserRole.citizen => 'Citoyen',
      UserRole.admin => 'Administrateur',
      UserRole.none => '',
    };
    _roleIcon = switch (_userRole) {
      UserRole.police => Icons.badge,
      UserRole.citizen => Icons.person,
      UserRole.admin => Icons.settings,
      UserRole.none => Icons.person,
    };
    _roleColor = switch (_userRole) {
      UserRole.police => StitchColors.primary,
      UserRole.citizen => StitchColors.secondary,
      UserRole.admin => StitchColors.tertiary,
      UserRole.none => StitchColors.primary,
    };
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _pinController.text.isEmpty) {
      _showSnack('Renseignez votre email et votre code PIN');
      return;
    }
    setState(() => _isLoading = true);
    final result = await ref.read(authProvider.notifier).login(
          role: _userRole,
          email: _emailController.text.trim(),
          pin: _pinController.text.trim(),
        );
    setState(() => _isLoading = false);

    if (result.requires2fa && mounted) {
      context.push(
        '/2fa',
        extra: {
          'challengeToken': result.challengeToken,
          'channel': result.channel,
          'roleTitle': _roleTitle,
        },
      );
      return;
    }

    if (!result.success && mounted) {
      _showSnack(ref.read(authProvider).error ?? 'Erreur de connexion');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: StitchColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StitchColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: StitchColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: StitchColors.outlineVariant),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: StitchColors.onSurface),
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 40),

              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(_roleIcon, color: _roleColor, size: 30),
              ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.7, 0.7), delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              Text('Connexion', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: StitchColors.onSurface))
                  .animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

              const SizedBox(height: 8),

              Text('Portail $_roleTitle', style: GoogleFonts.inter(fontSize: 16, color: StitchColors.onSurfaceVariant))
                  .animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 40),

              _buildLabel('Email'),
              const SizedBox(height: 8),
              _buildField(
                controller: _emailController,
                hint: 'agent1@pnc.cg',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 20),

              _buildLabel('Mot de passe'),
              const SizedBox(height: 8),
              _buildField(
                controller: _pinController,
                hint: 'Votre mot de passe',
                icon: Icons.lock_outline_rounded,
                obscureText: !_passwordVisible,
                onSubmitted: (_) => _login(),
                suffix: GestureDetector(
                  onTap: () => setState(() => _passwordVisible = !_passwordVisible),
                  child: Icon(_passwordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: StitchColors.onSurfaceVariant, size: 20),
                ),
              ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.3),

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: StitchColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: StitchColors.primary.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.info_outline_rounded, size: 13, color: StitchColors.primary),
                      const SizedBox(width: 6),
                      Text('Comptes de démonstration',
                          style: GoogleFonts.inter(fontSize: 11, color: StitchColors.primary, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 4),
                    Text('Police  →  agent1@pnc.cg', style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant)),
                    Text('Citoyen →  citoyen1@pnc.cg', style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant)),
                    Text('Admin   →  admin@pnc.cg', style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant)),
                    Text('Mot de passe démo : Admin@1234!',
                        style: GoogleFonts.inter(fontSize: 11, color: StitchColors.primary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StitchColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Se connecter', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(width: 8),
                            const Icon(Icons.login_rounded, size: 18),
                          ],
                        ),
                ),
              ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.3),

              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: Text('Mot de passe oublié ?', style: GoogleFonts.inter(color: StitchColors.onSurfaceVariant, fontSize: 13)),
                ),
              ).animate().fadeIn(delay: 600.ms),

              if (_userRole == UserRole.citizen) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/register'),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(fontSize: 13),
                        children: [
                          TextSpan(text: 'Pas encore de compte ? ', style: TextStyle(color: StitchColors.onSurfaceVariant)),
                          TextSpan(
                            text: 'Créer un compte',
                            style: TextStyle(color: StitchColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],

              const SizedBox(height: 40),

              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 14, color: StitchColors.primary),
                    const SizedBox(width: 6),
                    Text('Connexion sécurisée — DGST Congo', style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant)),
                  ],
                ),
              ).animate().fadeIn(delay: 700.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: StitchColors.onSurfaceVariant));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autocorrect: false,
      style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurface),
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: StitchColors.surface,
        prefixIcon: Icon(icon, color: StitchColors.primary, size: 20),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: StitchColors.outlineVariant)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: StitchColors.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: StitchColors.primary, width: 2)),
      ),
    );
  }
}
