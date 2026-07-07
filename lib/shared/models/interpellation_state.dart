import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'infraction_model.dart';
import 'department_model.dart';

/// Documents pouvant être saisis en cas de refus de signature.
enum DocumentSaisi {
  permisConduire,
  carteGrise,
  carteIdentite,
  certificatAssurance,
  controleTechnique,
}

extension DocumentSaisiX on DocumentSaisi {
  String get label => switch (this) {
        DocumentSaisi.permisConduire       => 'Permis de conduire',
        DocumentSaisi.carteGrise           => 'Carte grise',
        DocumentSaisi.carteIdentite        => 'Carte d\'identité',
        DocumentSaisi.certificatAssurance  => 'Certificat d\'assurance',
        DocumentSaisi.controleTechnique    => 'Contrôle technique',
      };

  String get icon => switch (this) {
        DocumentSaisi.permisConduire       => '🪪',
        DocumentSaisi.carteGrise           => '📋',
        DocumentSaisi.carteIdentite        => '🪪',
        DocumentSaisi.certificatAssurance  => '🛡️',
        DocumentSaisi.controleTechnique    => '🔧',
      };
}

/// État complet d'une interpellation en cours.
/// Partagé entre toutes les étapes du flux (étapes 1 → 6).
class InterpellationState {
  // ── Conducteur ────────────────────────────────────────────
  final String driverName;
  final String driverLicense;
  final bool hasLicense;        // false = défaut de permis
  final String driverPhone;

  // ── Véhicule ──────────────────────────────────────────────
  final String vehiclePlate;
  final String vehicleBrand;
  final String vehicleModel;
  final String vehicleColor;
  final bool hasCarteGrise;
  final bool hasControleTechnique;
  final bool hasAssurance;

  // ── Lieu ──────────────────────────────────────────────────
  final CongoDepartement? departement;
  final String lieuPrecis;      // Rue / carrefour / axe
  final double? gpsLat;
  final double? gpsLng;

  // ── Infractions ───────────────────────────────────────────
  final List<InfractionType> selectedInfractions;

  // ── Scan image ────────────────────────────────────────────
  /// Chemin local vers la photo du document scanné (permis / carte grise).
  final String? scanImagePath;

  // ── Signature ─────────────────────────────────────────────
  final bool signatureRefused;
  final List<DocumentSaisi> documentsSeizes;

  const InterpellationState({
    this.driverName = '',
    this.driverLicense = '',
    this.hasLicense = true,
    this.driverPhone = '',
    this.vehiclePlate = '',
    this.vehicleBrand = '',
    this.vehicleModel = '',
    this.vehicleColor = '',
    this.hasCarteGrise = true,
    this.hasControleTechnique = true,
    this.hasAssurance = true,
    this.departement,
    this.lieuPrecis = '',
    this.gpsLat,
    this.gpsLng,
    this.selectedInfractions = const [],
    this.scanImagePath,
    this.signatureRefused = false,
    this.documentsSeizes = const [],
  });

  InterpellationState copyWith({
    String? driverName,
    String? driverLicense,
    bool? hasLicense,
    String? driverPhone,
    String? vehiclePlate,
    String? vehicleBrand,
    String? vehicleModel,
    String? vehicleColor,
    bool? hasCarteGrise,
    bool? hasControleTechnique,
    bool? hasAssurance,
    CongoDepartement? departement,
    String? lieuPrecis,
    double? gpsLat,
    double? gpsLng,
    List<InfractionType>? selectedInfractions,
    String? scanImagePath,
    bool? signatureRefused,
    List<DocumentSaisi>? documentsSeizes,
  }) {
    return InterpellationState(
      driverName: driverName ?? this.driverName,
      driverLicense: driverLicense ?? this.driverLicense,
      hasLicense: hasLicense ?? this.hasLicense,
      driverPhone: driverPhone ?? this.driverPhone,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      hasCarteGrise: hasCarteGrise ?? this.hasCarteGrise,
      hasControleTechnique: hasControleTechnique ?? this.hasControleTechnique,
      hasAssurance: hasAssurance ?? this.hasAssurance,
      departement: departement ?? this.departement,
      lieuPrecis: lieuPrecis ?? this.lieuPrecis,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLng: gpsLng ?? this.gpsLng,
      selectedInfractions: selectedInfractions ?? this.selectedInfractions,
      scanImagePath: scanImagePath ?? this.scanImagePath,
      signatureRefused: signatureRefused ?? this.signatureRefused,
      documentsSeizes: documentsSeizes ?? this.documentsSeizes,
    );
  }

  /// Montant de base (somme des amendes sélectionnées).
  int get baseAmount =>
      selectedInfractions.fold(0, (sum, i) => sum + i.fineAmount);

  /// Montant total (base + 1 000 XAF frais plateforme).
  int get totalAmount => baseAmount + 1000;

  /// Référence PV générée dynamiquement.
  String get reference {
    final ms = DateTime.now().millisecondsSinceEpoch % 1000000;
    return 'PV-${DateTime.now().year}-${ms.toString().padLeft(6, '0')}';
  }

  /// Retourne true si des infractions documentaires manquantes sont détectées
  /// et qu'il faut notifier le citoyen concerné.
  bool get hasDocumentAlert =>
      !hasLicense || !hasCarteGrise || !hasAssurance || !hasControleTechnique;

  /// Résume les documents manquants (pour la notification).
  List<String> get missingDocuments => [
        if (!hasLicense) 'Permis de conduire',
        if (!hasCarteGrise) 'Carte grise',
        if (!hasAssurance) 'Assurance',
        if (!hasControleTechnique) 'Contrôle technique',
      ];
}

// ── Provider global ──────────────────────────────────────────────────────────

class InterpellationNotifier extends StateNotifier<InterpellationState> {
  InterpellationNotifier() : super(const InterpellationState());

  // Verrou de soumission — protège contre une double création de PV si deux
  // instances de l'écran de confirmation venaient à être montées en même
  // temps (ex: double-tap sur "Valider l'interpellation" malgré la garde
  // côté écran de signature). Partagé car le provider est un singleton.
  bool _submitLock = false;

  /// Tente d'acquérir le verrou de soumission. Renvoie false si une
  /// soumission est déjà en cours — l'appelant doit alors abandonner
  /// silencieusement plutôt que d'envoyer une deuxième requête.
  bool tryAcquireSubmitLock() {
    if (_submitLock) return false;
    _submitLock = true;
    return true;
  }

  void releaseSubmitLock() {
    _submitLock = false;
  }

  void updateDriver({
    String? name,
    String? license,
    bool? hasLicense,
    String? phone,
  }) {
    state = state.copyWith(
      driverName: name,
      driverLicense: license,
      hasLicense: hasLicense,
      driverPhone: phone,
    );
  }

  void updateVehicle({
    String? plate,
    String? brand,
    String? model,
    String? color,
    bool? hasCarteGrise,
    bool? hasControleTechnique,
    bool? hasAssurance,
  }) {
    state = state.copyWith(
      vehiclePlate: plate,
      vehicleBrand: brand,
      vehicleModel: model,
      vehicleColor: color,
      hasCarteGrise: hasCarteGrise,
      hasControleTechnique: hasControleTechnique,
      hasAssurance: hasAssurance,
    );
    // Détection automatique du département via la plaque
    if (plate != null && plate.isNotEmpty) {
      final dept = CongoDepartementX.fromPlate(plate);
      if (dept != null) {
        state = state.copyWith(departement: dept);
      }
    }
  }

  void updateLocation({
    CongoDepartement? departement,
    String? lieuPrecis,
    double? gpsLat,
    double? gpsLng,
  }) {
    state = state.copyWith(
      departement: departement,
      lieuPrecis: lieuPrecis,
      gpsLat: gpsLat,
      gpsLng: gpsLng,
    );
  }

  void setInfractions(List<InfractionType> infractions) {
    state = state.copyWith(selectedInfractions: infractions);
  }

  void setScanImage(String? path) {
    state = state.copyWith(scanImagePath: path);
  }

  void setSignatureRefused({
    required bool refused,
    List<DocumentSaisi>? documentsSeizes,
  }) {
    state = state.copyWith(
      signatureRefused: refused,
      documentsSeizes: documentsSeizes ?? [],
    );
  }

  /// Réinitialise entièrement pour une nouvelle interpellation.
  void reset() {
    state = const InterpellationState();
  }
}

final interpellationProvider =
    StateNotifierProvider<InterpellationNotifier, InterpellationState>(
  (_) => InterpellationNotifier(),
);
