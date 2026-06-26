import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/models/infraction_model.dart';

/// Service de cache hors-ligne.
///
/// Responsabilités :
/// 1. Mettre en cache le catalogue des infractions pour une utilisation hors-ligne.
/// 2. Stocker localement les PV créés sans connexion (file d'attente).
/// 3. Synchroniser automatiquement les PV en attente dès le retour du réseau.
class OfflineCache {
  OfflineCache._();
  static final OfflineCache instance = OfflineCache._();

  static const _keyInfractions = 'offline_infractions_cache';
  static const _keyPendingFines = 'offline_pending_fines';
  static const _keyCacheTimestamp = 'offline_cache_ts';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Infractions cache
  // ────────────────────────────────────────────────────────────────────────────

  /// Sauvegarde le catalogue des infractions dans le cache local.
  Future<void> cacheInfractions(List<InfractionType> infractions) async {
    final prefs = await _storage;
    final json = infractions.map((i) => {
      'id': i.id,
      'code': i.code,
      'labelFr': i.labelFr,
      'labelEn': i.labelEn,
      'fineAmount': i.fineAmount,
      'pointsDeducted': i.pointsDeducted,
      'category': i.category.index,
      'icon': i.icon,
    }).toList();
    await prefs.setString(_keyInfractions, jsonEncode(json));
    await prefs.setInt(_keyCacheTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  /// Charge le catalogue depuis le cache local.
  /// Retourne null si aucun cache n'existe.
  Future<List<InfractionType>?> getCachedInfractions() async {
    final prefs = await _storage;
    final raw = prefs.getString(_keyInfractions);
    if (raw == null) return null;

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return InfractionType(
          id: m['id'] as String? ?? '',
          code: m['code'] as String? ?? '',
          labelFr: m['labelFr'] as String? ?? '',
          labelEn: m['labelEn'] as String? ?? '',
          fineAmount: (m['fineAmount'] as num?)?.toInt() ?? 0,
          pointsDeducted: (m['pointsDeducted'] as num?)?.toInt() ?? 0,
          category: InfractionCategory.values[(m['category'] as num?)?.toInt() ?? 0],
          icon: m['icon'] as String? ?? '',
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }

  /// Vérifie si le cache est frais (moins de 24 heures).
  Future<bool> isCacheFresh() async {
    final prefs = await _storage;
    final ts = prefs.getInt(_keyCacheTimestamp);
    if (ts == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    return age < const Duration(hours: 24).inMilliseconds;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Pending fines queue (PV créés hors-ligne)
  // ────────────────────────────────────────────────────────────────────────────

  /// Ajoute un PV à la file d'attente hors-ligne.
  Future<void> queueFine(Map<String, dynamic> finePayload) async {
    final prefs = await _storage;
    final queue = await getPendingFines();
    final entry = {
      'payload': finePayload,
      'createdAt': DateTime.now().toIso8601String(),
      'id': '${DateTime.now().millisecondsSinceEpoch}',
    };
    queue.add(entry);
    await prefs.setString(_keyPendingFines, jsonEncode(queue));
  }

  /// Récupère tous les PV en attente de synchronisation.
  Future<List<Map<String, dynamic>>> getPendingFines() async {
    final prefs = await _storage;
    final raw = prefs.getString(_keyPendingFines);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Nombre de PV en attente.
  Future<int> get pendingCount async => (await getPendingFines()).length;

  /// Supprime un PV de la file après synchronisation réussie.
  Future<void> removePendingFine(String id) async {
    final prefs = await _storage;
    final queue = await getPendingFines();
    queue.removeWhere((e) => e['id'] == id);
    await prefs.setString(_keyPendingFines, jsonEncode(queue));
  }

  /// Vide toute la file (après sync complète).
  Future<void> clearPendingFines() async {
    final prefs = await _storage;
    await prefs.remove(_keyPendingFines);
  }
}
