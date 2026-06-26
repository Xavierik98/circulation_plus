import 'package:flutter/material.dart' hide Page;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../shared/models/fine_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/premium_button.dart';
import '../../../data/providers.dart';
import '../../../data/repositories.dart' show Page;
import '../../../data/api_client.dart';

class FinesManagementScreen extends ConsumerStatefulWidget {
  const FinesManagementScreen({super.key});

  @override
  ConsumerState<FinesManagementScreen> createState() =>
      _FinesManagementScreenState();
}

class _FinesManagementScreenState extends ConsumerState<FinesManagementScreen> {
  String? _filterStatus;
  int _currentPage = 1;
  DateTimeRange? _dateRange;

  AdminFinesParams get _params => AdminFinesParams(
    status: _filterStatus,
    dateFrom: _dateRange?.start.toIso8601String(),
    dateTo: _dateRange?.end.toIso8601String(),
    page: _currentPage,
  );

  void _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() { _dateRange = picked; _currentPage = 1; });
  }

  void _openDetailSheet(FineModel fine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FineDetailSheet(
        fine: fine,
        onStatusChanged: () {
          ref.invalidate(adminFinesProvider);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finesAsync = ref.watch(adminFinesProvider(_params));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Gestion des amendes', style: AppTextStyles.titleMedium),
        actions: [
          IconButton(
            icon: Icon(
              Icons.date_range_rounded,
              size: 20,
              color: _dateRange != null ? AppColors.primary : AppColors.textTertiary,
            ),
            onPressed: _pickDateRange,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient)),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          if (_dateRange != null) _buildDateBanner(),
          Expanded(
            child: finesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Amendes indisponibles.\n$e',
                      textAlign: TextAlign.center, style: AppTextStyles.bodyMedium),
                ),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return Center(
                    child: Text('Aucune amende', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary)),
                  );
                }
                return Column(
                  children: [
                    _buildSummaryBar(page.total),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: page.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          return _FineAdminCard(
                            fine: page.items[i],
                            onTap: () => _openDetailSheet(page.items[i]),
                          )
                              .animate(delay: Duration(milliseconds: i * 50))
                              .fadeIn(duration: 300.ms)
                              .slideX(begin: 0.05);
                        },
                      ),
                    ),
                    _buildPaginationBar(page),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      (null, 'Toutes'),
      ('PENDING', 'En attente'),
      ('PAID', 'Payées'),
      ('CONTESTED', 'Contestées'),
      ('OVERDUE', 'En retard'),
      ('CANCELLED', 'Annulées'),
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
            onTap: () => setState(() { _filterStatus = f.$1; _currentPage = 1; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.cardBorder),
              ),
              child: Center(
                child: Text(f.$2, style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.textTertiary,
                )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateBanner() {
    String fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.date_range_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            '${fmt(_dateRange!.start)} → ${fmt(_dateRange!.end)}',
            style: AppTextStyles.caption.copyWith(color: AppColors.primary),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() { _dateRange = null; _currentPage = 1; }),
            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('$total amende${total > 1 ? 's' : ''}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary)),
          const Spacer(),
          Text('Page $_currentPage', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildPaginationBar(Page<FineModel> page) {
    final totalPages = (page.total / page.limit).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.primary,
          ),
          Text('$_currentPage / $totalPages', style: AppTextStyles.bodySmall),
          IconButton(
            onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ─── Card amende ───────────────────────────────────────────────────────────────

class _FineAdminCard extends StatelessWidget {
  final FineModel fine;
  final VoidCallback onTap;
  const _FineAdminCard({required this.fine, required this.onTap});

  Color get _amountColor => fine.status == FineStatus.paid
      ? AppColors.success
      : fine.status == FineStatus.overdue
          ? AppColors.error
          : AppColors.warning;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              StatusBadge.fromFineStatus(fine.status),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fine.reference,
                  style: AppTextStyles.mono.copyWith(fontSize: 11, color: AppColors.textTertiary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(fine.amount / 1000).toStringAsFixed(0)}K',
                style: AppTextStyles.titleSmall.copyWith(color: _amountColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Expanded(child: Text(
                fine.officerName.isEmpty ? '—' : '${fine.officerName} · ${fine.officerBadge}',
                style: AppTextStyles.caption,
                overflow: TextOverflow.ellipsis,
              )),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Expanded(child: Text(
                fine.driverName.isEmpty ? '—' : '${fine.driverName} · ${fine.vehiclePlate}',
                style: AppTextStyles.caption,
                overflow: TextOverflow.ellipsis,
              )),
              const SizedBox(width: 8),
              Text(_fmt(fine.issuedAt), style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }
}

// ─── Sheet détail + changement statut ─────────────────────────────────────────

class _FineDetailSheet extends ConsumerStatefulWidget {
  final FineModel fine;
  final VoidCallback onStatusChanged;
  const _FineDetailSheet({required this.fine, required this.onStatusChanged});

  @override
  ConsumerState<_FineDetailSheet> createState() => _FineDetailSheetState();
}

class _FineDetailSheetState extends ConsumerState<_FineDetailSheet> {
  bool _isLoading = false;
  String? _error;

  Future<void> _changeStatus(String status) async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(fineRepositoryProvider).updateStatus(widget.fine.id, status);
      widget.onStatusChanged();
    } on ApiException catch (e) {
      setState(() { _isLoading = false; _error = e.message; });
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fine = widget.fine;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
            child: Column(children: [
              Container(height: 3, decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient)),
              const SizedBox(height: 14),
              Row(children: [
                StatusBadge.fromFineStatus(fine.status),
                const SizedBox(width: 10),
                Expanded(child: Text(fine.reference, style: AppTextStyles.mono.copyWith(fontSize: 12))),
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close_rounded, size: 20, color: AppColors.textTertiary)),
              ]),
            ]),
          ),
          // Détails
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _DetailRow(icon: Icons.attach_money_rounded, label: 'Montant', value: '${(fine.amount / 1000).toStringAsFixed(0)} 000 FCFA', valueColor: AppColors.warning),
                  _DetailRow(icon: Icons.badge_outlined, label: 'Agent', value: '${fine.officerName} · ${fine.officerBadge}'),
                  _DetailRow(icon: Icons.person_outline_rounded, label: 'Conducteur', value: fine.driverName.isEmpty ? '—' : fine.driverName),
                  _DetailRow(icon: Icons.directions_car_outlined, label: 'Véhicule', value: '${fine.vehiclePlate} — ${fine.vehicleBrand}'),
                  _DetailRow(icon: Icons.gavel_rounded, label: 'Infraction', value: '${fine.infractionCode} — ${fine.infractionLabel}'),
                  _DetailRow(icon: Icons.location_on_outlined, label: 'Lieu', value: fine.location.isEmpty ? '—' : fine.location),
                  _DetailRow(icon: Icons.calendar_today_rounded, label: 'Émise le', value: _fmt(fine.issuedAt)),
                  _DetailRow(icon: Icons.event_outlined, label: 'Échéance', value: _fmt(fine.deadline)),
                  if (fine.paidAt != null)
                    _DetailRow(icon: Icons.check_circle_outline_rounded, label: 'Payée le', value: _fmt(fine.paidAt!), valueColor: AppColors.success),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                    ),
                  ],

                  // Actions contextuelles
                  if (!_isLoading) ...[
                    const SizedBox(height: 20),
                    if (fine.status == FineStatus.pending) ...[
                      PremiumButton(
                        label: 'Marquer comme payée',
                        icon: Icons.check_circle_outline_rounded,
                        gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF2E7D32)]),
                        onPressed: () => _changeStatus('PAID'),
                      ),
                      const SizedBox(height: 10),
                      GhostButton(label: 'Annuler cette amende', icon: Icons.cancel_outlined, color: AppColors.error, onPressed: () => _changeStatus('CANCELLED')),
                    ],
                    if (fine.status == FineStatus.contested)
                      GhostButton(label: 'Annuler cette amende', icon: Icons.cancel_outlined, color: AppColors.error, onPressed: () => _changeStatus('CANCELLED')),
                    if (fine.status == FineStatus.overdue) ...[
                      PremiumButton(
                        label: 'Marquer comme payée',
                        icon: Icons.check_circle_outline_rounded,
                        gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF2E7D32)]),
                        onPressed: () => _changeStatus('PAID'),
                      ),
                      const SizedBox(height: 10),
                      GhostButton(label: 'Annuler cette amende', icon: Icons.cancel_outlined, color: AppColors.error, onPressed: () => _changeStatus('CANCELLED')),
                    ],
                  ] else ...[
                    const SizedBox(height: 20),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          SizedBox(width: 90, child: Text(label, style: AppTextStyles.caption)),
          Expanded(child: Text(value, style: AppTextStyles.bodySmall.copyWith(color: valueColor ?? AppColors.textPrimary))),
        ],
      ),
    );
  }
}
