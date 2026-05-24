enum OfficerStatus { active, inactive, suspended }

/// Grades PNC — reflète l'enum GradePNC du backend.
enum GradePNC {
  directeurGeneral,
  directeurGeneralAdjoint,
  directeurCentral,
  directeurDepartemental,
  commissaireDivisionnaire,
  commissairePrincipal,
  commissaire,
  inspecteurPrincipal,
  inspecteur,
  brigadierChef,
  brigadier,
  gardienDeLaPaix1cl,
  gardienDeLaPaix2cl,
  unknown,
}

GradePNC gradeFromString(String? s) {
  switch (s) {
    case 'DIRECTEUR_GENERAL':            return GradePNC.directeurGeneral;
    case 'DIRECTEUR_GENERAL_ADJOINT':    return GradePNC.directeurGeneralAdjoint;
    case 'DIRECTEUR_CENTRAL':            return GradePNC.directeurCentral;
    case 'DIRECTEUR_DEPARTEMENTAL':      return GradePNC.directeurDepartemental;
    case 'COMMISSAIRE_DIVISIONNAIRE':    return GradePNC.commissaireDivisionnaire;
    case 'COMMISSAIRE_PRINCIPAL':        return GradePNC.commissairePrincipal;
    case 'COMMISSAIRE':                  return GradePNC.commissaire;
    case 'INSPECTEUR_PRINCIPAL':         return GradePNC.inspecteurPrincipal;
    case 'INSPECTEUR':                   return GradePNC.inspecteur;
    case 'BRIGADIER_CHEF':               return GradePNC.brigadierChef;
    case 'BRIGADIER':                    return GradePNC.brigadier;
    case 'GARDIEN_DE_LA_PAIX_1CL':      return GradePNC.gardienDeLaPaix1cl;
    case 'GARDIEN_DE_LA_PAIX_2CL':      return GradePNC.gardienDeLaPaix2cl;
    default:                             return GradePNC.unknown;
  }
}

String gradeLabel(GradePNC grade) {
  switch (grade) {
    case GradePNC.directeurGeneral:          return 'Directeur Général';
    case GradePNC.directeurGeneralAdjoint:   return 'Directeur Général Adjoint';
    case GradePNC.directeurCentral:          return 'Directeur Central';
    case GradePNC.directeurDepartemental:    return 'Directeur Départemental';
    case GradePNC.commissaireDivisionnaire:  return 'Commissaire Divisionnaire';
    case GradePNC.commissairePrincipal:      return 'Commissaire Principal';
    case GradePNC.commissaire:               return 'Commissaire';
    case GradePNC.inspecteurPrincipal:       return 'Inspecteur Principal';
    case GradePNC.inspecteur:                return 'Inspecteur';
    case GradePNC.brigadierChef:             return 'Brigadier-Chef';
    case GradePNC.brigadier:                 return 'Brigadier';
    case GradePNC.gardienDeLaPaix1cl:        return 'Gardien de la Paix 1ère Cl.';
    case GradePNC.gardienDeLaPaix2cl:        return 'Gardien de la Paix 2ème Cl.';
    case GradePNC.unknown:                   return 'Agent PNC';
  }
}

/// Niveau hiérarchique fonctionnel — reflète l'enum NiveauHierarchique du backend.
enum NiveauHierarchique {
  directionGenerale,
  directionDept,
  commissariatCentral,
  commissariatZone,
  agent,
  unknown,
}

NiveauHierarchique niveauFromString(String? s) {
  switch (s) {
    case 'DIRECTION_GENERALE':    return NiveauHierarchique.directionGenerale;
    case 'DIRECTION_DEPT':        return NiveauHierarchique.directionDept;
    case 'COMMISSARIAT_CENTRAL':  return NiveauHierarchique.commissariatCentral;
    case 'COMMISSARIAT_ZONE':     return NiveauHierarchique.commissariatZone;
    case 'AGENT':                 return NiveauHierarchique.agent;
    default:                      return NiveauHierarchique.unknown;
  }
}

class OfficerModel {
  final String id;
  final String badgeNumber;
  final String firstName;
  final String lastName;
  final String rank;           // Label lisible (ex: "Inspecteur Principal")
  final String unit;
  final String zone;
  final String phone;
  final String avatarInitials;
  final OfficerStatus status;
  final int totalInfractions;
  final int todayInfractions;
  final double totalRevenue;
  final DateTime? lastActivity;
  final DateTime joinedDate;
  final bool onDuty;
  final double? lastLat;
  final double? lastLng;
  final DateTime? lastSeenAt;
  // ── Champs hiérarchiques (depuis le backend v2) ───────────────────────────
  final GradePNC grade;
  final NiveauHierarchique niveauHierarchique;
  final String? commissariatId;
  final String? departement;
  final String? email;
  final bool mustChangePassword;

  const OfficerModel({
    required this.id,
    required this.badgeNumber,
    required this.firstName,
    required this.lastName,
    required this.rank,
    required this.unit,
    required this.zone,
    required this.phone,
    required this.avatarInitials,
    required this.status,
    required this.totalInfractions,
    required this.todayInfractions,
    required this.totalRevenue,
    this.lastActivity,
    required this.joinedDate,
    this.onDuty = false,
    this.lastLat,
    this.lastLng,
    this.lastSeenAt,
    this.grade = GradePNC.unknown,
    this.niveauHierarchique = NiveauHierarchique.agent,
    this.commissariatId,
    this.departement,
    this.email,
    this.mustChangePassword = false,
  });

  String get fullName => '$firstName $lastName'.trim();

  static final List<OfficerModel> mockOfficers = [
    OfficerModel(
      id: 'OFF001',
      badgeNumber: 'PNB-4521',
      firstName: 'Jean-Pierre',
      lastName: 'Moukala',
      rank: 'Brigadier-Chef',
      unit: 'Brigade de Circulation',
      zone: 'Brazzaville Centre',
      phone: '+242 06 123 4567',
      avatarInitials: 'JM',
      status: OfficerStatus.active,
      totalInfractions: 1247,
      todayInfractions: 12,
      totalRevenue: 18705000,
      lastActivity: DateTime.now().subtract(const Duration(minutes: 15)),
      joinedDate: DateTime(2019, 3, 12),
    ),
    OfficerModel(
      id: 'OFF002',
      badgeNumber: 'PPN-2893',
      firstName: 'Marie-Claire',
      lastName: 'Ngoma',
      rank: 'Gardien de la Paix',
      unit: 'Police Nationale',
      zone: 'Pointe-Noire',
      phone: '+242 05 987 6543',
      avatarInitials: 'MN',
      status: OfficerStatus.active,
      totalInfractions: 843,
      todayInfractions: 8,
      totalRevenue: 12645000,
      lastActivity: DateTime.now().subtract(const Duration(minutes: 45)),
      joinedDate: DateTime(2021, 7, 8),
    ),
    OfficerModel(
      id: 'OFF003',
      badgeNumber: 'PNB-1102',
      firstName: 'Gabriel',
      lastName: 'Loemba',
      rank: 'Brigadier',
      unit: 'Brigade de Circulation',
      zone: 'Brazzaville Nord',
      phone: '+242 06 456 7890',
      avatarInitials: 'GL',
      status: OfficerStatus.active,
      totalInfractions: 2104,
      todayInfractions: 21,
      totalRevenue: 31560000,
      lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
      joinedDate: DateTime(2016, 11, 20),
    ),
    OfficerModel(
      id: 'OFF004',
      badgeNumber: 'PNB-3347',
      firstName: 'Christophe',
      lastName: 'Mavoungou',
      rank: 'Inspecteur',
      unit: 'Inspection Générale',
      zone: 'Brazzaville Sud',
      phone: '+242 06 333 2211',
      avatarInitials: 'CM',
      status: OfficerStatus.inactive,
      totalInfractions: 567,
      todayInfractions: 0,
      totalRevenue: 8505000,
      lastActivity: DateTime.now().subtract(const Duration(days: 1)),
      joinedDate: DateTime(2018, 5, 3),
    ),
    OfficerModel(
      id: 'OFF005',
      badgeNumber: 'PPN-4456',
      firstName: 'Sylvie',
      lastName: 'Nkodia',
      rank: 'Gardien de la Paix',
      unit: 'Brigade Routière',
      zone: 'Dolisie',
      phone: '+242 05 111 2233',
      avatarInitials: 'SN',
      status: OfficerStatus.active,
      totalInfractions: 932,
      todayInfractions: 15,
      totalRevenue: 13980000,
      lastActivity: DateTime.now().subtract(const Duration(hours: 1)),
      joinedDate: DateTime(2020, 2, 17),
    ),
  ];

  static OfficerModel get currentOfficer => mockOfficers.first;
}
