import '../shared/models/fine_model.dart';
import '../shared/models/officer_model.dart';
import '../shared/models/notification_model.dart';
import '../shared/models/infraction_model.dart';

/// Conversions JSON backend (français / MAJUSCULES) -> modèles UI existants
/// (anglais / minuscules). Centralisé pour ne pas réécrire les écrans.

DateTime _date(dynamic v) =>
    v == null ? DateTime.now() : DateTime.tryParse(v.toString())?.toLocal() ?? DateTime.now();

DateTime? _dateOrNull(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

FineStatus _fineStatus(String? s) {
  switch (s) {
    case 'PAID':
      return FineStatus.paid;
    case 'OVERDUE':
      return FineStatus.overdue;
    case 'CONTESTED':
      return FineStatus.contested;
    case 'PENDING':
    default:
      return FineStatus.pending;
  }
}

FineModel fineFromJson(Map<String, dynamic> j) {
  final driver = j['driver'] as Map<String, dynamic>?;
  final vehicle = j['vehicle'] as Map<String, dynamic>?;
  final officer = j['officer'] as Map<String, dynamic>?;
  final infraction = j['infractionType'] as Map<String, dynamic>?;
  final payment = j['payment'] as Map<String, dynamic>?;

  return FineModel(
    id: j['id'] as String,
    reference: j['reference'] as String? ?? '',
    driverId: j['driverId'] as String? ?? '',
    driverName: driver == null
        ? ''
        : '${driver['prenom'] ?? ''} ${driver['nom'] ?? ''}'.trim(),
    vehiclePlate: vehicle?['plaque'] as String? ?? '',
    vehicleBrand: vehicle?['marque'] as String? ?? '',
    officerId: j['officerId'] as String? ?? '',
    officerName: officer?['name'] as String? ?? '',
    officerBadge: officer?['badgeNumber'] as String? ?? '',
    infractionCode: infraction?['code'] as String? ?? '',
    infractionLabel: infraction?['libelle'] as String? ?? '',
    amount: (j['montantTotal'] as num?)?.toInt() ?? 0,
    pointsDeducted: 0,
    status: _fineStatus(j['status'] as String?),
    issuedAt: _date(j['verbaliseLe']),
    deadline: _date(j['dateEcheance']),
    location: j['adresseApprox'] as String? ?? '',
    latitude: (j['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (j['longitude'] as num?)?.toDouble() ?? 0,
    paymentRef: payment?['transactionId'] as String?,
    paidAt: _dateOrNull(payment?['confirmedAt']),
    paymentMethod: payment?['operateur'] as String?,
  );
}

OfficerModel officerFromJson(Map<String, dynamic> j) {
  final name = (j['name'] as String? ?? '').trim();
  final parts = name.isEmpty ? <String>[''] : name.split(RegExp(r'\s+'));
  final firstName = parts.first;
  final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
  final actif = j['actif'] as bool? ?? true;

  return OfficerModel(
    id: j['id'] as String,
    badgeNumber: j['badgeNumber'] as String? ?? '',
    firstName: firstName,
    lastName: lastName,
    rank: 'Agent',
    unit: 'Police Nationale',
    zone: '—',
    phone: j['telephone'] as String? ?? '',
    avatarInitials:
        '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}',
    status: actif ? OfficerStatus.active : OfficerStatus.inactive,
    totalInfractions: (j['totalFines'] as num?)?.toInt() ?? 0,
    todayInfractions: 0,
    totalRevenue: (j['montantCollecte'] as num?)?.toDouble() ?? 0,
    lastActivity: null,
    joinedDate: _date(j['createdAt']),
  );
}

NotificationType _notifType(String? t) {
  switch (t) {
    case 'fine_created':
      return NotificationType.fine;
    case 'payment_confirmed':
      return NotificationType.payment;
    case 'convocation':
      return NotificationType.alert;
    case 'system':
      return NotificationType.system;
    default:
      return NotificationType.info;
  }
}

NotificationModel notificationFromJson(Map<String, dynamic> j) {
  final data = j['data'] as Map<String, dynamic>?;
  return NotificationModel(
    id: j['id'] as String,
    type: _notifType(j['type'] as String?),
    title: j['title'] as String? ?? '',
    body: j['body'] as String? ?? '',
    createdAt: _date(j['createdAt']),
    isRead: j['read'] as bool? ?? false,
    actionId: data?['fineId'] as String?,
  );
}

InfractionCategory _category(String code) {
  if (code.startsWith('EXV') || code.startsWith('DEP')) {
    return InfractionCategory.speed;
  }
  if (code.startsWith('STA')) return InfractionCategory.parking;
  if (code.startsWith('PER') ||
      code.startsWith('CGR') ||
      code.startsWith('ASS')) {
    return InfractionCategory.documents;
  }
  if (code.startsWith('FEU') ||
      code.startsWith('TEL') ||
      code.startsWith('PRI') ||
      code.startsWith('ALC')) {
    return InfractionCategory.behavior;
  }
  return InfractionCategory.safety;
}

const _categoryIcon = {
  InfractionCategory.speed: '🚗',
  InfractionCategory.safety: '🦺',
  InfractionCategory.documents: '📄',
  InfractionCategory.parking: '🅿️',
  InfractionCategory.behavior: '🚦',
};

InfractionType infractionFromJson(Map<String, dynamic> j) {
  final code = j['code'] as String? ?? '';
  final cat = _category(code);
  final label = j['libelle'] as String? ?? '';
  return InfractionType(
    id: j['id'] as String,
    code: code,
    labelFr: label,
    labelEn: label,
    fineAmount: (j['montantBase'] as num?)?.toInt() ?? 0,
    pointsDeducted: 0,
    category: cat,
    icon: _categoryIcon[cat] ?? '🚗',
  );
}
