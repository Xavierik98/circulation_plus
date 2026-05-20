import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const PIN_ROUNDS = 12;

// ─────────────────────────────────────────────────────────────────────────────
// Catalogue officiel — Code de la route, République du Congo-Brazzaville
// Source : https://ekolo242.cg/securite/routieres/liste-des-infractions-et-amendes-relatives-au-code-de-la-route-au-congo/
// Montants en XAF (montantBase = amende officielle ; le +1 000 FCFA de frais
// plateforme est ajouté automatiquement par fines.service.ts au moment de la
// création de la contravention).
// ─────────────────────────────────────────────────────────────────────────────
const INFRACTIONS = [
  // ── ÉQUIPEMENT DU VÉHICULE ──────────────────────────────────────────────
  { code: 'EQP-001', libelle: 'Absence ou défectuosité des feux arrière brouillard',       montantBase: 24000, convocationObligatoire: false },
  { code: 'EQP-002', libelle: 'Feux brouillard non réglementaires',                        montantBase: 24000, convocationObligatoire: false },
  { code: 'EQP-003', libelle: 'Feux de croisement défaillants ou éblouissants',            montantBase: 24000, convocationObligatoire: false },
  { code: 'EQP-004', libelle: 'Feux indicateurs de direction non fonctionnels',            montantBase: 12000, convocationObligatoire: false },
  { code: 'EQP-005', libelle: 'Défaut de dispositif de marche arrière',                    montantBase: 24000, convocationObligatoire: true  },
  { code: 'EQP-006', libelle: 'Absence de feux de position',                               montantBase: 24000, convocationObligatoire: true  },
  { code: 'EQP-007', libelle: 'Installation d\'un feu spécial illégal',                   montantBase: 24000, convocationObligatoire: false },
  { code: 'EQP-008', libelle: 'Absence de feux stop',                                      montantBase: 24000, convocationObligatoire: false },
  { code: 'EQP-009', libelle: 'Pare-brise sans lave-glace',                                montantBase: 12000, convocationObligatoire: false },
  { code: 'EQP-010', libelle: 'Défaut de rétroviseur',                                     montantBase: 12000, convocationObligatoire: false },
  { code: 'EQP-011', libelle: 'Plaque d\'immatriculation absente',                        montantBase: 12000, convocationObligatoire: false },
  { code: 'EQP-012', libelle: 'Pneumatiques de structures différentes sur le même essieu', montantBase: 12000, convocationObligatoire: false },
  { code: 'EQP-013', libelle: 'Absence de triangle de pré-signalisation',                  montantBase: 12000, convocationObligatoire: false },
  { code: 'EQP-014', libelle: 'Défaut d\'avertisseur sonore',                             montantBase: 12000, convocationObligatoire: false },
  { code: 'EQP-015', libelle: 'Défectuosité des essuie-glaces',                            montantBase: 12000, convocationObligatoire: false },
  { code: 'EQP-016', libelle: 'Défectuosité des catadioptres',                             montantBase: 12000, convocationObligatoire: false },
  { code: 'EQP-017', libelle: 'Non-port du casque homologué (deux-roues)',                 montantBase: 24000, convocationObligatoire: false },
  { code: 'EQP-018', libelle: 'Plaques d\'immatriculation défectueuses',                  montantBase: 12000, convocationObligatoire: false },
  { code: 'EQP-019', libelle: 'Plaque spéciale non conforme',                              montantBase: 12000, convocationObligatoire: false },
  { code: 'EQP-020', libelle: 'Défaut d\'indication auto-école',                          montantBase: 12000, convocationObligatoire: false },
  { code: 'EQP-021', libelle: 'Défaut de roue de secours',                                 montantBase: 12000, convocationObligatoire: false },
  { code: 'EQP-022', libelle: 'Défaut de pare-brise',                                      montantBase: 12000, convocationObligatoire: false },
  { code: 'EQP-023', libelle: 'Défaut de boîte à pharmacie',                               montantBase: 12000, convocationObligatoire: false },
  { code: 'EQP-024', libelle: 'Défaut d\'extincteur',                                     montantBase: 12000, convocationObligatoire: false },
  { code: 'EQP-025', libelle: 'Défaut de ceinture de sécurité',                            montantBase: 12000, convocationObligatoire: false },
  { code: 'EQP-026', libelle: 'Plaques spéciales (TV/TVM/TM/TPP) défectueuses',           montantBase: 12000, convocationObligatoire: false },

  // ── PIÈCES ADMINISTRATIVES ───────────────────────────────────────────────
  { code: 'DOC-001', libelle: 'Non-présentation de l\'attestation d\'assurance',          montantBase: 24000, convocationObligatoire: false },
  { code: 'DOC-002', libelle: 'Non-apposition du certificat d\'assurance',                montantBase: 24000, convocationObligatoire: false },
  { code: 'DOC-003', libelle: 'Certificat d\'assurance périmé (plus d\'un mois)',         montantBase: 24000, convocationObligatoire: false },
  { code: 'DOC-004', libelle: 'Défaut de catégorie d\'assurance',                         montantBase: 24000, convocationObligatoire: false },
  { code: 'DOC-005', libelle: 'Défaut de droit de stationnement',                          montantBase: 12000, convocationObligatoire: false },
  { code: 'DOC-006', libelle: 'Non-présentation de l\'autorisation auto-école',           montantBase: 24000, convocationObligatoire: false },
  { code: 'DOC-007', libelle: 'Non-présentation de la carte grise ou du récépissé',       montantBase: 24000, convocationObligatoire: false },
  { code: 'DOC-008', libelle: 'Maintien en circulation sans nouvelle immatriculation',     montantBase: 24000, convocationObligatoire: false },
  { code: 'DOC-009', libelle: 'Défaut de certificat médical (transport en commun)',        montantBase: 12000, convocationObligatoire: false },
  { code: 'DOC-010', libelle: 'Défaut de taxe de roulage',                                 montantBase: 12000, convocationObligatoire: false },
  { code: 'DOC-011', libelle: 'Conduite sans permis valide',                               montantBase: 24000, convocationObligatoire: true  },
  { code: 'DOC-012', libelle: 'Maintien en circulation après retrait de la carte grise',  montantBase: 24000, convocationObligatoire: false },
  { code: 'DOC-013', libelle: 'Mise en circulation sans carte grise',                      montantBase: 24000, convocationObligatoire: false },
  { code: 'DOC-014', libelle: 'Non-présentation du permis de conduire',                    montantBase: 24000, convocationObligatoire: false },
  { code: 'DOC-015', libelle: 'Usage abusif de la carte grise W',                          montantBase: 24000, convocationObligatoire: false },
  { code: 'DOC-016', libelle: 'Usage abusif de la carte grise WW',                         montantBase: 24000, convocationObligatoire: false },
  { code: 'DOC-017', libelle: 'Défaut de contrôle technique',                              montantBase: 24000, convocationObligatoire: true  },
  { code: 'DOC-018', libelle: 'Défaut de catégorie au contrôle technique',                 montantBase: 24000, convocationObligatoire: false },
  { code: 'DOC-019', libelle: 'Refus de présentation des documents de bord',               montantBase: 12000, convocationObligatoire: false },
  { code: 'DOC-020', libelle: 'Défaut de catégorie de permis de conduire',                 montantBase: 24000, convocationObligatoire: false },
  { code: 'DOC-021', libelle: 'Non-présentation de l\'autorisation de transport public',  montantBase: 12000, convocationObligatoire: false },

  // ── MOTOCYCLES ───────────────────────────────────────────────────────────
  { code: 'MTO-001', libelle: 'Non-port du casque (conducteur ou passager moto)',          montantBase:  6000, convocationObligatoire: false },
  { code: 'MTO-002', libelle: 'Chargement mal arrimé (moto)',                              montantBase:  6000, convocationObligatoire: false },
  { code: 'MTO-003', libelle: 'Circulation à contresens (moto)',                           montantBase:  6000, convocationObligatoire: false },
  { code: 'MTO-004', libelle: 'Conducteur de moto de moins de 16 ans',                    montantBase:  6000, convocationObligatoire: true  },
  { code: 'MTO-005', libelle: 'Défaut de feu de position la nuit ou par mauvaise visibilité (moto)', montantBase: 12000, convocationObligatoire: false },
  { code: 'MTO-006', libelle: 'Défaut total d\'éclairage (moto)',                          montantBase: 12000, convocationObligatoire: false },
  { code: 'MTO-007', libelle: 'Transport de passager en position amazone',                 montantBase:  6000, convocationObligatoire: false },
  { code: 'MTO-008', libelle: 'Transport d\'enfant de moins de 5 ans sans siège adapté',  montantBase:  6000, convocationObligatoire: false },

  // ── DÉPANNAGE / REMORQUAGE ───────────────────────────────────────────────
  { code: 'DEP-001', libelle: 'Feux spéciaux utilisés hors des cas légaux',                montantBase: 24000, convocationObligatoire: false },
  { code: 'DEP-002', libelle: 'Absence de gilets fluorescents pour le personnel',          montantBase: 12000, convocationObligatoire: false },
  { code: 'DEP-003', libelle: 'Non-respect des règles de remorquage',                      montantBase: 12000, convocationObligatoire: false },
  { code: 'DEP-004', libelle: 'Remorquage sans autorisation préfectorale',                 montantBase: 24000, convocationObligatoire: false },
  { code: 'DEP-005', libelle: 'Remorquage sans l\'équipement exigé',                      montantBase: 24000, convocationObligatoire: false },

  // ── TRANSPORT EN COMMUN ──────────────────────────────────────────────────
  { code: 'TPC-001', libelle: 'Non-présentation de l\'autorisation de transport public',  montantBase: 24000, convocationObligatoire: false },
  { code: 'TPC-002', libelle: 'Excès de passagers',                                        montantBase: 12000, convocationObligatoire: false },
  { code: 'TPC-003', libelle: 'Garanties de sécurité insuffisantes',                       montantBase: 12000, convocationObligatoire: false },
  { code: 'TPC-004', libelle: 'Remorque affectée au transport en commun (interdite)',      montantBase: 12000, convocationObligatoire: false },
  { code: 'TPC-005', libelle: 'Transport de passagers debout dans les autocars',           montantBase: 12000, convocationObligatoire: false },
  { code: 'TPC-006', libelle: 'Défaut de mesures de commodité/sécurité avant départ',     montantBase: 12000, convocationObligatoire: false },
  { code: 'TPC-007', libelle: 'Transport de matières dangereuses avec voyageurs',          montantBase: 12000, convocationObligatoire: true  },
  { code: 'TPC-008', libelle: 'Transport de voyageurs sur camions-bennes ou remorques',    montantBase: 12000, convocationObligatoire: false },
  { code: 'TPC-009', libelle: 'Absence de roue ou jante de secours (transport commun)',    montantBase: 12000, convocationObligatoire: false },

  // ── COMPORTEMENT AU VOLANT ───────────────────────────────────────────────
  { code: 'COM-001', libelle: 'Non-respect d\'un feu rouge',                              montantBase: 20000, convocationObligatoire: false },
  { code: 'COM-002', libelle: 'Utilisation du téléphone au volant',                        montantBase: 20000, convocationObligatoire: false },
  { code: 'COM-003', libelle: 'Conduite en état d\'ivresse',                              montantBase: 50000, convocationObligatoire: true  },
  { code: 'COM-004', libelle: 'Dépassement dangereux',                                     montantBase: 25000, convocationObligatoire: false },
  { code: 'COM-005', libelle: 'Refus de priorité',                                         montantBase: 15000, convocationObligatoire: false },
  { code: 'COM-006', libelle: 'Circulation à contresens',                                  montantBase: 20000, convocationObligatoire: false },
  { code: 'COM-007', libelle: 'Non-respect d\'un stop ou d\'une priorité',                montantBase: 15000, convocationObligatoire: false },
  { code: 'COM-008', libelle: 'Demi-tour interdit',                                        montantBase: 12000, convocationObligatoire: false },
  { code: 'COM-009', libelle: 'Conduite sans éclairage de nuit',                           montantBase: 12000, convocationObligatoire: false },

  // ── STATIONNEMENT ────────────────────────────────────────────────────────
  { code: 'STA-001', libelle: 'Stationnement interdit ou gênant',                          montantBase:  5000, convocationObligatoire: false },
  { code: 'STA-002', libelle: 'Stationnement en double file',                              montantBase:  5000, convocationObligatoire: false },
  { code: 'STA-003', libelle: 'Stationnement sur trottoir',                                montantBase:  5000, convocationObligatoire: false },

  // ── VITESSE ──────────────────────────────────────────────────────────────
  { code: 'VIT-001', libelle: 'Excès de vitesse inférieur à 20 km/h',                     montantBase: 15000, convocationObligatoire: false },
  { code: 'VIT-002', libelle: 'Excès de vitesse entre 20 et 40 km/h',                     montantBase: 30000, convocationObligatoire: false },
  { code: 'VIT-003', libelle: 'Excès de vitesse supérieur à 40 km/h',                     montantBase: 60000, convocationObligatoire: true  },

  // ── SURCHARGE ────────────────────────────────────────────────────────────
  { code: 'SUR-001', libelle: 'Surcharge du véhicule',                                     montantBase: 40000, convocationObligatoire: false },
] as const;

// ─────────────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  // Mot de passe démo : respecte la politique ISO 27001 (min 10 car., maj, min, chiffre, spécial)
  const DEMO_PIN = 'Demo@1234!';
  const pinHash  = await bcrypt.hash(DEMO_PIN, PIN_ROUNDS);

  // ── Comptes ──
  await prisma.user.upsert({
    where:  { email: 'admin@pnc.cg' },
    update: { pinHash, emailVerified: true },
    create: { email: 'admin@pnc.cg', pinHash, role: 'ADMIN', name: 'Administrateur PNC', emailVerified: true },
  });

  const agents = [
    { email: 'agent1@pnc.cg', name: 'Jean Mbemba',     badgeNumber: 'PNC-2024-001', telephone: '+242060000001' },
    { email: 'agent2@pnc.cg', name: 'Aline Okemba',    badgeNumber: 'PNC-2024-002', telephone: '+242060000002' },
    { email: 'agent3@pnc.cg', name: 'Patrick Loubota', badgeNumber: 'PNC-2024-003', telephone: '+242060000003' },
  ];
  for (const a of agents) {
    await prisma.user.upsert({
      where:  { email: a.email },
      update: { pinHash, emailVerified: true },
      create: { ...a, pinHash, role: 'POLICE', emailVerified: true },
    });
  }

  const citoyens = [
    { email: 'citoyen1@pnc.cg', name: 'Marie Samba',  telephone: '+242061111111' },
    { email: 'citoyen2@pnc.cg', name: 'Thomas Ngolo', telephone: '+242062222222' },
  ];
  for (const c of citoyens) {
    await prisma.user.upsert({
      where:  { email: c.email },
      update: { pinHash, emailVerified: true },
      create: { ...c, pinHash, role: 'CITOYEN', emailVerified: true },
    });
  }

  // eslint-disable-next-line no-console
  console.log(`   Mot de passe démo : ${DEMO_PIN}`);

  // ── Catalogue d'infractions officiel (code de la route Congo) ──
  let upserted = 0;
  for (const inf of INFRACTIONS) {
    await prisma.infractionType.upsert({
      where: { code: inf.code },
      update: {
        libelle: inf.libelle,
        montantBase: inf.montantBase,
        convocationObligatoire: inf.convocationObligatoire,
        actif: true,
      },
      create: { ...inf, actif: true },
    });
    upserted++;
  }

  // ── Conducteur + véhicule de démonstration ──
  const driver = await prisma.driver.upsert({
    where: { numeroPermis: 'CG-PERM-0001' },
    update: {},
    create: {
      nom: 'Bantsimba',
      prenom: 'Joseph',
      telephone: '+242069999999',
      numeroPermis: 'CG-PERM-0001',
      permisValide: true,
      consentement: true,
    },
  });
  await prisma.vehicle.upsert({
    where: { plaque: 'CG-1234-AB' },
    update: {},
    create: {
      plaque: 'CG-1234-AB',
      marque: 'Toyota',
      modele: 'Corolla',
      couleur: 'Grise',
      driverId: driver.id,
    },
  });

  // eslint-disable-next-line no-console
  console.log(`✅ Seed terminé : ${upserted} infractions (code de la route Congo), comptes, conducteur/véhicule de démo.`);
  // eslint-disable-next-line no-console
  console.log('   Répartition : montantBase (police) + 1 000 XAF (Circulation+) = montantTotal citoyen');
}

main()
  .catch((err) => {
    // eslint-disable-next-line no-console
    console.error(err);
    process.exit(1);
  })
  .finally(() => {
    void prisma.$disconnect();
  });
