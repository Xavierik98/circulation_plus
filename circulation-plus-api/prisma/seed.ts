/**
 * Seed PNC Congo — hiérarchie complète + données de démonstration.
 *
 * Hiérarchie encodée via parentId (Commissariat auto-référentiel) :
 *   null (Direction Départementale)
 *   └─ parentId = DD.id  (Commissariat Central)
 *      └─ parentId = CC.id  (Commissariat de Zone)
 *
 * Usage : npx prisma db seed
 */

import bcrypt from 'bcryptjs';
import {
  PrismaClient,
  type GradePNC,
  type NiveauHierarchique,
  type Departement,
} from '@prisma/client';

const prisma = new PrismaClient();
const PIN_ROUNDS = 12;
const DEMO_PIN = 'Admin@1234!';

// ── Helper : upsert commissariat ──────────────────────────────────────────────
async function upsertCommissariat(data: {
  nom: string;
  code: string;
  departement: Departement;
  parentId?: string;
  lat?: number;
  lng?: number;
  adresse?: string;
}) {
  return prisma.commissariat.upsert({
    where: { code: data.code },
    update: {},
    create: {
      nom: data.nom,
      code: data.code,
      departement: data.departement,
      parentId: data.parentId ?? null,
      lat: data.lat ?? null,
      lng: data.lng ?? null,
      adresse: data.adresse ?? null,
      actif: true,
    },
  });
}

// ── Helper : upsert user ──────────────────────────────────────────────────────
async function upsertUser(data: {
  email: string;
  name: string;
  role: 'ADMIN' | 'POLICE' | 'CITOYEN';
  grade?: GradePNC;
  niveauHierarchique?: NiveauHierarchique;
  departement?: Departement;
  commissariatId?: string;
  badgeNumber?: string;
  telephone?: string;
  mustChangePassword?: boolean;
}) {
  const pinHash = await bcrypt.hash(DEMO_PIN, PIN_ROUNDS);
  return prisma.user.upsert({
    where: { email: data.email },
    update: {},
    create: {
      email: data.email,
      pinHash,
      name: data.name,
      role: data.role,
      grade: data.grade ?? null,
      niveauHierarchique: data.niveauHierarchique ?? 'AGENT',
      departement: data.departement ?? null,
      commissariatId: data.commissariatId ?? null,
      badgeNumber: data.badgeNumber ?? null,
      telephone: data.telephone ?? null,
      mustChangePassword: data.mustChangePassword ?? false,
      emailVerified: true,
      actif: true,
    },
  });
}

// ── 1. Directions Departementales (12) ───────────────────────────────────────
// parentId = null → niveau racine (Direction Départementale)
async function seedDirectionsDepartementales() {
  console.log('  -> Directions Departementales...');

  const defs = [
    { nom: 'Direction Departementale de Brazzaville',    code: 'DD-BZV',          dept: 'BRAZZAVILLE',   lat: -4.2634, lng: 15.2429, adresse: 'Avenue de la Paix, Brazzaville' },
    { nom: 'Direction Departementale de Pointe-Noire',   code: 'DD-PNR',          dept: 'POINTE_NOIRE',  lat: -4.7692, lng: 11.8660, adresse: 'Blvd Marien Ngouabi, Pointe-Noire' },
    { nom: 'Direction Departementale du Pool',            code: 'DD-POOL',         dept: 'POOL',          lat: -4.1770, lng: 14.8670, adresse: 'Kinkala' },
    { nom: 'Direction Departementale de la Bouenza',      code: 'DD-BOUENZA',      dept: 'BOUENZA',       lat: -4.2038, lng: 13.4826, adresse: 'Madingou' },
    { nom: 'Direction Departementale du Niari',           code: 'DD-NIARI',        dept: 'NIARI',         lat: -4.1820, lng: 12.3640, adresse: 'Dolisie' },
    { nom: 'Direction Departementale de la Lekoumou',     code: 'DD-LEKOUMOU',     dept: 'LEKOUMOU',      lat: -3.5330, lng: 13.5500, adresse: 'Sibiti' },
    { nom: 'Direction Departementale du Kouilou',         code: 'DD-KOUILOU',      dept: 'KOUILOU',       lat: -4.1500, lng: 11.8900, adresse: 'Hinda' },
    { nom: 'Direction Departementale des Plateaux',       code: 'DD-PLATEAUX',     dept: 'PLATEAUX',      lat: -0.7220, lng: 15.5950, adresse: 'Djambala' },
    { nom: 'Direction Departementale de la Cuvette',      code: 'DD-CUVETTE',      dept: 'CUVETTE',       lat: 0.0700,  lng: 16.0500, adresse: 'Owando' },
    { nom: 'Direction Departementale de la Cuvette-Ouest',code: 'DD-CUVETTE_OUEST',dept: 'CUVETTE_OUEST', lat: 0.3010,  lng: 14.5200, adresse: 'Ewo' },
    { nom: 'Direction Departementale de la Sangha',       code: 'DD-SANGHA',       dept: 'SANGHA',        lat: 1.6150,  lng: 16.0500, adresse: 'Ouesso' },
    { nom: 'Direction Departementale de la Likouala',     code: 'DD-LIKOUALA',     dept: 'LIKOUALA',      lat: 1.2290,  lng: 17.6760, adresse: 'Impfondo' },
  ];

  const dirs = await Promise.all(
    defs.map((d) =>
      upsertCommissariat({
        nom: d.nom,
        code: d.code,
        departement: d.dept as Departement,
        lat: d.lat,
        lng: d.lng,
        adresse: d.adresse,
      }),
    ),
  );

  return dirs;
}

// ── 2. Commissariats Centraux de Brazzaville (9 arrondissements) ─────────────
async function seedBrazzaville(parentId: string) {
  console.log('  -> Commissariats centraux de Brazzaville...');

  const defs = [
    { nom: 'Commissariat Central Makelekele (1er Arr.)',    code: 'CC-BZV-01', lat: -4.3170, lng: 15.2780 },
    { nom: 'Commissariat Central Bacongo (2e Arr.)',         code: 'CC-BZV-02', lat: -4.2940, lng: 15.2620 },
    { nom: 'Commissariat Central Djiri (3e Arr.)',           code: 'CC-BZV-03', lat: -4.1600, lng: 15.3300 },
    { nom: 'Commissariat Central Moungali (4e Arr.)',        code: 'CC-BZV-04', lat: -4.2500, lng: 15.2900 },
    { nom: 'Commissariat Central Ouenze (5e Arr.)',          code: 'CC-BZV-05', lat: -4.2320, lng: 15.2920 },
    { nom: 'Commissariat Central Talangai (6e Arr.)',        code: 'CC-BZV-06', lat: -4.2050, lng: 15.2990 },
    { nom: 'Commissariat Central Mfilou (7e Arr.)',          code: 'CC-BZV-07', lat: -4.2810, lng: 15.2200 },
    { nom: 'Commissariat Central Madibou (8e Arr.)',         code: 'CC-BZV-08', lat: -4.3490, lng: 15.2560 },
    { nom: 'Commissariat Central Poto-Poto (9e Arr.)',       code: 'CC-BZV-09', lat: -4.2580, lng: 15.2840 },
  ];

  const centraux = await Promise.all(
    defs.map((d) =>
      upsertCommissariat({
        nom: d.nom,
        code: d.code,
        departement: 'BRAZZAVILLE',
        parentId,
        lat: d.lat,
        lng: d.lng,
        adresse: `${d.nom.replace('Commissariat Central ', '')}, Brazzaville`,
      }),
    ),
  );

  return centraux;
}

// ── 3. Commissariats de Zone — Brazzaville ────────────────────────────────────
async function seedZonesBrazzaville(centraux: { id: string; code: string }[]) {
  console.log('  -> Commissariats de zone de Brazzaville...');

  const byCode = Object.fromEntries(centraux.map((c) => [c.code, c.id]));

  const defs = [
    { nom: 'Commissariat de Zone La Plaine',      code: 'CZ-BZV-09-1', parentCode: 'CC-BZV-09', lat: -4.2550, lng: 15.2870 },
    { nom: 'Commissariat de Zone Poto-Poto Nord', code: 'CZ-BZV-09-2', parentCode: 'CC-BZV-09', lat: -4.2510, lng: 15.2810 },
    { nom: 'Commissariat de Zone Moungali Est',   code: 'CZ-BZV-04-1', parentCode: 'CC-BZV-04', lat: -4.2470, lng: 15.2950 },
    { nom: 'Commissariat de Zone Moungali Ouest', code: 'CZ-BZV-04-2', parentCode: 'CC-BZV-04', lat: -4.2520, lng: 15.2880 },
    { nom: 'Commissariat de Zone Talangai Centre',code: 'CZ-BZV-06-1', parentCode: 'CC-BZV-06', lat: -4.2040, lng: 15.3010 },
  ];

  await Promise.all(
    defs.map((z) =>
      upsertCommissariat({
        nom: z.nom,
        code: z.code,
        departement: 'BRAZZAVILLE',
        parentId: byCode[z.parentCode]!,
        lat: z.lat,
        lng: z.lng,
      }),
    ),
  );
}

// ── 4. Commissariats Centraux de Pointe-Noire (6 arrondissements) ─────────────
async function seedPointeNoire(parentId: string) {
  console.log('  -> Commissariats centraux de Pointe-Noire...');

  const defs = [
    { nom: 'Commissariat Central Lumumba (1er Arr.)',     code: 'CC-PNR-01', lat: -4.7760, lng: 11.8590 },
    { nom: 'Commissariat Central Mvou-Mvou (2e Arr.)',    code: 'CC-PNR-02', lat: -4.7820, lng: 11.8650 },
    { nom: 'Commissariat Central Tie-Tie (3e Arr.)',      code: 'CC-PNR-03', lat: -4.7700, lng: 11.8500 },
    { nom: 'Commissariat Central Loandjili (4e Arr.)',    code: 'CC-PNR-04', lat: -4.7600, lng: 11.8900 },
    { nom: 'Commissariat Central Ngoyo (5e Arr.)',        code: 'CC-PNR-05', lat: -4.7500, lng: 11.9000 },
    { nom: 'Commissariat Central Mongo-Mpoukou (6e Arr.)',code: 'CC-PNR-06', lat: -4.7400, lng: 11.8700 },
  ];

  await Promise.all(
    defs.map((d) =>
      upsertCommissariat({
        nom: d.nom,
        code: d.code,
        departement: 'POINTE_NOIRE',
        parentId,
        lat: d.lat,
        lng: d.lng,
        adresse: `${d.nom.replace('Commissariat Central ', '')}, Pointe-Noire`,
      }),
    ),
  );
}

// ── 5. Commissariats chef-lieu — autres departements ─────────────────────────
async function seedAutresDepartements(dirs: { id: string; code: string; departement: string }[]) {
  console.log('  -> Commissariats chef-lieu autres departements...');

  const byCode = Object.fromEntries(dirs.map((d) => [d.code, d]));

  const defs = [
    { nom: 'Commissariat Central de Kinkala',  code: 'CC-POOL-1',          dirCode: 'DD-POOL',          dept: 'POOL',          lat: -4.1770, lng: 14.8670 },
    { nom: 'Commissariat Central de Madingou', code: 'CC-BOUENZA-1',        dirCode: 'DD-BOUENZA',       dept: 'BOUENZA',       lat: -4.2038, lng: 13.4826 },
    { nom: 'Commissariat Central de Dolisie',  code: 'CC-NIARI-1',          dirCode: 'DD-NIARI',         dept: 'NIARI',         lat: -4.1820, lng: 12.3640 },
    { nom: 'Commissariat Central de Sibiti',   code: 'CC-LEKOUMOU-1',       dirCode: 'DD-LEKOUMOU',      dept: 'LEKOUMOU',      lat: -3.5330, lng: 13.5500 },
    { nom: 'Commissariat Central de Hinda',    code: 'CC-KOUILOU-1',        dirCode: 'DD-KOUILOU',       dept: 'KOUILOU',       lat: -4.1500, lng: 11.8900 },
    { nom: 'Commissariat Central de Djambala', code: 'CC-PLATEAUX-1',       dirCode: 'DD-PLATEAUX',      dept: 'PLATEAUX',      lat: -0.7220, lng: 15.5950 },
    { nom: 'Commissariat Central de Owando',   code: 'CC-CUVETTE-1',        dirCode: 'DD-CUVETTE',       dept: 'CUVETTE',       lat:  0.0700, lng: 16.0500 },
    { nom: 'Commissariat Central de Ewo',      code: 'CC-CUVETTE_OUEST-1',  dirCode: 'DD-CUVETTE_OUEST', dept: 'CUVETTE_OUEST', lat:  0.3010, lng: 14.5200 },
    { nom: 'Commissariat Central de Ouesso',   code: 'CC-SANGHA-1',         dirCode: 'DD-SANGHA',        dept: 'SANGHA',        lat:  1.6150, lng: 16.0500 },
    { nom: 'Commissariat Central de Impfondo', code: 'CC-LIKOUALA-1',       dirCode: 'DD-LIKOUALA',      dept: 'LIKOUALA',      lat:  1.2290, lng: 17.6760 },
  ];

  await Promise.all(
    defs.map((c) =>
      upsertCommissariat({
        nom: c.nom,
        code: c.code,
        departement: c.dept as Departement,
        parentId: byCode[c.dirCode]!.id,
        lat: c.lat,
        lng: c.lng,
      }),
    ),
  );
}

// ── 6. Types d'infractions (Code de la route Congo) ──────────────────────────
async function seedInfractionTypes() {
  console.log("  -> Types d'infractions...");

  const defs = [
    { code: 'VIT-01', libelle: 'Exces de vitesse (1 a 20 km/h)',                montant: 15000  },
    { code: 'VIT-02', libelle: 'Exces de vitesse (21 a 50 km/h)',               montant: 30000  },
    { code: 'VIT-03', libelle: 'Exces de vitesse (plus de 50 km/h)',            montant: 60000  },
    { code: 'ALC-01', libelle: "Conduite sous l'emprise de l'alcool",           montant: 100000 },
    { code: 'ALC-02', libelle: "Refus de se soumettre au test d'alcoolemie",    montant: 100000 },
    { code: 'STU-01', libelle: "Conduite sous l'emprise de stupefiants",        montant: 150000 },
    { code: 'DOC-01', libelle: 'Defaut de permis de conduire',                  montant: 25000  },
    { code: 'DOC-02', libelle: 'Defaut de carte grise (immatriculation)',        montant: 20000  },
    { code: 'DOC-03', libelle: "Defaut d'assurance",                            montant: 50000  },
    { code: 'DOC-04', libelle: 'Defaut de visite technique',                    montant: 20000  },
    { code: 'CEI-01', libelle: 'Non-port de la ceinture de securite',           montant: 15000  },
    { code: 'CAS-01', libelle: 'Non-port du casque (deux-roues)',               montant: 15000  },
    { code: 'TEL-01', libelle: 'Usage du telephone au volant',                  montant: 25000  },
    { code: 'SIG-01', libelle: 'Non-respect du feu rouge',                      montant: 30000  },
    { code: 'SIG-02', libelle: 'Non-respect du stop',                           montant: 25000  },
    { code: 'SIG-03', libelle: 'Sens interdit',                                 montant: 25000  },
    { code: 'STA-01', libelle: 'Stationnement interdit genant',                 montant: 10000  },
    { code: 'STA-02', libelle: 'Stationnement sur passage pieton',              montant: 15000  },
    { code: 'VEH-01', libelle: "Defaut d'eclairage ou de signalisation",        montant: 10000  },
    { code: 'VEH-02', libelle: 'Surcharge du vehicule',                         montant: 40000  },
  ];

  await Promise.all(
    defs.map((inf) =>
      prisma.infractionType.upsert({
        where: { code: inf.code },
        update: {},
        create: {
          code: inf.code,
          libelle: inf.libelle,
          montantBase: inf.montant,
          actif: true,
        },
      }),
    ),
  );

  console.log(`     ${defs.length} infractions creees/ignorees`);
}

// ── 7. Utilisateurs de demonstration ─────────────────────────────────────────
async function seedUsers(commissariats: { id: string; code: string }[]) {
  console.log('  -> Utilisateurs de demonstration...');

  const byCode = Object.fromEntries(commissariats.map((c) => [c.code, c.id]));

  // Super-admin — Direction Generale (voit tout le pays)
  await upsertUser({
    email: 'admin@pnc.cg',
    name: 'Directeur General PNC',
    role: 'ADMIN',
    grade: 'DIRECTEUR_GENERAL',
    niveauHierarchique: 'DIRECTION_GENERALE',
  });

  // Admin — Direction Departementale Brazzaville
  await upsertUser({
    email: 'dir.bzv@pnc.cg',
    name: 'Commissaire Divisionnaire Brazzaville',
    role: 'ADMIN',
    grade: 'COMMISSAIRE_DIVISIONNAIRE',
    niveauHierarchique: 'DIRECTION_DEPT',
    departement: 'BRAZZAVILLE',
  });

  // Admin — Commissariat Central Moungali
  await upsertUser({
    email: 'comm.moungali@pnc.cg',
    name: 'Commissaire Moungali',
    role: 'ADMIN',
    grade: 'COMMISSAIRE_PRINCIPAL',
    niveauHierarchique: 'COMMISSARIAT_CENTRAL',
    departement: 'BRAZZAVILLE',
    commissariatId: byCode['CC-BZV-04'],
    badgeNumber: 'PNC-ADM-2024-001',
  });

  // Agents de police
  await upsertUser({
    email: 'agent1@pnc.cg',
    name: 'Jean Mbemba',
    role: 'POLICE',
    grade: 'INSPECTEUR',
    niveauHierarchique: 'AGENT',
    departement: 'BRAZZAVILLE',
    commissariatId: byCode['CC-BZV-09'],
    badgeNumber: 'PNC-2024-001',
    telephone: '+242066001001',
  });

  await upsertUser({
    email: 'agent2@pnc.cg',
    name: 'Aline Okemba',
    role: 'POLICE',
    grade: 'INSPECTEUR_PRINCIPAL',
    niveauHierarchique: 'AGENT',
    departement: 'BRAZZAVILLE',
    commissariatId: byCode['CC-BZV-04'],
    badgeNumber: 'PNC-2024-002',
    telephone: '+242066001002',
  });

  await upsertUser({
    email: 'agent3@pnc.cg',
    name: 'Patrick Loubota',
    role: 'POLICE',
    grade: 'BRIGADIER',
    niveauHierarchique: 'AGENT',
    departement: 'BRAZZAVILLE',
    commissariatId: byCode['CC-BZV-06'],
    badgeNumber: 'PNC-2024-003',
    telephone: '+242066001003',
  });

  // Citoyens
  await upsertUser({
    email: 'citoyen1@gmail.com',
    name: 'Marie Samba',
    role: 'CITOYEN',
    telephone: '+242055001001',
  });

  await upsertUser({
    email: 'citoyen2@gmail.com',
    name: 'Thomas Ngolo',
    role: 'CITOYEN',
    telephone: '+242055001002',
  });

  console.log('     8 utilisateurs crees/ignores (PIN: Admin@1234!)');
}

// ── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  console.log('\nSeed PNC Congo -- debut\n');

  // 1. Directions Departementales
  const dirs = await seedDirectionsDepartementales();
  console.log(`     ${dirs.length} directions creees/ignorees`);

  // 2. Commissariats centraux Brazzaville
  const ddBzv = dirs.find((d) => d.code === 'DD-BZV')!;
  const centraux = await seedBrazzaville(ddBzv.id);
  console.log(`     ${centraux.length} commissariats centraux BZV crees/ignores`);

  // 3. Commissariats de zone Brazzaville
  await seedZonesBrazzaville(centraux);

  // 4. Commissariats centraux Pointe-Noire
  const ddPnr = dirs.find((d) => d.code === 'DD-PNR')!;
  await seedPointeNoire(ddPnr.id);

  // 5. Commissariats chef-lieu autres departements
  const dirsWithDept = dirs.map((d) => ({
    id: d.id,
    code: d.code,
    departement: d.departement,
  }));
  await seedAutresDepartements(dirsWithDept);

  // 6. Types d'infractions
  await seedInfractionTypes();

  // 7. Utilisateurs
  const allCommissariats = await prisma.commissariat.findMany({
    select: { id: true, code: true },
  });
  await seedUsers(allCommissariats);

  console.log('\nSeed termine avec succes!\n');
  console.log('Comptes demo (PIN: Admin@1234!) :');
  console.log('  admin@pnc.cg          ADMIN  Direction Generale');
  console.log('  dir.bzv@pnc.cg        ADMIN  Direction Dept Brazzaville');
  console.log('  comm.moungali@pnc.cg  ADMIN  Commissariat Central Moungali');
  console.log('  agent1@pnc.cg         POLICE Poto-Poto (badge PNC-2024-001)');
  console.log('  agent2@pnc.cg         POLICE Moungali  (badge PNC-2024-002)');
  console.log('  agent3@pnc.cg         POLICE Talangai  (badge PNC-2024-003)');
  console.log('  citoyen1@gmail.com    CITOYEN');
  console.log('  citoyen2@gmail.com    CITOYEN\n');
}

main()
  .catch((e) => {
    console.error('\nSeed echoue :', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
