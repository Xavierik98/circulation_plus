import 'dart:async';
import 'package:flutter/foundation.dart';
import 'offline_cache.dart';
import 'repositories.dart';

/// Service de synchronisation automatique.
///
/// Tente de synchroniser les PV en attente (créés hors-ligne)
/// avec le backend dès que le réseau est disponible.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final OfflineCache _cache = OfflineCache.instance;
  final FineRepository _fineRepo = FineRepository();

  bool _isSyncing = false;
  Timer? _retryTimer;

  /// Nombre de PV en attente (pour le badge UI).
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  /// Initialise le service et démarre une tentative de sync.
  Future<void> init() async {
    await _refreshCount();
    // Tenter une première sync au démarrage
    await syncNow();
    // Retry toutes les 2 minutes si des PV sont en attente
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      syncNow();
    });
  }

  /// Tente de synchroniser immédiatement tous les PV en attente.
  /// Retourne le nombre de PV synchronisés avec succès.
  Future<int> syncNow() async {
    if (_isSyncing) return 0;
    _isSyncing = true;

    int synced = 0;
    try {
      final pending = await _cache.getPendingFines();
      if (pending.isEmpty) {
        _isSyncing = false;
        return 0;
      }

      for (final entry in List<Map<String, dynamic>>.from(pending)) {
        try {
          final payload = entry['payload'] as Map<String, dynamic>;
          await _fineRepo.create(payload);
          await _cache.removePendingFine(entry['id'] as String);
          synced++;
          debugPrint('[SyncService] ✓ PV synchronisé : ${entry['id']}');
        } catch (e) {
          // Le serveur n'est pas encore accessible, on garde le PV en file
          debugPrint('[SyncService] ✗ Échec sync PV ${entry['id']}: $e');
          break; // Inutile de tenter les suivants si le réseau est KO
        }
      }

      await _refreshCount();
    } finally {
      _isSyncing = false;
    }

    return synced;
  }

  /// Met à jour le compteur de PV en attente.
  Future<void> _refreshCount() async {
    pendingCount.value = await _cache.pendingCount;
  }

  /// Arrête le timer de retry (appelé quand l'app se ferme).
  void dispose() {
    _retryTimer?.cancel();
  }
}
