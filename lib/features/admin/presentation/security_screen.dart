import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../data/api_client.dart';
import '../../../shared/widgets/glass_card.dart';

// ── Provider ──────────────────────────────────────────────────────────────────
final blockedIpsProvider =
    FutureProvider.autoDispose<List<_BlockedIp>>((ref) async {
  final data = await ApiClient.instance.get('/api/auth/admin/blocked-ips');
  final list = data as List<dynamic>;
  return list
      .cast<Map<String, dynamic>>()
      .map((j) => _BlockedIp(
            ip: j['ip'] as String,
            ttlSeconds: (j['ttlSeconds'] as num).toInt(),
          ))
      .toList();
});

class _BlockedIp {
  final String ip;
  final int ttlSeconds;
  const _BlockedIp({required this.ip, required this.ttlSeconds});
}

// ── Screen ────────────────────────────────────────────────────────────────────
class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncIps = ref.watch(blockedIpsProvider);

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
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_outlined,
                  size: 18, color: AppColors.error),
            ),
            const SizedBox(width: 10),
            Text('Sécurité — IPs bloquées', style: AppTextStyles.titleSmall),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => ref.invalidate(blockedIpsProvider),
            tooltip: 'Actualiser',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
              height: 3,
              decoration:
                  const BoxDecoration(gradient: AppColors.congoFlagGradient)),
        ),
      ),
      body: asyncIps.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _ErrorBody(error: e.toString(),
            onRetry: () => ref.invalidate(blockedIpsProvider)),
        data: (ips) => _IpListBody(ips: ips,
            onUnblock: (ip) => _unblock(context, ref, ip)),
      ),
    );
  }

  Future<void> _unblock(
      BuildContext context, WidgetRef ref, String ip) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Débloquer $ip ?', style: AppTextStyles.titleSmall),
        content: Text(
          'L\'IP $ip pourra à nouveau tenter de se connecter.',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Débloquer',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!context.mounted) return;

    try {
      await ApiClient.instance
          .delete('/api/auth/admin/blocked-ips/${Uri.encodeComponent(ip)}');
      ref.invalidate(blockedIpsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('IP $ip débloquée'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }
}

// ── IP List ───────────────────────────────────────────────────────────────────
class _IpListBody extends StatelessWidget {
  final List<_BlockedIp> ips;
  final void Function(String ip) onUnblock;
  const _IpListBody({required this.ips, required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    if (ips.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_outlined,
                  size: 48, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            Text('Aucune IP bloquée', style: AppTextStyles.titleSmall),
            const SizedBox(height: 6),
            Text('Le système anti-brute-force est actif.',
                style: AppTextStyles.bodySmall),
          ],
        ).animate().fadeIn(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Banner info
        PremiumCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${ips.length} IP${ips.length > 1 ? 's' : ''} bloquée${ips.length > 1 ? 's' : ''}',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'Blocage automatique après 10 tentatives échouées (30 min).',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 12),
        ...ips.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _IpCard(
                ip: e.value,
                onUnblock: () => onUnblock(e.value.ip),
              ).animate().fadeIn(
                  delay: Duration(milliseconds: 80 * e.key), duration: 300.ms),
            )),
      ],
    );
  }
}

class _IpCard extends StatelessWidget {
  final _BlockedIp ip;
  final VoidCallback onUnblock;
  const _IpCard({required this.ip, required this.onUnblock});

  String _formatTtl(int seconds) {
    if (seconds <= 0) return 'Expiration imminente';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '$s s restantes';
    return '$m min $s s restantes';
  }

  @override
  Widget build(BuildContext context) {
    final fraction = (ip.ttlSeconds / (30 * 60)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.08),
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
              // IP chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.block_rounded,
                        size: 13, color: AppColors.error),
                    const SizedBox(width: 6),
                    Text(ip.ip,
                        style: AppTextStyles.mono.copyWith(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const Spacer(),
              // Unblock button
              GestureDetector(
                onTap: onUnblock,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_open_rounded,
                          size: 13, color: AppColors.success),
                      const SizedBox(width: 5),
                      Text('Débloquer',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // TTL progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                fraction > 0.5
                    ? AppColors.error
                    : fraction > 0.25
                        ? AppColors.warning
                        : AppColors.success,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(_formatTtl(ip.ttlSeconds),
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

// ── Error body ────────────────────────────────────────────────────────────────
class _ErrorBody extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorBody({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Impossible de charger les IPs bloquées',
                style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Text(error,
                style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
