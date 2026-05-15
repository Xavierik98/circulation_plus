enum InfractionCategory { speed, safety, documents, parking, behavior }

class InfractionType {
  final String id;
  final String code;
  final String labelFr;
  final String labelEn;
  final int fineAmount;
  final int pointsDeducted;
  final InfractionCategory category;
  final String icon;

  const InfractionType({
    required this.id,
    required this.code,
    required this.labelFr,
    required this.labelEn,
    required this.fineAmount,
    required this.pointsDeducted,
    required this.category,
    required this.icon,
  });

  static const List<InfractionType> all = [
    InfractionType(
      id: 'INF001',
      code: 'EXV-1',
      labelFr: 'Excès de vitesse < 20 km/h',
      labelEn: 'Speeding < 20 km/h',
      fineAmount: 15000,
      pointsDeducted: 1,
      category: InfractionCategory.speed,
      icon: '🚗',
    ),
    InfractionType(
      id: 'INF002',
      code: 'EXV-2',
      labelFr: 'Excès de vitesse 20–40 km/h',
      labelEn: 'Speeding 20–40 km/h',
      fineAmount: 30000,
      pointsDeducted: 2,
      category: InfractionCategory.speed,
      icon: '🚗',
    ),
    InfractionType(
      id: 'INF003',
      code: 'EXV-3',
      labelFr: 'Excès de vitesse > 40 km/h',
      labelEn: 'Speeding > 40 km/h',
      fineAmount: 60000,
      pointsDeducted: 4,
      category: InfractionCategory.speed,
      icon: '🚗',
    ),
    InfractionType(
      id: 'INF004',
      code: 'CAS-1',
      labelFr: 'Circulation sans casque (moto)',
      labelEn: 'No helmet (motorcycle)',
      fineAmount: 5000,
      pointsDeducted: 1,
      category: InfractionCategory.safety,
      icon: '🏍️',
    ),
    InfractionType(
      id: 'INF005',
      code: 'FEU-1',
      labelFr: 'Non-respect feu rouge',
      labelEn: 'Red light violation',
      fineAmount: 20000,
      pointsDeducted: 2,
      category: InfractionCategory.behavior,
      icon: '🚦',
    ),
    InfractionType(
      id: 'INF006',
      code: 'CEI-1',
      labelFr: 'Non-port de la ceinture de sécurité',
      labelEn: 'No seatbelt',
      fineAmount: 10000,
      pointsDeducted: 1,
      category: InfractionCategory.safety,
      icon: '🔒',
    ),
    InfractionType(
      id: 'INF007',
      code: 'PER-1',
      labelFr: 'Conduite sans permis valide',
      labelEn: 'No valid driver license',
      fineAmount: 25000,
      pointsDeducted: 3,
      category: InfractionCategory.documents,
      icon: '📄',
    ),
    InfractionType(
      id: 'INF008',
      code: 'CGR-1',
      labelFr: 'Défaut de carte grise',
      labelEn: 'No vehicle registration',
      fineAmount: 15000,
      pointsDeducted: 1,
      category: InfractionCategory.documents,
      icon: '📋',
    ),
    InfractionType(
      id: 'INF009',
      code: 'TEL-1',
      labelFr: 'Utilisation du téléphone au volant',
      labelEn: 'Phone use while driving',
      fineAmount: 20000,
      pointsDeducted: 2,
      category: InfractionCategory.behavior,
      icon: '📱',
    ),
    InfractionType(
      id: 'INF010',
      code: 'STA-1',
      labelFr: 'Stationnement interdit / gênant',
      labelEn: 'Illegal parking',
      fineAmount: 5000,
      pointsDeducted: 0,
      category: InfractionCategory.parking,
      icon: '🅿️',
    ),
    InfractionType(
      id: 'INF011',
      code: 'ASS-1',
      labelFr: 'Défaut d\'assurance',
      labelEn: 'No insurance',
      fineAmount: 30000,
      pointsDeducted: 2,
      category: InfractionCategory.documents,
      icon: '🛡️',
    ),
    InfractionType(
      id: 'INF012',
      code: 'SUR-1',
      labelFr: 'Surcharge du véhicule',
      labelEn: 'Vehicle overload',
      fineAmount: 40000,
      pointsDeducted: 2,
      category: InfractionCategory.safety,
      icon: '⚖️',
    ),
  ];
}
