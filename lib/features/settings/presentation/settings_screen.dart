import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../../../shared/widgets/pnc_badge.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        title: Text('Paramètres', style: AppTextStyles.titleMedium),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),

          // Profile card
          _buildProfileCard(auth),

          const SizedBox(height: 24),

          // Language section
          _buildSection(
            title: 'Langue',
            icon: Icons.language_rounded,
            iconColor: AppColors.primary,
            children: [
              _LanguageOption(
                label: 'Français',
                subtitle: 'Langue principale',
                flag: '🇨🇬',
                isSelected: settings.locale.languageCode == 'fr',
                onTap: () => ref.read(settingsProvider.notifier).setLocale(const Locale('fr')),
              ),
              const Divider(height: 1, color: AppColors.divider, indent: 16),
              _LanguageOption(
                label: 'English',
                subtitle: 'Secondary language',
                flag: '🇬🇧',
                isSelected: settings.locale.languageCode == 'en',
                onTap: () => ref.read(settingsProvider.notifier).setLocale(const Locale('en')),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Appearance section
          _buildSection(
            title: 'Apparence',
            icon: Icons.palette_outlined,
            iconColor: AppColors.accent,
            children: [
              _ToggleRow(
                label: 'Mode sombre',
                subtitle: 'Interface optimisée pour la nuit',
                icon: Icons.dark_mode_outlined,
                value: settings.isDarkMode,
                onChanged: (_) => ref.read(settingsProvider.notifier).toggleDarkMode(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Notifications section
          _buildSection(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            iconColor: AppColors.warning,
            children: [
              _ToggleRow(
                label: 'Alertes amendes',
                subtitle: 'Nouvelles amendes et rappels',
                icon: Icons.gavel_rounded,
                value: true,
                onChanged: (_) {},
              ),
              const Divider(height: 1, color: AppColors.divider, indent: 16),
              _ToggleRow(
                label: 'Paiements',
                subtitle: 'Confirmation de paiements',
                icon: Icons.payment_rounded,
                value: true,
                onChanged: (_) {},
              ),
              const Divider(height: 1, color: AppColors.divider, indent: 16),
              _ToggleRow(
                label: 'Alertes système',
                subtitle: 'Mises à jour et maintenance',
                icon: Icons.system_update_outlined,
                value: false,
                onChanged: (_) {},
              ),
            ],
          ),

          const SizedBox(height: 16),

          // About section
          _buildSection(
            title: 'À propos',
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.textTertiary,
            children: [
              const _InfoRow(label: 'Application', value: AppConstants.appName),
              const Divider(height: 1, color: AppColors.divider, indent: 16),
              const _InfoRow(label: 'Version', value: '${AppConstants.appVersion} (${AppConstants.appBuild})'),
              const Divider(height: 1, color: AppColors.divider, indent: 16),
              const _InfoRow(label: 'Opérateur', value: AppConstants.dgst),
              const Divider(height: 1, color: AppColors.divider, indent: 16),
              const _InfoRow(label: 'Pays', value: AppConstants.country),
            ],
          ),

          const SizedBox(height: 16),

          // Security
          _buildSection(
            title: 'Sécurité',
            icon: Icons.security_rounded,
            iconColor: AppColors.success,
            children: [
              _ActionRow(
                label: 'Politique de confidentialité',
                icon: Icons.privacy_tip_outlined,
                onTap: () => _showPrivacyPolicy(context),
              ),
              const Divider(height: 1, color: AppColors.divider, indent: 16),
              _ActionRow(
                label: 'Conditions d\'utilisation',
                icon: Icons.article_outlined,
                onTap: () => _showTermsOfUse(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Logout
          GestureDetector(
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/role');
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, size: 18, color: AppColors.error),
                  const SizedBox(width: 10),
                  Text('Se déconnecter',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.error)),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Column(
              children: [
                const PncBadge(size: 44, showGlow: false),
                const SizedBox(height: 8),
                Text(AppConstants.appName,
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.gold)),
                Text(AppConstants.country, style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text('© 2024 DGST — Tous droits réservés',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textDisabled)),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileCard(AuthState auth) {
    final roleLabel = switch (auth.role) {
      UserRole.police => 'Agent de Police',
      UserRole.citizen => 'Citoyen',
      UserRole.admin => 'Administrateur',
      UserRole.none => '',
    };
    final roleColor = switch (auth.role) {
      UserRole.police => AppColors.primary,
      UserRole.citizen => AppColors.success,
      UserRole.admin => AppColors.info,
      UserRole.none => AppColors.textTertiary,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: roleColor.withValues(alpha: 0.3)),
            ),
            child: Icon(
              switch (auth.role) {
                UserRole.police => Icons.local_police_rounded,
                UserRole.citizen => Icons.person_rounded,
                UserRole.admin => Icons.admin_panel_settings_rounded,
                UserRole.none => Icons.person_outline_rounded,
              },
              color: roleColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.userName ?? 'Utilisateur', style: AppTextStyles.titleSmall),
                Text(auth.userId ?? '', style: AppTextStyles.mono.copyWith(fontSize: 11, color: AppColors.textTertiary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(roleLabel, style: AppTextStyles.caption.copyWith(color: roleColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  void _showPrivacyPolicy(BuildContext context) {
    _showLegalSheet(
      context,
      title: 'Politique de confidentialité',
      sections: const [
        _LegalSection(
          heading: 'Données collectées',
          body:
              'Nous collectons votre nom, adresse email, numéro de téléphone '
              'et votre localisation lors de la constatation d\'infractions routières.',
        ),
        _LegalSection(
          heading: 'Utilisation des données',
          body:
              'Vos données sont utilisées pour la gestion des contraventions '
              'routières et la communication officielle avec la Police Nationale '
              'Congolaise (PNC).',
        ),
        _LegalSection(
          heading: 'Partage des données',
          body:
              'Vos informations sont partagées uniquement avec les autorités '
              'judiciaires congolaises compétentes, dans le cadre strict des '
              'procédures légales en vigueur.',
        ),
        _LegalSection(
          heading: 'Durée de conservation',
          body:
              'Vos données sont conservées pendant 5 ans, conformément au '
              'Code de la route de la République du Congo.',
        ),
        _LegalSection(
          heading: 'Vos droits',
          body:
              'Vous disposez d\'un droit d\'accès, de rectification et de '
              'suppression de vos données personnelles, exerceable directement '
              'depuis l\'application.',
        ),
        _LegalSection(
          heading: 'Contact',
          body: 'Pour toute demande relative à vos données : dgst@pnc.cg',
        ),
      ],
    );
  }

  void _showTermsOfUse(BuildContext context) {
    _showLegalSheet(
      context,
      title: 'Conditions d\'utilisation',
      sections: const [
        _LegalSection(
          heading: 'Accès à l\'application',
          body:
              'L\'application Circulation+ est réservée aux citoyens et agents '
              'de la République du Congo. Toute utilisation en dehors de ce '
              'cadre est interdite.',
        ),
        _LegalSection(
          heading: 'Exactitude des informations',
          body:
              'Les informations fournies lors de votre inscription et au cours '
              'de l\'utilisation de l\'application doivent être exactes et '
              'à jour.',
        ),
        _LegalSection(
          heading: 'Usage frauduleux',
          body:
              'Toute utilisation frauduleuse de l\'application, notamment la '
              'falsification d\'informations ou l\'usurpation d\'identité, '
              'est passible de sanctions pénales conformément à la législation '
              'congolaise.',
        ),
        _LegalSection(
          heading: 'Suspension de compte',
          body:
              'La Police Nationale Congolaise se réserve le droit de suspendre '
              'ou de supprimer tout compte en cas de manquement aux présentes '
              'conditions d\'utilisation.',
        ),
        _LegalSection(
          heading: 'Droit applicable',
          body:
              'Les présentes conditions sont régies par le droit congolais. '
              'Tout litige relève de la compétence exclusive du Tribunal de '
              'Brazzaville.',
        ),
      ],
    );
  }

  void _showLegalSheet(
    BuildContext context, {
    required String title,
    required List<_LegalSection> sections,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textDisabled,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(title, style: AppTextStyles.titleMedium),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      for (final s in sections) ...[
                        Text(s.heading,
                            style: AppTextStyles.titleSmall
                                .copyWith(color: AppColors.primary)),
                        const SizedBox(height: 6),
                        Text(s.body,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary, height: 1.6)),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Text(title.toUpperCase(),
                  style: AppTextStyles.overline.copyWith(color: iconColor, letterSpacing: 2)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(children: children),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.subtitle,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.textTertiary),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection {
  final String heading;
  final String body;
  const _LegalSection({required this.heading, required this.body});
}

class _ActionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionRow({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textTertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
