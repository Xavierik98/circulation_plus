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
    paymentId: payment?['id'] as String?,
    paymentRef: payment?['transactionId'] as String?,
    paidAt: _dateOrNull(payment?['confirmedAt']),
    paymentMethod: payment?['mode'] as String? ?? payment?['operateur'] as String?,
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
    lastActivity: _dateOrNull(j['lastSeenAt']),
    joinedDate: _date(j['createdAt']),
    onDuty: j['onDuty'] as bool? ?? false,
    lastLat: (j['lastLat'] as num?)?.toDouble(),
    lastLng: (j['lastLng'] as num?)?.toDouble(),
    lastSeenAt: _dateOrNull(j['lastSeenAt']),
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

InfractionCategory _categoryFromCode(String code) {
  final c = code.toUpperCase();
  // Vitesse
  if (c.startsWith('EXV') || c.startsWith('VIT') || c.startsWith('DEP')) {
    return InfractionCategory.speed;
  }
  // Stationnement
  if (c.startsWith('STA') || c.startsWith('STAT') || c.startsWith('GAR')) {
    return InfractionCategory.parking;
  }
  // Documents
  if (c.startsWith('PER') || c.startsWith('CGR') || c.startsWith('ASS') ||
      c.startsWith('CTN') || c.startsWith('DOC') || c.startsWith('IMM')) {
    return InfractionCategory.documents;
  }
  // Comportement
  if (c.startsWith('FEU') || c.startsWith('TEL') || c.startsWith('PRI') ||
      c.startsWith('ALC') || c.startsWith('CTR') || c.startsWith('COMP') ||
      c.startsWith('DEP') || c.startsWith('CON') || c.startsWith('CEI') && c.length < 6) {
    return InfractionCategory.behavior;
  }
  // Sécurité (défaut)
  return InfractionCategory.safety;
}

InfractionCategory _categoryFromString(String? s) {
  switch ((s ?? '').toUpperCase()) {
    case 'VITESSE':       return InfractionCategory.speed;
    case 'SPEED':        return InfractionCategory.speed;
    case 'STATIONNEMENT': return InfractionCategory.parking;
    case 'PARKING':      return InfractionCategory.parking;
    case 'DOCUMENTS':    return InfractionCategory.documents;
    case 'COMPORTEMENT': return InfractionCategory.behavior;
    case 'BEHAVIOR':     return InfractionCategory.behavior;
    case 'SECURITE':     return InfractionCategory.safety;
    case 'SAFETY':       return InfractionCategory.safety;
    default:             return InfractionCategory.safety;
  }
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
  // Priorité : champ categorie du backend → puis déduction depuis le code
  final rawCat = j['categorie'] as String? ?? j['category'] as String?;
  final cat = rawCat != null && rawCat.isNotEmpty
      ? _categoryFromString(rawCat)
      : _categoryFromCode(code);
  final label = j['libelle'] as String? ?? j['label'] as String? ?? '';
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
