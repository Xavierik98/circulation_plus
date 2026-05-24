import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/department_model.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../shared/widgets/password_strength_indicator.dart';
import '../../../data/api_client.dart';
import '../../../data/repositories.dart';

class RegisterAgentScreen extends ConsumerStatefulWidget {
  const RegisterAgentScreen({super.key});

  @override
  ConsumerState<RegisterAgentScreen> createState() =>
      _RegisterAgentScreenState();
}

class _RegisterAgentScreenState extends ConsumerState<RegisterAgentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _badgeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  CongoDepartement? _department;
  // Grade PNC : clé = valeur enum backend, valeur = libellé affiché
  static const _gradeMap = <String, String>{
    'GARDIEN_DE_LA_PAIX_2CL':    'Gardien de la Paix 2ᵉ cl.',
    'GARDIEN_DE_LA_PAIX_1CL':    'Gardien de la Paix 1ʳᵉ cl.',
    'BRIGADIER':                  'Brigadier',
    'BRIGADIER_CHEF':             'Brigadier-Chef',
    'INSPECTEUR':                 'Inspecteur',
    'INSPECTEUR_PRINCIPAL':       'Inspecteur Principal',
    'COMMISSAIRE':                'Commissaire',
    'COMMISSAIRE_PRINCIPAL':      'Commissaire Principal',
    'COMMISSAIRE_DIVISIONNAIRE':  'Commissaire Divisionnaire',
    'DIRECTEUR_DEPARTEMENTAL':    'Directeur Départemental',
    'DIRECTEUR_CENTRAL':          'Directeur Central',
    'DIRECTEUR_GENERAL_ADJOINT':  'Directeur Général Adjoint',
    'DIRECTEUR_GENERAL':          'Directeur Général',
  };
  String _rank = 'GARDIEN_DE_LA_PAIX_2CL'; // enum value envoyé au backend
  bool _passVisible = false;
  bool _isLoading = false;
  String? _generatedPassword; // mot de passe auto-généré affiché à l'admin

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _badgeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// Génère un mot de passe fort aléatoire de 10 caractères
  /// Format : 2 majuscules + 2 minuscules + 2 chiffres + 1 spécial + 3 mixtes
  String _buildPassword() {
    const upper   = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower   = 'abcdefghjkmnpqrstuvwxyz';
    const digits  = '23456789';
    const special = '@!#\$&';
    final rand = Random.secure();

    final chars = <String>[
      upper[rand.nextInt(upper.length)],
      upper[rand.nextInt(upper.length)],
      lower[rand.nextInt(lower.length)],
      lower[rand.nextInt(lower.length)],
      digits[rand.nextInt(digits.length)],
      digits[rand.nextInt(digits.length)],
      special[rand.nextInt(special.length)],
      lower[rand.nextInt(lower.length)],
      upper[rand.nextInt(upper.length)],
      digits[rand.nextInt(digits.length)],
    ];
    chars.shuffle(rand);
    return chars.join();
  }

  void _autoGeneratePassword() {
    final pwd = _buildPassword();
    setState(() {
      _generatedPassword = pwd;
      _passCtrl.text = pwd;
      _confirmCtrl.text = pwd;
      _passVisible = true; // afficher en clair pour que l'admin puisse le noter
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_passCtrl.text != _confirmCtrl.text) {
      _snack('Les mots de passe ne correspondent pas');
      return;
    }
    if (_department == null) {
      _snack('Sélectionnez un département');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Appel API : création compte POLICE par admin
      final repo = AuthRepository();
      await repo.createAgent(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        telephone: _phoneCtrl.text.trim(),
        badge: _badgeCtrl.text.trim(),
        rank: _rank,
        department: _department!.name.toUpperCase(),
        password: _passCtrl.text.trim(),
      );
      if (mounted) {
        _snack('Agent créé avec succès', isSuccess: true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) context.pop();
      }
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (e) {
      // Mode démo offline : simuler la création
      if (mounted) {
        _snack('Mode hors-ligne : agent simulé. Reconnectez le backend.', isSuccess: true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) context.pop();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isSuccess ? AppColors.success : AppColors.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Fond dégradé bleu police
          Positioned.fill(child: CustomPaint(painter: _AgentBgPainter())),
          // Barre Congo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                  gradient: AppColors.congoFlagGradient),
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

                    // Retour
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: AppColors.textPrimary),
                      ),
                    ).animate().fadeIn(),

                    const SizedBox(height: 28),

                    // Icône PNC
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F1D3A), Color(0xFF1A2E50)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.5),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.shield_rounded,
                              color: AppColors.gold, size: 32),
                          Positioned(
                            bottom: 12,
                            child: Text(
                              'PNC',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.gold,
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms).scale(
                        begin: const Offset(0.7, 0.7),
                        delay: 100.ms,
                        duration: 400.ms,
                        curve: Curves.easeOutBack),

                    const SizedBox(height: 20),

                    Text('Créer un compte agent',
                            style: AppTextStyles.displaySmall)
                        .animate()
                        .fadeIn(delay: 150.ms)
                        .slideY(begin: 0.3),

                    const SizedBox(height: 4),

                    Text(
                      'Police Nationale du Congo — Administration',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.textTertiary),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 28),

                    // ── Identité ───────────────────────────────────────────
                    _sectionTitle('Identité de l\'agent'),
                    const SizedBox(height: 12),

                    _label('Nom complet'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Ex : Jean Mbemba',
                        prefixIcon: Icon(Icons.person_outline_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().length < 2)
                          ? 'Nom trop court'
                          : null,
                    ).animate().fadeIn(delay: 250.ms),

                    const SizedBox(height: 16),

                    // Rang + Matricule sur 2 colonnes
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Grade / Rang'),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _rank,
                                dropdownColor: AppColors.surface,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.military_tech_rounded,
                                      color: AppColors.gold, size: 20),
                                ),
                                items: _gradeMap.entries
                                    .map((e) => DropdownMenuItem(
                                        value: e.key,
                                        child: Text(e.value,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                    color: AppColors
                                                        .textPrimary))))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _rank = v ?? _rank),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Matricule / Badge'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _badgeCtrl,
                                textCapitalization:
                                    TextCapitalization.characters,
                                style: AppTextStyles.mono.copyWith(
                                    color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: 'PNC-2026-001',
                                  prefixIcon: Icon(Icons.badge_outlined,
                                      color: AppColors.gold, size: 20),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Requis'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 16),

                    // Département
                    _label('Département d\'affectation'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<CongoDepartement>(
                      initialValue: _department,
                      dropdownColor: AppColors.surface,
                      hint: Text('Sélectionnez...',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textTertiary)),
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_city_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      items: CongoDepartement.values
                          .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d.label,
                                  style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textPrimary))))
                          .toList(),
                      onChanged: (v) => setState(() => _department = v),
                      validator: (v) =>
                          v == null ? 'Sélectionnez un département' : null,
                    ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: 24),

                    // ── Contact ────────────────────────────────────────────
                    _sectionTitle('Coordonnées'),
                    const SizedBox(height: 12),

                    _label('Email institutionnel'),
                    const SizedBox(height: 4),
                    // Règle domaine visible
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 12, color: AppColors.gold),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Obligatoire : l\'email doit se terminer par @pnc.cg  —  Ex : jean.mbemba@pnc.cg',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.gold, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'prenom.nom@pnc.cg',
                        prefixIcon: Icon(Icons.alternate_email_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email requis';
                        if (!v.trim().toLowerCase().endsWith('@pnc.cg')) {
                          return 'L\'email doit se terminer par @pnc.cg';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 16),

                    _label('Téléphone de service'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: '+242 06 000 0000',
                        prefixIcon: Icon(Icons.phone_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().length < 8)
                              ? 'Numéro invalide'
                              : null,
                    ).animate().fadeIn(delay: 450.ms),

                    const SizedBox(height: 24),

                    // ── Sécurité ───────────────────────────────────────────
                    _sectionTitle('Accès & sécurité'),
                    const SizedBox(height: 12),

                    // Bouton génération automatique
                    GestureDetector(
                      onTap: _autoGeneratePassword,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.gold.withValues(alpha: 0.15),
                              AppColors.gold.withValues(alpha: 0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome_rounded,
                                size: 16, color: AppColors.gold),
                            const SizedBox(width: 8),
                            Text(
                              'Générer un mot de passe automatique',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 480.ms),

                    // Carte du mot de passe généré (visible après génération)
                    if (_generatedPassword != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1D0A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    size: 14, color: AppColors.success),
                                const SizedBox(width: 6),
                                Text(
                                  'Mot de passe généré',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _autoGeneratePassword,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.refresh_rounded,
                                          size: 13,
                                          color: AppColors.textTertiary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Régénérer',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.cardBorder),
                                    ),
                                    child: SelectableText(
                                      _generatedPassword!,
                                      style: AppTextStyles.mono.copyWith(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                        text: _generatedPassword!));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Mot de passe copié dans le presse-papier'),
                                      duration: Duration(seconds: 2),
                                    ));
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.success
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.success
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: const Icon(Icons.copy_rounded,
                                        size: 16, color: AppColors.success),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '⚠  Notez ce mot de passe — il ne sera plus affiché après création.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.gold.withValues(alpha: 0.8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),
                    ],

                    const SizedBox(height: 16),

                    _label('Mot de passe provisoire'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: !_passVisible,
                      onChanged: (_) => setState(() {}),
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Minimum 8 caractères',
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: AppColors.primary, size: 20),
                        suffixIcon: GestureDetector(
                          onTap: () =>
                              setState(() => _passVisible = !_passVisible),
                          child: Icon(
                            _passVisible
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.textTertiary,
                            size: 20,
                          ),
                        ),
                      ),
                      validator: const PasswordPolicy().validate,
                    ).animate().fadeIn(delay: 500.ms),

                    PasswordStrengthIndicator(password: _passCtrl.text)
                        .animate()
                        .fadeIn(delay: 510.ms),

                    const SizedBox(height: 14),

                    _label('Confirmer le mot de passe'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: !_passVisible,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Répétez le mot de passe',
                        prefixIcon: Icon(Icons.lock_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) => v != _passCtrl.text
                          ? 'Les mots de passe ne correspondent pas'
                          : null,
                    ).animate().fadeIn(delay: 550.ms),

                    const SizedBox(height: 8),

                    // Note
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'L\'agent devra changer son mot de passe à la première connexion. '
                              'Un email de bienvenue lui sera envoyé.',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textTertiary),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 570.ms),

                    const SizedBox(height: 28),

                    PremiumButton(
                      label: _isLoading
                          ? 'Création en cours...'
                          : 'Créer le compte agent',
                      isLoading: _isLoading,
                      icon: Icons.shield_rounded,
                      onPressed: _isLoading ? null : _submit,
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

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

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: AppTextStyles.titleSmall
                .copyWith(color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTextStyles.labelMedium
            .copyWith(color: AppColors.textSecondary),
      );
}

class _AgentBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, -0.6),
        radius: 0.8,
        colors: [
          AppColors.gold.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p1);

    final p2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.8, 1.0),
        radius: 0.7,
        colors: [
          AppColors.primary.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
