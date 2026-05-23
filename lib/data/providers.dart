import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/fine_model.dart';
import '../shared/models/officer_model.dart';
import '../shared/models/notification_model.dart';
import '../shared/models/infraction_model.dart';
import 'repositories.dart';

// Repository singletons (ajouts)
final paymentRepositoryProvider = Provider((_) => PaymentRepository());

// Dépôts (singletons).
final authRepositoryProvider = Provider((_) => AuthRepository());
final fineRepositoryProvider = Provider((_) => FineRepository());
final infractionRepositoryProvider = Provider((_) => InfractionRepository());
final officerRepositoryProvider = Provider((_) => OfficerRepository());
final notificationRepositoryProvider =
    Provider((_) => NotificationRepository());
final driverRepositoryProvider = Provider((_) => DriverRepository());
final statsRepositoryProvider = Provider((_) => StatsRepository());

/// Catalogue public des infractions (utilisé dans le flux de verbalisation).
final infractionsProvider =
    FutureProvider.autoDispose<List<InfractionType>>((ref) {
  return ref.read(infractionRepositoryProvider).list();
});

/// Contraventions de l'utilisateur courant (RLS appliquée côté serveur).
final myFinesProvider =
    FutureProvider.autoDispose<List<FineModel>>((ref) async {
  final page = await ref.read(fineRepositoryProvider).list(limit: 50);
  return page.items;
});

/// Détail d'une contravention par identifiant.
final fineDetailProvider =
    FutureProvider.autoDispose.family<FineModel, String>((ref, id) {
  return ref.read(fineRepositoryProvider).getById(id);
});

/// Notifications de l'utilisateur courant.
final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final page = await ref.read(notificationRepositoryProvider).list(limit: 50);
  return page.items;
});

/// Recherche d'agents (admin) — paramétrée par le terme de recherche.
final officersProvider = FutureProvider.autoDispose
    .family<List<OfficerModel>, String>((ref, search) async {
  final page = await ref
      .read(officerRepositoryProvider)
      .list(limit: 50, search: search);
  return page.items;
});

/// Statistiques personnelles de l'agent connecté.
final officerStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.read(statsRepositoryProvider).officerStats();
});

/// KPIs nationaux pour l'admin.
final adminStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.read(statsRepositoryProvider).adminStats();
});

/// Statistiques de revenus (admin).
final revenueStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.read(statsRepositoryProvider).revenue();
});

/// Reçu d'un paiement (citoyen ou agent).
final receiptProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, paymentId) {
  return ref.read(paymentRepositoryProvider).receipt(paymentId);
});

/// Carte thermique des infractions (admin).
final heatmapProvider = FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.read(statsRepositoryProvider).heatmap();
});

/// Infractions sélectionnées pendant le flux d'interpellation.
/// Partagé entre InfractionSelectionScreen → FineCalculationScreen.
final selectedInfractionsProvider =
    StateProvider<List<InfractionType>>((ref) => []);
