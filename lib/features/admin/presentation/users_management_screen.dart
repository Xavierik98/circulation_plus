import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../data/providers.dart';
import '../../../data/api_client.dart';

class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  ConsumerState<UsersManagementScreen> createState() =>
      _UsersManagementScreenState();
}

class _UsersManagementScreenState
    extends ConsumerState<UsersManagementScreen> {
  String _searchQuery = '';
  String? _roleFilter;     // null = tous, 'CITOYEN', 'POLICE', ou filtre suspendu
  bool? _actifFilter;      // null = tous, false = suspendus uniquement

  UsersParams get _params => UsersParams(
    role: _roleFilter,
    actif: _actifFilter,
    search: _searchQuery.isEmpty ? null : _searchQuery,
  );

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider(_params));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Gestion des comptes', style: AppTextStyles.titleMedium),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterBar(),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 48, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      Text('Comptes indisponibles',
                          style: AppTextStyles.titleSmall),
                      const SizedBox(height: 8),
                      Text(e.toString(),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(usersProvider),
                        icon: const Icon(Icons.refresh_rounded,
                            color: AppColors.primary),
                        label: Text('Réessayer',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 56,
                            color: AppColors.textTertiary.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text('Aucun compte trouvé',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textTertiary)),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    _buildSummaryRow(page.total),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: page.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          return _UserCard(
                            user: page.items[i],
                            onChanged: () => ref.invalidate(usersProvider),
                          )
                              .animate(delay: Duration(milliseconds: i * 50))
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

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Rechercher un compte...',
          prefixIcon:
              Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      (role: null as String?, actif: null as bool?, label: 'Tous'),
      (role: 'CITOYEN', actif: null as bool?, label: 'Citoyens'),
      (role: 'POLICE', actif: null as bool?, label: 'Police'),
      (role: null as String?, actif: false, label: 'Suspendus'),
    ];

    return Container(
      height: 44,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: filters.map((f) {
          final isSelected = _roleFilter == f.role && _actifFilter == f.actif;
          return GestureDetector(
            onTap: () => setState(() {
              _roleFilter = f.role;
              _actifFilter = f.actif;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.info : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected ? AppColors.info : AppColors.cardBorder),
              ),
              child: Center(
                child: Text(f.label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textTertiary,
                    )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryRow(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _SummaryChip(
            label: 'Total',
            value: '$total',
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

// ── Card utilisateur ──────────────────────────────────────────────────────────

class _UserCard extends ConsumerWidget {
  final UserModel user;
  final VoidCallback onChanged;

  const _UserCard({required this.user, required this.onChanged});

  void _openDetailSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(user: user, onChanged: onChanged),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumCard(
      onTap: () => _openDetailSheet(context, ref),
      child: Row(
        children: [
          // Avatar initiales
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: _roleGradient(user.role),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.avatarInitials,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nom + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName,
                    style: AppTextStyles.titleSmall,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(user.email,
                    style: AppTextStyles.bodySmall,
                    overflow: TextOverflow.ellipsis),
                if (user.telephone != null && user.telephone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 11, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(user.telephone!,
                          style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Badges
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _RoleBadge(role: user.role),
              const SizedBox(height: 4),
              StatusBadge(
                label: user.actif ? 'Actif' : 'Suspendu',
                color: user.actif ? AppColors.success : AppColors.error,
              ),
              if (user.finesCount != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${user.finesCount} PV',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  LinearGradient _roleGradient(UserRole role) {
    switch (role) {
      case UserRole.POLICE:
        return AppColors.policeGradient;
      case UserRole.ADMIN:
        return AppColors.goldGradient;
      case UserRole.CITOYEN:
        return AppColors.primaryGradient;
    }
  }
}

// ── Badge de rôle ─────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  Color get _color {
    switch (role) {
      case UserRole.POLICE:
        return AppColors.info;
      case UserRole.ADMIN:
        return AppColors.gold;
      case UserRole.CITOYEN:
        return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (role) {
      case UserRole.POLICE:
        return Icons.shield_rounded;
      case UserRole.ADMIN:
        return Icons.admin_panel_settings_rounded;
      case UserRole.CITOYEN:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 11, color: _color),
          const SizedBox(width: 4),
          Text(userRoleLabel(role),
              style: AppTextStyles.caption.copyWith(color: _color)),
        ],
      ),
    );
  }
}

// ── Sheet de détail utilisateur ───────────────────────────────────────────────

class _UserDetailSheet extends ConsumerStatefulWidget {
  final UserModel user;
  final VoidCallback onChanged;

  const _UserDetailSheet({required this.user, required this.onChanged});

  @override
  ConsumerState<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends ConsumerState<_UserDetailSheet> {
  bool _loading = false;
  String? _error;

  Future<void> _toggleStatus() async {
    final newStatus = !widget.user.actif;
    final action = newStatus ? 'Activer' : 'Suspendre';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('$action le compte', style: AppTextStyles.titleSmall),
        content: Text(
          'Confirmez-vous la décision de $action le compte de ${widget.user.fullName} ?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annuler',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  newStatus ? AppColors.success : AppColors.error,
            ),
            child: Text('$action',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(userRepositoryProvider)
          .setUserStatus(widget.user.id, newStatus);
      widget.onChanged();
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${widget.user.fullName} a été ${newStatus ? 'activé(e)' : 'suspendu(e)'}.'),
          backgroundColor: newStatus ? AppColors.success : AppColors.warning,
        ));
      }
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Supprimer le compte', style: AppTextStyles.titleSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action est irréversible.',
              style:
                  AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              'Supprimer définitivement le compte de ${widget.user.fullName} ?',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annuler',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(userRepositoryProvider).deleteUser(widget.user.id);
      widget.onChanged();
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Compte de ${widget.user.fullName} supprimé.'),
          backgroundColor: AppColors.error,
        ));
      }
    } on ApiException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header Congo gradient
          Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              gradient: AppColors.congoFlagGradient,
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          // Avatar + nom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _roleGradient(user.role),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(user.avatarInitials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _RoleBadge(role: user.role),
                          const SizedBox(width: 6),
                          StatusBadge(
                            label: user.actif ? 'Actif' : 'Suspendu',
                            color: user.actif
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          // Détails
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email,
                  ),
                  if (user.telephone != null && user.telephone!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Téléphone',
                      value: user.telephone!,
                    ),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Inscrit le',
                    value: _fmt(user.createdAt),
                  ),
                  if (user.finesCount != null)
                    _DetailRow(
                      icon: Icons.gavel_rounded,
                      label: 'Contraventions',
                      value: '${user.finesCount}',
                      valueColor: user.finesCount! > 0
                          ? AppColors.warning
                          : AppColors.success,
                    ),

                  // Erreur
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Text(_error!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.error)),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Actions
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    // Bouton Suspendre / Activer
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: Icon(
                          user.actif
                              ? Icons.block_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                        label: Text(
                          user.actif ? 'Suspendre ce compte' : 'Activer ce compte',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: user.actif
                              ? AppColors.error
                              : AppColors.success,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _toggleStatus,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Bouton Supprimer
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.error),
                        label: Text(
                          'Supprimer ce compte',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side:
                              BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _deleteUser,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _roleGradient(UserRole role) {
    switch (role) {
      case UserRole.POLICE:
        return AppColors.policeGradient;
      case UserRole.ADMIN:
        return AppColors.goldGradient;
      case UserRole.CITOYEN:
        return AppColors.primaryGradient;
    }
  }

  String _fmt(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          SizedBox(
              width: 100,
              child: Text(label, style: AppTextStyles.caption)),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                  color: valueColor ?? AppColors.textPrimary),
            ),
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
  const _SummaryChip(
      {required this.label, required this.value, required this.color});

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
          Text(value,
              style: AppTextStyles.labelSmall.copyWith(color: color)),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
