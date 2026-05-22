/// NOTE : Le système de retrait de points n'existe pas en République du Congo.
/// Le champ [pointsDeducted] est conservé à 0 pour compatibilité avec la base
/// de données ; il n'est JAMAIS affiché dans l'interface.
enum InfractionCategory { speed, safety, documents, parking, behavior }

class InfractionType {
  final String id;
  final String code;
  final String labelFr;
  final String labelEn;
  final int fineAmount;       // Montant en XAF
  final int pointsDeducted;   // Toujours 0 au Congo — non affiché
  final InfractionCategory category;
  final String icon;

  const InfractionType({
    required this.id,
    required this.code,
    required this.labelFr,
    required this.labelEn,
    required this.fineAmount,
    this.pointsDeducted = 0,  // Valeur par défaut : 0
    required this.category,
    required this.icon,
  });

  static const List<InfractionType> all = [
    // ── Vitesse ────────────────────────────────────────────────────────────
    InfractionType(
      id: 'INF001', code: 'EXV-1',
      labelFr: 'Excès de vitesse (< 20 km/h)',
      labelEn: 'Speeding < 20 km/h',
      fineAmount: 15000, category: InfractionCategory.speed, icon: '🚗',
    ),
    InfractionType(
      id: 'INF002', code: 'EXV-2',
      labelFr: 'Excès de vitesse (20–40 km/h)',
      labelEn: 'Speeding 20–40 km/h',
      fineAmount: 30000, category: InfractionCategory.speed, icon: '🚗',
    ),
    InfractionType(
      id: 'INF003', code: 'EXV-3',
      labelFr: 'Excès de vitesse (> 40 km/h)',
      labelEn: 'Speeding > 40 km/h',
      fineAmount: 60000, category: InfractionCategory.speed, icon: '🚗',
    ),

    // ── Comportement ───────────────────────────────────────────────────────
    InfractionType(
      id: 'INF005', code: 'FEU-1',
      labelFr: 'Non-respect du feu rouge',
      labelEn: 'Red light violation',
      fineAmount: 20000, category: InfractionCategory.behavior, icon: '🚦',
    ),
    InfractionType(
      id: 'INF009', code: 'TEL-1',
      labelFr: 'Utilisation du téléphone au volant',
      labelEn: 'Phone use while driving',
      fineAmount: 20000, category: InfractionCategory.behavior, icon: '📱',
    ),
    InfractionType(
      id: 'INF013', code: 'PRI-1',
      labelFr: 'Non-respect de la priorité',
      labelEn: 'Failure to yield',
      fineAmount: 15000, category: InfractionCategory.behavior, icon: '⛔',
    ),
    InfractionType(
      id: 'INF014', code: 'CTR-1',
      labelFr: 'Demi-tour interdit',
      labelEn: 'Illegal U-turn',
      fineAmount: 10000, category: InfractionCategory.behavior, icon: '↩️',
    ),

    // ── Sécurité ───────────────────────────────────────────────────────────
    InfractionType(
      id: 'INF004', code: 'CAS-1',
      labelFr: 'Circulation sans casque (moto)',
      labelEn: 'No helmet (motorcycle)',
      fineAmount: 5000, category: InfractionCategory.safety, icon: '🏍️',
    ),
    InfractionType(
      id: 'INF006', code: 'CEI-1',
      labelFr: 'Non-port de la ceinture de sécurité',
      labelEn: 'No seatbelt',
      fineAmount: 10000, category: InfractionCategory.safety, icon: '🔒',
    ),
    InfractionType(
      id: 'INF012', code: 'SUR-1',
      labelFr: 'Surcharge du véhicule',
      labelEn: 'Vehicle overload',
      fineAmount: 40000, category: InfractionCategory.safety, icon: '⚖️',
    ),
    InfractionType(
      id: 'INF015', code: 'FEU-V-1',
      labelFr: 'Feux défectueux / absents',
      labelEn: 'Defective/missing lights',
      fineAmount: 10000, category: InfractionCategory.safety, icon: '💡',
    ),

    // ── Documents ──────────────────────────────────────────────────────────
    InfractionType(
      id: 'INF007', code: 'PER-1',
      labelFr: 'Conduite sans permis valide',
      labelEn: 'No valid driver\'s licence',
      fineAmount: 50000, category: InfractionCategory.documents, icon: '🪪',
    ),
    InfractionType(
      id: 'INF016', code: 'PER-2',
      labelFr: 'Défaut de présentation du permis',
      labelEn: 'Failure to present licence',
      fineAmount: 25000, category: InfractionCategory.documents, icon: '🪪',
    ),
    InfractionType(
      id: 'INF008', code: 'CGR-1',
      labelFr: 'Défaut de carte grise',
      labelEn: 'No vehicle registration card',
      fineAmount: 20000, category: InfractionCategory.documents, icon: '📋',
    ),
    InfractionType(
      id: 'INF011', code: 'ASS-1',
      labelFr: 'Défaut d\'assurance',
      labelEn: 'No insurance certificate',
      fineAmount: 30000, category: InfractionCategory.documents, icon: '🛡️',
    ),
    InfractionType(
      id: 'INF017', code: 'CTN-1',
      labelFr: 'Défaut de contrôle technique',
      labelEn: 'No technical inspection',
      fineAmount: 25000, category: InfractionCategory.documents, icon: '🔧',
    ),

    // ── Stationnement ──────────────────────────────────────────────────────
    InfractionType(
      id: 'INF010', code: 'STA-1',
      labelFr: 'Stationnement interdit / gênant',
      labelEn: 'Illegal/obstructive parking',
      fineAmount: 5000, category: InfractionCategory.parking, icon: '🅿️',
    ),
    InfractionType(
      id: 'INF018', code: 'STA-2',
      labelFr: 'Stationnement sur voie de bus / urgence',
      labelEn: 'Parking on bus/emergency lane',
      fineAmount: 10000, category: InfractionCategory.parking, icon: '🚌',
    ),
  ];
}
