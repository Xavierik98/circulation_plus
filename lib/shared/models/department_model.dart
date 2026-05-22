/// 12 départements officiels de la République du Congo (Congo-Brazzaville).
enum CongoDepartement {
  brazzaville,
  pointeNoire,
  bouenza,
  cuvette,
  cuvetteOuest,
  kouilou,
  lekoumou,
  likouala,
  niari,
  plateaux,
  pool,
  sangha,
}

extension CongoDepartementX on CongoDepartement {
  String get label => switch (this) {
        CongoDepartement.brazzaville   => 'Brazzaville',
        CongoDepartement.pointeNoire   => 'Pointe-Noire',
        CongoDepartement.bouenza       => 'Bouenza',
        CongoDepartement.cuvette       => 'Cuvette',
        CongoDepartement.cuvetteOuest  => 'Cuvette-Ouest',
        CongoDepartement.kouilou       => 'Kouilou',
        CongoDepartement.lekoumou      => 'Lékoumou',
        CongoDepartement.likouala      => 'Likouala',
        CongoDepartement.niari         => 'Niari',
        CongoDepartement.plateaux      => 'Plateaux',
        CongoDepartement.pool          => 'Pool',
        CongoDepartement.sangha        => 'Sangha',
      };

  String get capital => switch (this) {
        CongoDepartement.brazzaville   => 'Brazzaville',
        CongoDepartement.pointeNoire   => 'Pointe-Noire',
        CongoDepartement.bouenza       => 'Madingou',
        CongoDepartement.cuvette       => 'Owando',
        CongoDepartement.cuvetteOuest  => 'Ewo',
        CongoDepartement.kouilou       => 'Loubomo',
        CongoDepartement.lekoumou      => 'Sibiti',
        CongoDepartement.likouala      => 'Impfondo',
        CongoDepartement.niari         => 'Dolisie',
        CongoDepartement.plateaux      => 'Djambala',
        CongoDepartement.pool          => 'Kinkala',
        CongoDepartement.sangha        => 'Ouesso',
      };

  /// Préfixe d'immatriculation (3 lettres).
  String get platePrefix => switch (this) {
        CongoDepartement.brazzaville   => 'BZV',
        CongoDepartement.pointeNoire   => 'PNR',
        CongoDepartement.bouenza       => 'BOZ',
        CongoDepartement.cuvette       => 'CUV',
        CongoDepartement.cuvetteOuest  => 'CUO',
        CongoDepartement.kouilou       => 'KOU',
        CongoDepartement.lekoumou      => 'LEK',
        CongoDepartement.likouala      => 'LIK',
        CongoDepartement.niari         => 'NIA',
        CongoDepartement.plateaux      => 'PLA',
        CongoDepartement.pool          => 'POL',
        CongoDepartement.sangha        => 'SAN',
      };

  /// Détecte le département depuis le préfixe de plaque (ex: "BZV-4521-A").
  static CongoDepartement? fromPlate(String plate) {
    final upper = plate.toUpperCase().replaceAll(RegExp(r'[\s\-_]'), '');
    for (final dept in CongoDepartement.values) {
      if (upper.startsWith(dept.platePrefix)) return dept;
    }
    return null;
  }
}

/// Quartiers et axes de circulation par département / ville.
/// Utilisé comme suggestions dans le formulaire lieu d'infraction.
const Map<CongoDepartement, List<String>> lieuxParDepartement = {
  // ── Brazzaville ────────────────────────────────────────────────────────────
  CongoDepartement.brazzaville: [
    // Arrondissements & quartiers
    'Bacongo',
    'Makélékélé',
    'Poto-Poto',
    'Moungali',
    'Ouenzé',
    'Talangaï',
    'Mfilou',
    'Madibou',
    'Djiri',
    'Plateau (Centre-ville)',
    // Axes principaux
    'Boulevard Denis Sassou Nguesso',
    'Avenue de France',
    'Avenue des 3 Martyrs',
    'Rond-point de la Démocratie',
    'Rond-point Poto-Poto',
    'Carrefour Moungali',
    'Pont du Djoué',
    'Route de Brazzaville-Sud (RN1)',
    'Aéroport Maya-Maya',
  ],

  // ── Pointe-Noire ───────────────────────────────────────────────────────────
  CongoDepartement.pointeNoire: [
    // Arrondissements & quartiers
    'Loandjili',
    'Mvou-Mvou',
    'Tié-Tié',
    'Ngoyo',
    'Zone 1 (Centre-ville)',
    'Mongo-Mpoukou',
    'Mvoumvou',
    'Vindou',
    'Fouks',
    'OCH (Cité Natchiboua)',
    // Axes principaux
    'Avenue Charles de Gaulle',
    'Boulevard Marien Ngouabi',
    'Rond-point Lumumba',
    'Route de l\'Aéroport Agostinho Neto',
    'Port autonome de Pointe-Noire',
    'Carrefour Tchiamba-Nzassi',
  ],

  // ── Bouenza ────────────────────────────────────────────────────────────────
  CongoDepartement.bouenza: [
    'Madingou (chef-lieu)',
    'Nkayi',
    'Loudima',
    'Mfouati',
    'Mouyondzi',
    'Kimongo',
    'Route nationale 1 (RN1) — tronçon Bouenza',
    'Carrefour Loudima',
  ],

  // ── Cuvette ────────────────────────────────────────────────────────────────
  CongoDepartement.cuvette: [
    'Owando (chef-lieu)',
    'Makoua',
    'Boundji',
    'Oyo',
    'Tchikapika',
    'Mossaka',
    'Loukolela',
    'Route nationale 2 (RN2)',
    'Carrefour Makoua',
  ],

  // ── Cuvette-Ouest ──────────────────────────────────────────────────────────
  CongoDepartement.cuvetteOuest: [
    'Ewo (chef-lieu)',
    'Kelle',
    'Mbama',
    'Ngo',
    'Route nationale 2 (RN2) — tronçon Cuvette-Ouest',
  ],

  // ── Kouilou ────────────────────────────────────────────────────────────────
  CongoDepartement.kouilou: [
    'Loubomo',
    'Hinda',
    'Kakamoeka',
    'Mvouti',
    'Tchiamba-Nzassi',
    'Route côtière',
    'Route nationale 1 (RN1) — tronçon Kouilou',
  ],

  // ── Lékoumou ───────────────────────────────────────────────────────────────
  CongoDepartement.lekoumou: [
    'Sibiti (chef-lieu)',
    'Komono',
    'Zanaga',
    'Bambama',
    'Route nationale 1 (RN1) — tronçon Lékoumou',
  ],

  // ── Likouala ───────────────────────────────────────────────────────────────
  CongoDepartement.likouala: [
    'Impfondo (chef-lieu)',
    'Dongou',
    'Epéna',
    'Enyellé',
    'Betou',
    'Route nationale 4 (RN4)',
  ],

  // ── Niari ──────────────────────────────────────────────────────────────────
  CongoDepartement.niari: [
    'Dolisie (chef-lieu)',
    'Mossendjo',
    'Kibangou',
    'Louvakou',
    'Makabana',
    'Ndindi',
    'Route nationale 1 (RN1) — tronçon Niari',
    'Carrefour Dolisie',
    'Gare ferroviaire de Dolisie',
  ],

  // ── Plateaux ───────────────────────────────────────────────────────────────
  CongoDepartement.plateaux: [
    'Djambala (chef-lieu)',
    'Gamboma',
    'Abala',
    'Lékana',
    'Ngo',
    'Route nationale 2 (RN2) — tronçon Plateaux',
  ],

  // ── Pool ───────────────────────────────────────────────────────────────────
  CongoDepartement.pool: [
    'Kinkala (chef-lieu)',
    'Boko',
    'Mindouli',
    'Kindamba',
    'Mayama',
    'Ngabe',
    'Route nationale 1 (RN1) — tronçon Pool',
    'Carrefour Kinkala',
  ],

  // ── Sangha ─────────────────────────────────────────────────────────────────
  CongoDepartement.sangha: [
    'Ouesso (chef-lieu)',
    'Pokola',
    'Souanké',
    'Sembe',
    'Ngbala',
    'Route nationale 3 (RN3)',
  ],
};
