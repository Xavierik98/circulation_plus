enum FineStatus { pending, paid, overdue, contested, cancelled }

class FineModel {
  final String id;
  final String reference;
  final String driverId;
  final String driverName;
  final String vehiclePlate;
  final String vehicleBrand;
  final String officerId;
  final String officerName;
  final String officerBadge;
  final String infractionCode;
  final String infractionLabel;
  final int amount;
  final int pointsDeducted;
  final FineStatus status;
  final DateTime issuedAt;
  final DateTime deadline;
  final String location;
  final double latitude;
  final double longitude;
  final String? paymentId;   // UUID du paiement (pour le reçu)
  final String? paymentRef;
  final DateTime? paidAt;
  final String? paymentMethod;

  const FineModel({
    required this.id,
    required this.reference,
    required this.driverId,
    required this.driverName,
    required this.vehiclePlate,
    required this.vehicleBrand,
    required this.officerId,
    required this.officerName,
    required this.officerBadge,
    required this.infractionCode,
    required this.infractionLabel,
    required this.amount,
    required this.pointsDeducted,
    required this.status,
    required this.issuedAt,
    required this.deadline,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.paymentId,
    this.paymentRef,
    this.paidAt,
    this.paymentMethod,
  });

  bool get isOverdue => status == FineStatus.pending && deadline.isBefore(DateTime.now());

  static final List<FineModel> mockFines = [
    FineModel(
      id: 'FIN001',
      reference: 'CP-2024-001847',
      driverId: 'DRV001',
      driverName: 'Thierry Nguesso',
      vehiclePlate: 'BZV-4521-A',
      vehicleBrand: 'Toyota Corolla',
      officerId: 'OFF001',
      officerName: 'Jean-Pierre Moukala',
      officerBadge: 'PNB-4521',
      infractionCode: 'EXV-2',
      infractionLabel: 'Excès de vitesse 20–40 km/h',
      amount: 30000,
      pointsDeducted: 2,
      status: FineStatus.pending,
      issuedAt: DateTime.now().subtract(const Duration(days: 5)),
      deadline: DateTime.now().add(const Duration(days: 25)),
      location: 'Avenue de l\'Indépendance, Brazzaville',
      latitude: -4.2634,
      longitude: 15.2429,
      paymentId: null,
    ),
    FineModel(
      id: 'FIN002',
      reference: 'CP-2024-001523',
      driverId: 'DRV001',
      driverName: 'Thierry Nguesso',
      vehiclePlate: 'BZV-4521-A',
      vehicleBrand: 'Toyota Corolla',
      officerId: 'OFF002',
      officerName: 'Marie-Claire Ngoma',
      officerBadge: 'PPN-2893',
      infractionCode: 'TEL-1',
      infractionLabel: 'Utilisation du téléphone au volant',
      amount: 20000,
      pointsDeducted: 2,
      status: FineStatus.paid,
      issuedAt: DateTime.now().subtract(const Duration(days: 45)),
      deadline: DateTime.now().subtract(const Duration(days: 15)),
      location: 'Boulevard Denis Sassou Nguesso, Brazzaville',
      latitude: -4.2767,
      longitude: 15.2589,
      paymentId: null,
      paymentRef: 'MTN-2024-78923',
      paidAt: DateTime.now().subtract(const Duration(days: 30)),
      paymentMethod: 'MTN Mobile Money',
    ),
    FineModel(
      id: 'FIN003',
      reference: 'CP-2024-000892',
      driverId: 'DRV001',
      driverName: 'Thierry Nguesso',
      vehiclePlate: 'BZV-4521-A',
      vehicleBrand: 'Toyota Corolla',
      officerId: 'OFF003',
      officerName: 'Gabriel Loemba',
      officerBadge: 'PNB-1102',
      infractionCode: 'CEI-1',
      infractionLabel: 'Non-port de la ceinture de sécurité',
      amount: 10000,
      pointsDeducted: 1,
      status: FineStatus.overdue,
      issuedAt: DateTime.now().subtract(const Duration(days: 75)),
      deadline: DateTime.now().subtract(const Duration(days: 45)),
      location: 'Rue Makotipoko, Brazzaville',
      latitude: -4.2891,
      longitude: 15.2312,
      paymentId: null,
    ),
    FineModel(
      id: 'FIN004',
      reference: 'CP-2024-002341',
      driverId: 'DRV002',
      driverName: 'Cédric Okemba',
      vehiclePlate: 'PNR-1123-B',
      vehicleBrand: 'Honda CB 125',
      officerId: 'OFF001',
      officerName: 'Jean-Pierre Moukala',
      officerBadge: 'PNB-4521',
      infractionCode: 'CAS-1',
      infractionLabel: 'Circulation sans casque (moto)',
      amount: 5000,
      pointsDeducted: 1,
      status: FineStatus.pending,
      issuedAt: DateTime.now().subtract(const Duration(days: 2)),
      deadline: DateTime.now().add(const Duration(days: 28)),
      location: 'Rond-point Moungali, Brazzaville',
      latitude: -4.2456,
      longitude: 15.2687,
      paymentId: null,
    ),
  ];
}
