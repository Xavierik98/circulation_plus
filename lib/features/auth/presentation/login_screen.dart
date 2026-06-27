import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/pnc_badge.dart';
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
  late Gradient _roleGradient;

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
      UserRole.police => Icons.local_police_rounded,
      UserRole.citizen => Icons.person_rounded,
      UserRole.admin => Icons.admin_panel_settings_rounded,
      UserRole.none => Icons.person_rounded,
    };
    _roleGradient = switch (_userRole) {
      UserRole.police => AppColors.primaryGradient,
      UserRole.citizen => const LinearGradient(
          colors: [AppColors.success, Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      UserRole.admin => const LinearGradient(
          colors: [AppColors.info, Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      UserRole.none => AppColors.primaryGradient,
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

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isSuccess ? AppColors.success : AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Scaffold(
      backgroundColor: col.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _LoginBgPainter(_userRole, Theme.of(context).brightness),
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(height: 3, decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient)),
          ),
          SafeArea(
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
                        color: col.surfaceVar,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: col.cardBorder),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: col.textPrimary),
                    ),
                  ).animate().fadeIn(),

                  const SizedBox(height: 40),

                  if (_userRole == UserRole.police)
                    const PncBadge(size: 68, showGlow: true)
                        .animate()
                        .fadeIn(delay: 100.ms)
                        .scale(begin: const Offset(0.6, 0.6), delay: 100.ms, duration: 500.ms, curve: Curves.easeOutBack)
                  else
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: _roleGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(_roleIcon, color: Colors.white, size: 30),
                    ).animate().fadeIn(delay: 100.ms).scale(
                        begin: const Offset(0.7, 0.7),
                        delay: 100.ms,
                        duration: 400.ms,
                        curve: Curves.easeOutBack),

                  const SizedBox(height: 24),

                  Text(
                    'Connexion',
                    style: AppTextStyles.displaySmall,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

                  const SizedBox(height: 8),

                  Text(
                    'Portail $_roleTitle',
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textTertiary),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 40),

                  // Email
                  _buildLabel('Email'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'agent1@pnc.cg',
                      prefixIcon: Icon(
                        Icons.alternate_email_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 20),

                  // Mot de passe
                  _buildLabel('Mot de passe'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pinController,
                    obscureText: !_passwordVisible,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Votre mot de passe',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _passwordVisible = !_passwordVisible),
                        child: Icon(
                          _passwordVisible
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppColors.textTertiary, size: 20,
                        ),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                  ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.3),

                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('Comptes de démonstration',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 4),
                        Text('Police  →  agent1@pnc.cg',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                        Text('Citoyen →  citoyen1@pnc.cg',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                        Text('Admin   →  admin@pnc.cg',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                        Text('Mot de passe démo : Admin@1234!',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 32),

                  PremiumButton(
                    label: 'Se connecter',
                    isLoading: _isLoading,
                    gradient: _roleGradient,
                    icon: Icons.login_rounded,
                    onPressed: _isLoading ? null : _login,
                  ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.3),

                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),

                  // Inscription — citoyen uniquement
                  if (_userRole == UserRole.citizen) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => context.push('/register'),
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodySmall,
                            children: const [
                              TextSpan(
                                text: 'Pas encore de compte ? ',
                                style: TextStyle(color: AppColors.textTertiary),
                              ),
                              TextSpan(
                                text: 'Créer un compte',
                                style: TextStyle(
                                  color: AppColors.congoGreen,
                                  fontWeight: FontWeight.w600,
                                ),
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
                        const Icon(Icons.verified_user_outlined,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text(
                          'Connexion sécurisée — DGST Congo',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 700.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _LoginBgPainter extends CustomPainter {
  final UserRole role;
  final Brightness brightness;
  _LoginBgPainter(this.role, this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final glowColor = role == UserRole.police
        ? AppColors.gold.withValues(alpha: 0.08)
        : role == UserRole.citizen
            ? AppColors.congoGreen.withValues(alpha: 0.06)
            : AppColors.info.withValues(alpha: 0.06);

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [glowColor, Colors.transparent],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.85, size.height * 0.12),
        radius: size.width * 0.75,
      ));
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.12), size.width * 0.75, paint);

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.primary.withValues(alpha: 0.04), Colors.transparent],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.1, size.height * 0.85),
        radius: size.width * 0.5,
      ));
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.85), size.width * 0.5, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
