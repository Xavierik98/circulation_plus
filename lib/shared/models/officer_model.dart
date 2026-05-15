enum OfficerStatus { active, inactive, suspended }

class OfficerModel {
  final String id;
  final String badgeNumber;
  final String firstName;
  final String lastName;
  final String rank;
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
  });

  String get fullName => '$firstName $lastName';

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
