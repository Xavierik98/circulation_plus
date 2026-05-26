import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/password_strength_indicator.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController  = TextEditingController();
  final _lastNameController   = TextEditingController();
  final _emailController      = TextEditingController();
  final _phoneController      = TextEditingController();
  final _pinController        = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isLoading  = false;
  bool _pinVisible = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
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
    final firstName = _firstNameController.text.trim();
    final lastName  = _lastNameController.text.trim();
    final fullName  = '$firstName $lastName'.trim();
    final verificationUrl = await ref.read(authProvider.notifier).register(
      name:      fullName,
      email:     email,
      telephone: _phoneController.text.trim(),
      pin:       _pinController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (verificationUrl == null) {
      // Erreur (null = exception dans le notifier)
      _showSnack(ref.read(authProvider).error ?? 'Erreur lors de l\'inscription');
    } else if (ref.read(authProvider).emailVerified) {
      // Mode développement : compte auto-vérifié → dashboard citoyen directement
      context.go('/citizen');
    } else {
      // Mode production : email de vérification requis
      context.go(
        '/verify-email',
        extra: {'email': email, 'devUrl': verificationUrl},
      );
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
          // Fond dégradé vert citoyen
          Positioned.fill(
            child: CustomPaint(painter: _RegisterBgPainter()),
          ),
          // Barre Congo
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Bouton retour
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: col.surfaceVar,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: col.cardBorder),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: col.textPrimary),
                      ),
                    ).animate().fadeIn(),

                    const SizedBox(height: 32),

                    // Icône
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.congoGreen, Color(0xFF059669)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.congoGreen.withValues(alpha: 0.35),
                            blurRadius: 20, offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 30),
                    ).animate().fadeIn(delay: 100.ms).scale(
                        begin: const Offset(0.7, 0.7),
                        delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),

                    const SizedBox(height: 24),

                    Text('Créer un compte',
                        style: AppTextStyles.displaySmall)
                        .animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),

                    const SizedBox(height: 6),

                    Text('Portail Citoyen — Circulation+',
                        style: AppTextStyles.bodyLarge
                            .copyWith(color: AppColors.textTertiary))
                        .animate().fadeIn(delay: 250.ms),

                    const SizedBox(height: 32),

                    // Prénom + Nom côte à côte
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Prénom *'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _firstNameController,
                                textCapitalization: TextCapitalization.words,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: 'Ex : Marie',
                                  prefixIcon: Icon(Icons.person_outline_rounded,
                                      color: AppColors.congoGreen, size: 20),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().length < 2)
                                        ? 'Requis'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Nom *'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _lastNameController,
                                textCapitalization: TextCapitalization.words,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: 'Ex : Samba',
                                  prefixIcon: Icon(Icons.badge_outlined,
                                      color: AppColors.congoGreen, size: 20),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().length < 2)
                                        ? 'Requis'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 18),

                    // Email
                    _label('Email'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'votre@email.com',
                        prefixIcon: Icon(Icons.alternate_email_rounded,
                            color: AppColors.congoGreen, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email requis';
                        if (!v.contains('@') || !v.contains('.')) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: 18),

                    // Téléphone
                    _label('Numéro de téléphone'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: '+242 06 000 0000',
                        prefixIcon: Icon(Icons.phone_rounded,
                            color: AppColors.congoGreen, size: 20),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().length < 8)
                              ? 'Numéro invalide'
                              : null,
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 18),

                    // Mot de passe
                    _label('Mot de passe'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pinController,
                      obscureText: !_pinVisible,
                      onChanged: (_) => setState(() {}),
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ex: MonMotDePasse1!',
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: AppColors.congoGreen, size: 20),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _pinVisible = !_pinVisible),
                          child: Icon(
                            _pinVisible
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.textTertiary, size: 20,
                          ),
                        ),
                      ),
                      validator: const PasswordPolicy().validate,
                    ).animate().fadeIn(delay: 450.ms),

                    // Indicateur de force
                    PasswordStrengthIndicator(password: _pinController.text)  // ignore: prefer_const_constructors
                        .animate().fadeIn(delay: 460.ms),

                    const SizedBox(height: 18),

                    // Confirmer mot de passe
                    _label('Confirmer le mot de passe'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPinController,
                      obscureText: !_pinVisible,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Répétez votre mot de passe',
                        prefixIcon: Icon(Icons.lock_rounded,
                            color: AppColors.congoGreen, size: 20),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _register(),
                      validator: (v) {
                        if (v != _pinController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 8),

                    // Note sécurité
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.congoGreen.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.congoGreen.withValues(alpha: 0.2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 13, color: AppColors.congoGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Compte citoyen uniquement. Les comptes police sont '
                            'créés par l\'administration PNC.',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textTertiary),
                          ),
                        ),
                      ]),
                    ).animate().fadeIn(delay: 520.ms),

                    const SizedBox(height: 28),

                    PremiumButton(
                      label: _isLoading ? 'Création en cours...' : 'Créer mon compte',
                      isLoading: _isLoading,
                      gradient: const LinearGradient(
                        colors: [AppColors.congoGreen, Color(0xFF059669)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      icon: Icons.person_add_rounded,
                      onPressed: _isLoading ? null : _register,
                    ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.3),

                    const SizedBox(height: 16),

                    // Déjà un compte ?
                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodySmall,
                            children: const [
                              TextSpan(
                                text: 'Déjà un compte ? ',
                                style: TextStyle(color: AppColors.textTertiary),
                              ),
                              TextSpan(
                                text: 'Se connecter',
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

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
  );
}

class _RegisterBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintTop = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.8, -0.8),
        radius: 0.9,
        colors: [
          AppColors.congoGreen.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintTop);

    final paintBottom = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, 1.0),
        radius: 0.7,
        colors: [
          AppColors.congoYellow.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintBottom);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
