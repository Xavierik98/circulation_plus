import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../data/api_client.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/status_badge.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Écran de vérification rapide d'un permis de conduire
// Accessible depuis le dashboard police et le flux d'interpellation
// ─────────────────────────────────────────────────────────────────────────────
class LicenseVerifyScreen extends StatefulWidget {
  /// Pré-rempli si appelé depuis le flux OCR / scan
  final String? initialLicense;
  final String? initialPlate;

  const LicenseVerifyScreen({
    super.key,
    this.initialLicense,
    this.initialPlate,
  });

  @override
  State<LicenseVerifyScreen> createState() => _LicenseVerifyScreenState();
}

class _LicenseVerifyScreenState extends State<LicenseVerifyScreen> {
  final _controller = TextEditingController();
  String _mode = 'license'; // 'license' | 'plate'
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialLicense != null) {
      _mode = 'license';
      _controller.text = widget.initialLicense!;
    } else if (widget.initialPlate != null) {
      _mode = 'plate';
      _controller.text = widget.initialPlate!;
    }
    // Auto-vérifier si valeur pré-remplie
    if (_controller.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final query = _controller.text.trim().toUpperCase();
    if (query.isEmpty) return;
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final data = await ApiClient.instance.get(
        '/api/drivers',
        query: _mode == 'license' ? {'license': query} : {'plate': query},
      );
      setState(() { _result = data as Map<String, dynamic>; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.credit_card_rounded,
                  size: 18, color: AppColors.gold),
            ),
            const SizedBox(width: 10),
            Text('Vérification permis', style: AppTextStyles.titleSmall),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
              height: 3,
              decoration:
                  const BoxDecoration(gradient: AppColors.congoFlagGradient)),
        ),
      ),
      body: Column(
        children: [
          // ── Barre de recherche ───────────────────────────────────────────
          _SearchBar(
            controller: _controller,
            mode: _mode,
            onModeChange: (m) => setState(() { _mode = m; _result = null; _error = null; }),
            onSearch: _verify,
            loading: _loading,
          ),
          // ── Résultat ─────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _verify)
                    : _result != null
                        ? _DriverResult(driver: _result!)
                        : _EmptyHint(mode: _mode),
          ),
        ],
      ),
    );
  }
}

// ── Barre de recherche ────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String mode;
  final ValueChanged<String> onModeChange;
  final VoidCallback onSearch;
  final bool loading;
  const _SearchBar({
    required this.controller,
    required this.mode,
    required this.onModeChange,
    required this.onSearch,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Toggle plaque/permis
          Row(
            children: [
              _ModeTab(label: 'N° Permis', icon: Icons.credit_card_rounded,
                  selected: mode == 'license',
                  onTap: () => onModeChange('license')),
              const SizedBox(width: 8),
              _ModeTab(label: 'Plaque',    icon: Icons.directions_car_rounded,
                  selected: mode == 'plate',
                  onTap: () => onModeChange('plate')),
            ],
          ),
          const SizedBox(height: 10),
          // Champ de saisie
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  style: AppTextStyles.mono.copyWith(
                      fontSize: 16, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: mode == 'license'
                        ? 'Ex: CG-BZV-2024-001'
                        : 'Ex: BZV-4521-A',
                    hintStyle: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(
                      mode == 'license'
                          ? Icons.credit_card_rounded
                          : Icons.directions_car_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 18, color: AppColors.textTertiary),
                            onPressed: () => controller.clear(),
                          )
                        : null,
                  ),
                  onSubmitted: (_) => onSearch(),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: loading ? null : onSearch,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: loading
                        ? null
                        : AppColors.goldGradient,
                    color: loading ? AppColors.surfaceVariant : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: loading
                      ? const Center(
                          child: SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.gold),
                          ))
                      : const Icon(Icons.search_rounded,
                          color: AppColors.policeNavy, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeTab({
    required this.label, required this.icon,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withValues(alpha: 0.15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected
                  ? AppColors.gold.withValues(alpha: 0.5)
                  : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? AppColors.gold : AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                    color: selected ? AppColors.gold : AppColors.textTertiary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

// ── Résultat conducteur ───────────────────────────────────────────────────────
class _DriverResult extends StatelessWidget {
  final Map<String, dynamic> driver;
  const _DriverResult({required this.driver});

  @override
  Widget build(BuildContext context) {
    final permisValide = driver['permisValideComputed'] as bool? ?? false;
    final permisSuspendu = driver['permisSuspendu'] as bool? ?? false;
    final permisExpire = driver['permisExpire'] as bool? ?? false;
    final joursExpir = driver['joursAvantExpiration'] as int?;
    final photoUrl = driver['photoUrl'] as String?;
    final nom = '${driver['prenom'] ?? ''} ${driver['nom'] ?? ''}'.trim();
    final numPermis = driver['numeroPermis'] as String? ?? '—';
    final categories = (driver['categoriesPermis'] as String? ?? 'B')
        .split(',').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
    final dateExp = driver['dateExpirationPermis'] as String?;
    final dateDel = driver['dateDelivrancePermis'] as String?;
    final lieu = driver['lieuDelivrance'] as String?;
    final points = driver['pointsPermis'] as int? ?? 12;
    final vehicles = (driver['vehicles'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final fines = (driver['fines'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    // Couleur et label de validité
    final statusColor = permisValide
        ? AppColors.success
        : permisSuspendu
            ? AppColors.warning
            : AppColors.error;
    final statusLabel = permisValide
        ? 'PERMIS VALIDE'
        : permisSuspendu
            ? 'SUSPENDU'
            : permisExpire ? 'EXPIRÉ' : 'INVALIDE';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Bannière statut ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(
                permisValide
                    ? Icons.verified_rounded
                    : Icons.cancel_rounded,
                color: statusColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusLabel,
                        style: AppTextStyles.titleSmall.copyWith(
                            color: statusColor, fontSize: 15)),
                    if (joursExpir != null)
                      Text(
                        joursExpir > 0
                            ? 'Expire dans $joursExpir jour${joursExpir > 1 ? 's' : ''}'
                            : 'Expiré depuis ${(-joursExpir)} jour${(-joursExpir) > 1 ? 's' : ''}',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: joursExpir > 30
                                ? AppColors.textTertiary
                                : AppColors.warning),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 350.ms),
        const SizedBox(height: 14),

        // ── Carte conducteur ─────────────────────────────────────────────
        PremiumCard(
          child: Row(
            children: [
              // Photo
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5), width: 2),
                ),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(photoUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initials(nom))
                      : _initials(nom),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nom.isEmpty ? '—' : nom,
                        style: AppTextStyles.titleSmall),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => Clipboard.setData(
                          ClipboardData(text: numPermis)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(numPermis,
                            style: AppTextStyles.mono.copyWith(
                                fontSize: 12, color: AppColors.gold)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Points de permis
                    Row(
                      children: [
                        ...List.generate(12, (i) => Container(
                          width: 10, height: 10,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < points
                                ? (points > 6 ? AppColors.success
                                    : points > 3 ? AppColors.warning
                                    : AppColors.error)
                                : AppColors.surfaceVariant,
                          ),
                        )),
                        const SizedBox(width: 6),
                        Text('$points/12 pts',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textTertiary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 12),

        // ── Détails permis ───────────────────────────────────────────────
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Permis de conduire',
                  style: AppTextStyles.titleSmall
                      .copyWith(color: AppColors.textTertiary)),
              const SizedBox(height: 12),
              // Catégories
              Row(
                children: [
                  Text('Catégories', style: AppTextStyles.bodySmall),
                  const Spacer(),
                  ...categories.map((c) => Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Text(c,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800)),
                  )),
                ],
              ),
              if (dateDel != null) ...[
                const Padding(padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.divider)),
                _InfoRow('Délivré le', _fmtDate(dateDel)),
              ],
              if (dateExp != null) ...[
                const Padding(padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.divider)),
                _InfoRow('Expire le', _fmtDate(dateExp),
                    valueColor: permisExpire ? AppColors.error
                        : joursExpir != null && joursExpir < 30
                            ? AppColors.warning : null),
              ],
              if (lieu != null) ...[
                const Padding(padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.divider)),
                _InfoRow('Délivré à', lieu),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 160.ms),
        const SizedBox(height: 12),

        // ── Véhicules ────────────────────────────────────────────────────
        if (vehicles.isNotEmpty) ...[
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Véhicule${vehicles.length > 1 ? 's' : ''} enregistré${vehicles.length > 1 ? 's' : ''}',
                    style: AppTextStyles.titleSmall
                        .copyWith(color: AppColors.textTertiary)),
                const SizedBox(height: 10),
                ...vehicles.asMap().entries.map((e) => Column(
                  children: [
                    _VehicleRow(vehicle: e.value),
                    if (e.key < vehicles.length - 1)
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: AppColors.divider)),
                  ],
                )),
              ],
            ),
          ).animate().fadeIn(delay: 220.ms),
          const SizedBox(height: 12),
        ],

        // ── Antécédents (5 dernières amendes) ───────────────────────────
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Antécédents', style: AppTextStyles.titleSmall
                      .copyWith(color: AppColors.textTertiary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (fines.isEmpty ? AppColors.success : AppColors.warning)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      fines.isEmpty ? 'Aucun' : '${fines.length} PV',
                      style: AppTextStyles.caption.copyWith(
                          color: fines.isEmpty
                              ? AppColors.success
                              : AppColors.warning,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              if (fines.isEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 18, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text('Casier vierge', style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.success)),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 10),
                ...fines.asMap().entries.map((e) => _FineRow(fine: e.value)),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 280.ms),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _initials(String name) {
    final p = name.trim().split(RegExp(r'\s+'));
    final init = p.take(2).map((x) => x.isNotEmpty ? x[0].toUpperCase() : '').join();
    return Container(
      color: AppColors.policeNavy,
      child: Center(child: Text(init.isEmpty ? '?' : init,
          style: const TextStyle(color: AppColors.gold, fontSize: 22, fontWeight: FontWeight.w800))),
    );
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        const Spacer(),
        Text(value,
            style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _VehicleRow extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  const _VehicleRow({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final plaque = vehicle['plaque'] as String? ?? '—';
    final marque = vehicle['marque'] as String? ?? '';
    final modele = vehicle['modele'] as String? ?? '';
    final couleur = vehicle['couleur'] as String? ?? '';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.directions_car_rounded,
              size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plaque, style: AppTextStyles.mono.copyWith(
                  fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w700)),
              if (marque.isNotEmpty || modele.isNotEmpty)
                Text('$marque $modele'.trim(),
                    style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        if (couleur.isNotEmpty)
          Text(couleur, style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary)),
      ],
    );
  }
}

class _FineRow extends StatelessWidget {
  final Map<String, dynamic> fine;
  const _FineRow({required this.fine});

  @override
  Widget build(BuildContext context) {
    final infraction = fine['infractionType'] as Map<String, dynamic>?;
    final label = infraction?['libelle'] as String? ?? '—';
    final status = fine['status'] as String? ?? 'PENDING';
    final montant = (fine['montantTotal'] as num?)?.toInt() ?? 0;
    final dateStr = fine['verbaliseLe'] as String?;
    final statusColor = status == 'PAID' ? AppColors.success
        : status == 'OVERDUE' ? AppColors.error
        : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: statusColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (dateStr != null)
                  Text(_fmtDate(dateStr),
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
          Text('${(montant / 1000).toStringAsFixed(0)} 000 F',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return iso; }
  }
}

// ── Empty / hint ──────────────────────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  final String mode;
  const _EmptyHint({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.credit_card_outlined,
                size: 44, color: AppColors.gold),
          ),
          const SizedBox(height: 16),
          Text('Saisissez un ${mode == 'license' ? 'numéro de permis' : 'numéro de plaque'}',
              style: AppTextStyles.titleSmall),
          const SizedBox(height: 6),
          Text('La vérification est instantanée.',
              style: AppTextStyles.bodySmall),
        ],
      ).animate().fadeIn(),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final notFound = error.toLowerCase().contains('not_found') ||
        error.toLowerCase().contains('introuvable');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              notFound ? Icons.search_off_rounded : Icons.error_outline_rounded,
              size: 48,
              color: notFound ? AppColors.textTertiary : AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              notFound ? 'Conducteur introuvable' : 'Erreur de vérification',
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              notFound
                  ? 'Aucun conducteur trouvé pour ce critère dans la base PNC.'
                  : error,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (!notFound) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ).animate().fadeIn(),
    );
  }
}
