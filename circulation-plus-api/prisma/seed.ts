import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const PIN_ROUNDS = 12;

// 15 infractions routières réalistes (codes alignés sur le catalogue Flutter
// + 3 ajouts). Montants en XAF.
const INFRACTIONS = [
  { id: 'INF001', code: 'EXV-1', libelle: 'Excès de vitesse < 20 km/h', montantBase: 15000, convocationObligatoire: false },
  { id: 'INF002', code: 'EXV-2', libelle: 'Excès de vitesse 20–40 km/h', montantBase: 30000, convocationObligatoire: false },
  { id: 'INF003', code: 'EXV-3', libelle: 'Excès de vitesse > 40 km/h', montantBase: 60000, convocationObligatoire: false },
  { id: 'INF004', code: 'CAS-1', libelle: 'Circulation sans casque (moto)', montantBase: 5000, convocationObligatoire: false },
  { id: 'INF005', code: 'FEU-1', libelle: 'Non-respect feu rouge', montantBase: 20000, convocationObligatoire: false },
  { id: 'INF006', code: 'CEI-1', libelle: 'Non-port de la ceinture de sécurité', montantBase: 10000, convocationObligatoire: false },
  { id: 'INF007', code: 'PER-1', libelle: 'Conduite sans permis valide', montantBase: 25000, convocationObligatoire: true },
  { id: 'INF008', code: 'CGR-1', libelle: 'Défaut de carte grise', montantBase: 15000, convocationObligatoire: false },
  { id: 'INF009', code: 'TEL-1', libelle: 'Utilisation du téléphone au volant', montantBase: 20000, convocationObligatoire: false },
  { id: 'INF010', code: 'STA-1', libelle: 'Stationnement interdit / gênant', montantBase: 5000, convocationObligatoire: false },
  { id: 'INF011', code: 'ASS-1', libelle: "Défaut d'assurance", montantBase: 30000, convocationObligatoire: false },
  { id: 'INF012', code: 'SUR-1', libelle: 'Surcharge du véhicule', montantBase: 40000, convocationObligatoire: false },
  { id: 'INF013', code: 'ALC-1', libelle: "Conduite en état d'ivresse", montantBase: 50000, convocationObligatoire: true },
  { id: 'INF014', code: 'DEP-1', libelle: 'Dépassement dangereux', montantBase: 25000, convocationObligatoire: false },
  { id: 'INF015', code: 'PRI-1', libelle: 'Refus de priorité', montantBase: 15000, convocationObligatoire: false },
];

async function main(): Promise<void> {
  const pinHash = await bcrypt.hash('0000', PIN_ROUNDS);

  // Comptes
  await prisma.user.upsert({
    where: { email: 'admin@pnc.cg' },
    update: {},
    create: { email: 'admin@pnc.cg', pinHash, role: 'ADMIN', name: 'Administrateur PNC' },
  });

  const agents = [
    { email: 'agent1@pnc.cg', name: 'Jean Mbemba', badgeNumber: 'PNC-2024-001', telephone: '+242060000001' },
    { email: 'agent2@pnc.cg', name: 'Aline Okemba', badgeNumber: 'PNC-2024-002', telephone: '+242060000002' },
    { email: 'agent3@pnc.cg', name: 'Patrick Loubota', badgeNumber: 'PNC-2024-003', telephone: '+242060000003' },
  ];
  for (const a of agents) {
    await prisma.user.upsert({
      where: { email: a.email },
      update: {},
      create: { ...a, pinHash, role: 'POLICE' },
    });
  }

  const citoyens = [
    { email: 'citoyen1@pnc.cg', name: 'Marie Samba', telephone: '+242061111111' },
    { email: 'citoyen2@pnc.cg', name: 'Thomas Ngolo', telephone: '+242062222222' },
  ];
  for (const c of citoyens) {
    await prisma.user.upsert({
      where: { email: c.email },
      update: {},
      create: { ...c, pinHash, role: 'CITOYEN' },
    });
  }

  // Catalogue d'infractions
  for (const inf of INFRACTIONS) {
    await prisma.infractionType.upsert({
      where: { code: inf.code },
      update: { libelle: inf.libelle, montantBase: inf.montantBase, convocationObligatoire: inf.convocationObligatoire },
      create: inf,
    });
  }

  // Conducteur + véhicule de démonstration
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
  console.log('Seed terminé : comptes, 15 infractions, conducteur/véhicule de démo.');
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
