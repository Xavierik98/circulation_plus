import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../data/api_client.dart';

class SuspensionHistoryScreen extends StatefulWidget {
  const SuspensionHistoryScreen({super.key});

  @override
  State<SuspensionHistoryScreen> createState() => _SuspensionHistoryScreenState();
}

class _SuspensionHistoryScreenState extends State<SuspensionHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  int _total = 0;
  int _page = 1;
  bool _hasMore = true;

  static final _dateFmt = DateFormat('d MMM yyyy, HH:mm', 'fr_FR');

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiClient.instance.get(
        '/api/officers/suspensions',
        query: { 'page': _page, 'limit': 30 },
      ) as Map<String, dynamic>;

      final newItems = (data['items'] as List<dynamic>).cast<Map<String, dynamic>>();
      _total = (data['total'] as num).toInt();

      setState(() {
        _items = _page == 1 ? newItems : [..._items, ...newItems];
        _hasMore = _items.length < _total;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loading) return;
    _page++;
    await _loadPage();
  }

  Future<void> _refresh() async {
    _page = 1;
    _items = [];
    await _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Historique des suspensions', style: AppTextStyles.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _refresh,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
            height: 3,
            decoration: const BoxDecoration(gradient: AppColors.congoFlagGradient),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text('Impossible de charger l\'historique', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Text(_error!, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 64, color: AppColors.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Aucune suspension enregistrée', style: AppTextStyles.titleSmall.copyWith(color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            Text('Les suspensions et réactivations apparaîtront ici.', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Stats banner
        _buildStatsBanner(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _items.length + (_hasMore ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == _items.length) {
                return _loading
                    ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                    : TextButton(onPressed: _loadMore, child: const Text('Charger plus'));
              }
              return _SuspensionEventCard(item: _items[i], dateFmt: _dateFmt)
                  .animate(delay: Duration(milliseconds: i * 40))
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.05);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBanner() {
    final suspensions  = _items.where((i) => i['action'] == 'OFFICER_SUSPENDED').length;
    final activations  = _items.where((i) => i['action'] == 'OFFICER_ACTIVATED').length;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _StatChip(label: 'Total', value: '$_total', color: AppColors.primary),
          const SizedBox(width: 12),
          _StatChip(label: 'Suspensions', value: '$suspensions', color: AppColors.error),
          const SizedBox(width: 12),
          _StatChip(label: 'Réactivations', value: '$activations', color: AppColors.success),
        ],
      ),
    );
  }
}

class _SuspensionEventCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final DateFormat dateFmt;
  const _SuspensionEventCard({required this.item, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    final action = item['action'] as String? ?? '';
    final isSuspension = action == 'OFFICER_SUSPENDED';
    final officerName  = item['officerName'] as String? ?? '—';
    final badgeNumber  = item['badgeNumber'] as String?;
    final motif        = item['motif'] as String?;
    final durationDays = item['durationDays'];
    final createdAt    = DateTime.tryParse(item['createdAt'] as String? ?? '')?.toLocal();

    final color = isSuspension ? AppColors.error : AppColors.success;
    final icon  = isSuspension ? Icons.block_rounded : Icons.check_circle_rounded;
    final label = isSuspension ? 'SUSPENDU' : 'RÉACTIVÉ';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(officerName, style: AppTextStyles.titleSmall, overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(label,
                            style: AppTextStyles.caption.copyWith(
                                color: color, fontWeight: FontWeight.w700, fontSize: 9, letterSpacing: 0.8)),
                      ),
                    ],
                  ),
                  if (badgeNumber != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 11, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        Text(badgeNumber, style: AppTextStyles.mono.copyWith(fontSize: 11, color: AppColors.textTertiary)),
                      ],
                    ),
                  ],
                  if (motif != null && motif.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.gavel_rounded, size: 13, color: AppColors.textTertiary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(motif,
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        createdAt != null ? dateFmt.format(createdAt) : '—',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                      ),
                      if (durationDays != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.timelapse_rounded, size: 12, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text('$durationDays jour(s)',
                            style: AppTextStyles.caption.copyWith(color: AppColors.warning)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.labelMedium.copyWith(color: color, fontWeight: FontWeight.w700)),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary, fontSize: 9)),
        ],
      ),
    );
  }
}
