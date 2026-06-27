import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/date_input_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../data/api_client.dart';
import '../../../core/utils/congo_phone.dart';
import '../../auth/providers/auth_provider.dart';

class CitizenProfileScreen extends ConsumerStatefulWidget {
  const CitizenProfileScreen({super.key});

  @override
  ConsumerState<CitizenProfileScreen> createState() =>
      _CitizenProfileScreenState();
}

class _CitizenProfileScreenState extends ConsumerState<CitizenProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  final TextEditingController _licenseCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  DateTime? _birthDate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _nameCtrl = TextEditingController(text: auth.userName ?? '');
    _phoneCtrl = TextEditingController(text: auth.telephone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      final body = <String, dynamic>{};
      final auth = ref.read(authProvider);
      if (_nameCtrl.text.trim() != (auth.userName ?? '')) {
        body['name'] = _nameCtrl.text.trim();
      }
      if (_phoneCtrl.text.trim() != (auth.telephone ?? '')) {
        body['telephone'] = _phoneCtrl.text.trim();
      }

      if (body.isNotEmpty) {
        await ApiClient.instance.patch('/api/auth/profile', body: body);
        // Rafraîchir l'état local (nom, téléphone) depuis /me
        await ref.read(authProvider.notifier).checkEmailVerified();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour du profil.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        title: Text('Mon profil', style: AppTextStyles.titleMedium),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration:
                const BoxDecoration(gradient: AppColors.congoFlagGradient),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 16),
            // ── Avatar éditable ──────────────────────────────────
            Center(
              child: Column(
                children: [
                  UserAvatar(
                    size: 88,
                    editable: true,
                    photoUrl: auth.photoUrl,
                    initials: auth.initials,
                  ),
                  const SizedBox(height: 8),
                  Text('Appuyez pour changer la photo',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Informations personnelles',
                style: AppTextStyles.titleSmall
                    .copyWith(color: AppColors.textTertiary)),
            const SizedBox(height: 16),

            // Nom complet
            _buildField(
              controller: _nameCtrl,
              label: 'Nom complet',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Le nom est requis' : null,
            ),
            const SizedBox(height: 14),

            // Téléphone
            _buildField(
              controller: _phoneCtrl,
              label: 'Téléphone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              hint: '+242 06 000 0000',
              inputFormatters: CongoPhone.inputFormatters,
              validator: CongoPhone.validator(required: false),
            ),
            const SizedBox(height: 14),

            // Numéro de permis
            _buildField(
              controller: _licenseCtrl,
              label: 'Numéro de permis (facultatif)',
              icon: Icons.credit_card_rounded,
            ),
            const SizedBox(height: 14),

            // Date de naissance
            DateInputField(
              initialValue: _birthDate,
              firstDate: DateTime(1930),
              lastDate: DateTime(DateTime.now().year - 16),
              label: 'Date de naissance (facultatif)',
              helpText: 'Date de naissance',
              onChanged: (d) => setState(() => _birthDate = d),
            ),
            const SizedBox(height: 14),

            // Adresse
            _buildField(
              controller: _addressCtrl,
              label: 'Adresse (facultatif)',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Bouton Enregistrer
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Enregistrer',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      inputFormatters: inputFormatters,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textTertiary),
        labelStyle: AppTextStyles.bodySmall,
        hintStyle:
            AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
