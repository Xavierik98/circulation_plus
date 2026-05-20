import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/officer_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../data/providers.dart';
import '../../../data/repositories.dart';

class OfficersManagementScreen extends ConsumerStatefulWidget {
  const OfficersManagementScreen({super.key});

  @override
  ConsumerState<OfficersManagementScreen> createState() =>
      _OfficersManagementScreenState();
}

class _OfficersManagementScreenState
    extends ConsumerState<OfficersManagementScreen> {
  OfficerStatus? _filterStatus;
  String _searchQuery = '';

  List<OfficerModel> _applyStatus(List<OfficerModel> officers) {
    if (_filterStatus == null) return officers;
    return officers.where((o) => o.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final officersAsync = ref.watch(officersProvider(_searchQuery));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Gestion des agents', style: AppTextStyles.titleMedium),
        actions: [
          IconButton(
            tooltip: 'Ajouter un agent',
            icon: const Icon(Icons.person_add_rounded, color: AppColors.primary),
            onPressed: () => _showAddOfficerDialog(context),
          ),
          IconButton(
            tooltip: 'Import CSV',
            icon: const Icon(Icons.upload_file_rounded, color: AppColors.primary),
            onPressed: () => _showCsvImportDialog(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient)),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterBar(),
          Expanded(
            child: officersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Agents indisponibles.\n$e',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium),
                ),
              ),
              data: (all) {
                final officers = _applyStatus(all);
                return Column(
                  children: [
                    _buildSummaryRow(all),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: officers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          return _OfficerCard(officer: officers[i])
                              .animate(delay: Duration(milliseconds: i * 60))
                              .fadeIn(duration: 300.ms)
                              .slideX(begin: 0.05);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogue : ajout manuel d'un agent ────────────────────────────────────
  void _showAddOfficerDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl  = TextEditingController();
    final emailCtrl = TextEditingController();
    final badgeCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pinCtrl   = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Nouvel agent', style: AppTextStyles.titleMedium),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogField(nameCtrl,  'Nom complet *',              Icons.person_rounded),
                    const SizedBox(height: 12),
                    _dialogField(emailCtrl, 'Email @pnc.cg *',            Icons.email_rounded,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (!v.toLowerCase().endsWith('@pnc.cg')) return 'Domaine @pnc.cg obligatoire';
                        return null;
                      }),
                    const SizedBox(height: 12),
                    _dialogField(badgeCtrl, 'Matricule (ex: PNC-2024-042)', Icons.badge_rounded),
                    const SizedBox(height: 12),
                    _dialogField(phoneCtrl, 'Téléphone',                   Icons.phone_rounded),
                    const SizedBox(height: 12),
                    _dialogField(pinCtrl,   'Mot de passe temporaire *',   Icons.lock_rounded,
                      obscure: true,
                      validator: (v) {
                        if (v == null || v.length < 10) return 'Min. 10 caractères';
                        if (!v.contains(RegExp(r'[A-Z]'))) return 'Majuscule requise';
                        if (!v.contains(RegExp(r'[0-9]'))) return 'Chiffre requis';
                        if (!v.contains(RegExp('[!@#\$%^&*()\\-_=+\\[\\]{};:\'",.<>/?\\\\|`~]'))) return 'Caractère spécial requis';
                        return null;
                      }),
                    const SizedBox(height: 4),
                    Text(
                      'Le compte sera créé avec mustChangePassword = true.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Annuler', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: loading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setLocal(() => loading = true);
                final nav          = Navigator.of(ctx);
                final messenger    = ScaffoldMessenger.of(context);
                final ctxMessenger = ScaffoldMessenger.of(ctx);
                try {
                  await OfficerRepository().create({
                    'name':        nameCtrl.text.trim(),
                    'email':       emailCtrl.text.trim(),
                    'badgeNumber': badgeCtrl.text.trim().isEmpty ? null : badgeCtrl.text.trim(),
                    'telephone':   phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    'pin':         pinCtrl.text,
                  });
                  nav.pop();
                  ref.invalidate(officersProvider(_searchQuery));
                  messenger.showSnackBar(const SnackBar(
                    content: Text('Agent créé avec succès'),
                    backgroundColor: AppColors.success,
                  ));
                } catch (e) {
                  setLocal(() => loading = false);
                  ctxMessenger.showSnackBar(SnackBar(
                    content: Text('Erreur : $e'),
                    backgroundColor: AppColors.error,
                  ));
                }
              },
              child: loading
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Créer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialogue : import CSV ───────────────────────────────────────────────────
  void _showCsvImportDialog(BuildContext context) {
    final csvCtrl = TextEditingController();
    bool loading = false;
    Map<String, dynamic>? result;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Import CSV', style: AppTextStyles.titleMedium),
          content: SizedBox(
            width: double.maxFinite,
            child: result == null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          'Format : name,email,badge_number,telephone\n'
                          'Ex: Jean Mbemba,jean@pnc.cg,PNC-2024-001,+24206000001\n'
                          'La 1ère ligne peut être un en-tête (ignoré automatiquement).\n'
                          'Tous les emails doivent se terminer par @pnc.cg.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: csvCtrl,
                        maxLines: 8,
                        style: AppTextStyles.mono.copyWith(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Collez votre contenu CSV ici…',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ImportResultRow(
                          icon: Icons.check_circle_rounded,
                          color: AppColors.success,
                          label: '${result!['created']} agent(s) créé(s)',
                        ),
                        _ImportResultRow(
                          icon: Icons.skip_next_rounded,
                          color: AppColors.warning,
                          label: '${result!['skipped']} ignoré(s) (doublon)',
                        ),
                        _ImportResultRow(
                          icon: Icons.error_rounded,
                          color: AppColors.error,
                          label: '${(result!['errors'] as List).length} erreur(s)',
                        ),
                        if ((result!['credentials'] as List).isNotEmpty) ...[
                          const Divider(),
                          Text('Identifiants temporaires', style: AppTextStyles.labelMedium),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  for (final c in result!['credentials'] as List)
                                    _CredentialTile(
                                      email: c['email'] as String,
                                      password: c['tempPassword'] as String,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
          actions: result != null
              ? [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Fermer'),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Annuler',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: loading ? null : () async {
                      final csv = csvCtrl.text.trim();
                      if (csv.length < 10) {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Contenu CSV trop court'),
                          backgroundColor: AppColors.error,
                        ));
                        return;
                      }
                      setLocal(() => loading = true);
                      try {
                        final res = await OfficerRepository().importCsv(csv);
                        ref.invalidate(officersProvider(_searchQuery));
                        setLocal(() { loading = false; result = res; });
                      } catch (e) {
                        setLocal(() => loading = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text('Erreur import : $e'),
                            backgroundColor: AppColors.error,
                          ));
                        }
                      }
                    },
                    child: loading
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Importer', style: TextStyle(color: Colors.white)),
                  ),
                ],
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
        isDense: true,
      ),
      validator: validator ?? (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Rechercher un agent...',
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      (null, 'Tous'),
      (OfficerStatus.active, 'En service'),
      (OfficerStatus.inactive, 'Hors service'),
      (OfficerStatus.suspended, 'Suspendus'),
    ];

    return Container(
      height: 44,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: filters.map((f) {
          final isSelected = _filterStatus == f.$1;
          return GestureDetector(
            onTap: () => setState(() => _filterStatus = f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.info : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.info : AppColors.cardBorder),
              ),
              child: Center(
                child: Text(f.$2,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textTertiary,
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryRow(List<OfficerModel> all) {
    final active = all.where((o) => o.status == OfficerStatus.active).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _SummaryChip(label: 'Total', value: '${all.length}', color: AppColors.textTertiary),
          const SizedBox(width: 12),
          _SummaryChip(label: 'Actifs', value: '$active', color: AppColors.success),
          const SizedBox(width: 12),
          _SummaryChip(label: 'Hors service', value: '${all.length - active}', color: AppColors.warning),
        ],
      ),
    );
  }
}

class _OfficerCard extends StatelessWidget {
  final OfficerModel officer;
  const _OfficerCard({required this.officer});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(officer.avatarInitials,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(officer.fullName, style: AppTextStyles.titleSmall),
                    const SizedBox(height: 2),
                    Text(officer.rank, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 2),
                    Text(officer.badgeNumber,
                        style: AppTextStyles.mono.copyWith(fontSize: 10, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge.fromOfficerStatus(officer.status),
                  const SizedBox(height: 4),
                  if (officer.lastActivity != null)
                    Text(
                      _formatLastActivity(officer.lastActivity!),
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          Row(
            children: [
              _OfficerStat(label: 'Total', value: '${officer.totalInfractions}', icon: Icons.gavel_rounded),
              _OfficerStat(
                label: 'Aujourd\'hui',
                value: '${officer.todayInfractions}',
                icon: Icons.today_rounded,
                color: AppColors.primary,
              ),
              _OfficerStat(
                label: 'Revenus',
                value: '${(officer.totalRevenue / 1000000).toStringAsFixed(1)}M',
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(officer.zone, style: AppTextStyles.caption),
              const Spacer(),
              const Icon(Icons.phone_outlined, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(officer.phone, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  String _formatLastActivity(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }
}

class _OfficerStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  const _OfficerStat({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.textTertiary),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.labelSmall.copyWith(color: color ?? AppColors.textPrimary)),
              Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImportResultRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _ImportResultRow({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _CredentialTile extends StatelessWidget {
  final String email;
  final String password;
  const _CredentialTile({required this.email, required this.password});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email, style: AppTextStyles.mono.copyWith(fontSize: 11)),
                Text(password,
                    style: AppTextStyles.mono.copyWith(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textTertiary),
            tooltip: 'Copier',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Clipboard.setData(ClipboardData(text: '$email / $password')),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppTextStyles.labelSmall.copyWith(color: color)),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
