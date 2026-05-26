/**
 * Seed PNC Congo — hiérarchie complète FK (v2).
 *
 * Structure :
 *   DirectionGenerale (1 — DGPN)
 *   └─ DirectionNationale (7 — DSP, DPJ, DPAF, DCRP, DCI, DST, DRSP)
 *   Departement (12)
 *   └─ DirectionDepartementale (12)
 *      └─ Commissariat (52)
 *         └─ Unite (96)
 *   Grade (12)
 *   AppRole (8) + Permission (15) + RolePermission
 *   Utilisateurs de démonstration
 *
 * Usage : npx prisma db seed
 */

import bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const PIN_ROUNDS = 12;
const DEMO_PIN = 'Admin@1234!';

// ─────────────────────────────────────────────────────────────────────────────
// 1. DirectionGenerale
// ─────────────────────────────────────────────────────────────────────────────
async function seedDirectionGenerale() {
  console.log('  -> Direction Generale...');
  return prisma.directionGenerale.upsert({
    where:  { code: 'DGPN' },
    update: {},
    create: {
      nom:     'Direction Générale de la Police Nationale',
      code:    'DGPN',
      adresse: 'Avenue de la Paix, Brazzaville',
      actif:   true,
      updatedAt: new Date(),
    },
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. DirectionsNationales
// ─────────────────────────────────────────────────────────────────────────────
async function seedDirectionsNationales(dgpnId: string) {
  console.log('  -> Directions Nationales (7)...');
  const defs = [
    { sigle: 'DSP',  nom: 'Direction de la Sécurité Publique',             description: 'Maintien de l\'ordre et sécurité publique' },
    { sigle: 'DPJ',  nom: 'Direction de la Police Judiciaire',              description: 'Police judiciaire et enquêtes criminelles' },
    { sigle: 'DPAF', nom: 'Direction de la Police de l\'Air et des Frontières', description: 'Contrôle des frontières, aéroports, ports' },
    { sigle: 'DCRP', nom: 'Direction Centrale des Ressources et du Personnel', description: 'Ressources humaines et administration' },
    { sigle: 'DCI',  nom: 'Direction Centrale des Infrastructures',         description: 'Équipements et infrastructures' },
    { sigle: 'DST',  nom: 'Direction de la Surveillance du Territoire',     description: 'Renseignement intérieur' },
    { sigle: 'DRSP', nom: 'Direction des Renseignements et de la Sécurité Présidentielle', description: 'Sécurité présidentielle' },
  ];
  const result: Record<string, string> = {};
  for (const d of defs) {
    const dn = await prisma.directionNationale.upsert({
      where:  { sigle: d.sigle },
      update: {},
      create: {
        nom: d.nom, sigle: d.sigle, description: d.description,
        directionGeneraleId: dgpnId, actif: true, updatedAt: new Date(),
      },
    });
    result[d.sigle] = dn.id;
  }
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Départements (12)
// ─────────────────────────────────────────────────────────────────────────────
async function seedDepartements() {
  console.log('  -> Departements (12)...');
  const defs = [
    { code: 'BRAZZAVILLE',   nom: 'Brazzaville',    chefLieu: 'Brazzaville'  },
    { code: 'POINTE_NOIRE',  nom: 'Pointe-Noire',   chefLieu: 'Pointe-Noire' },
    { code: 'POOL',          nom: 'Pool',             chefLieu: 'Kinkala'      },
    { code: 'BOUENZA',       nom: 'Bouenza',          chefLieu: 'Madingou'     },
    { code: 'NIARI',         nom: 'Niari',            chefLieu: 'Dolisie'      },
    { code: 'LEKOUMOU',      nom: 'Lékoumou',         chefLieu: 'Sibiti'       },
    { code: 'KOUILOU',       nom: 'Kouilou',          chefLieu: 'Hinda'        },
    { code: 'PLATEAUX',      nom: 'Plateaux',         chefLieu: 'Djambala'     },
    { code: 'CUVETTE',       nom: 'Cuvette',          chefLieu: 'Owando'       },
    { code: 'CUVETTE_OUEST', nom: 'Cuvette-Ouest',    chefLieu: 'Ewo'          },
    { code: 'SANGHA',        nom: 'Sangha',           chefLieu: 'Ouesso'       },
    { code: 'LIKOUALA',      nom: 'Likouala',         chefLieu: 'Impfondo'     },
  ];
  const result: Record<string, string> = {};
  for (const d of defs) {
    const dept = await prisma.departement.upsert({
      where:  { code: d.code },
      update: {},
      create: { nom: d.nom, code: d.code, chefLieu: d.chefLieu, actif: true, updatedAt: new Date() },
    });
    result[d.code] = dept.id;
  }
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. DirectionsDepartementales (12)
// ─────────────────────────────────────────────────────────────────────────────
async function seedDirectionsDepartementales(deptIds: Record<string, string>) {
  console.log('  -> Directions Departementales (12)...');
  const defs = [
    { code: 'DD-BZV',          deptCode: 'BRAZZAVILLE',   nom: 'Direction Départementale de Brazzaville',         lat: -4.2634, lng: 15.2429 },
    { code: 'DD-PNR',          deptCode: 'POINTE_NOIRE',  nom: 'Direction Départementale de Pointe-Noire',        lat: -4.7692, lng: 11.8660 },
    { code: 'DD-POOL',         deptCode: 'POOL',           nom: 'Direction Départementale du Pool',                lat: -4.1770, lng: 14.8670 },
    { code: 'DD-BOUENZA',      deptCode: 'BOUENZA',        nom: 'Direction Départementale de la Bouenza',          lat: -4.2038, lng: 13.4826 },
    { code: 'DD-NIARI',        deptCode: 'NIARI',          nom: 'Direction Départementale du Niari',               lat: -4.1820, lng: 12.3640 },
    { code: 'DD-LEKOUMOU',     deptCode: 'LEKOUMOU',       nom: 'Direction Départementale de la Lékoumou',         lat: -3.5330, lng: 13.5500 },
    { code: 'DD-KOUILOU',      deptCode: 'KOUILOU',        nom: 'Direction Départementale du Kouilou',             lat: -4.1500, lng: 11.8900 },
    { code: 'DD-PLATEAUX',     deptCode: 'PLATEAUX',       nom: 'Direction Départementale des Plateaux',           lat: -0.7220, lng: 15.5950 },
    { code: 'DD-CUVETTE',      deptCode: 'CUVETTE',        nom: 'Direction Départementale de la Cuvette',          lat:  0.0700, lng: 16.0500 },
    { code: 'DD-CUVETTE_OUEST',deptCode: 'CUVETTE_OUEST',  nom: 'Direction Départementale de la Cuvette-Ouest',   lat:  0.3010, lng: 14.5200 },
    { code: 'DD-SANGHA',       deptCode: 'SANGHA',         nom: 'Direction Départementale de la Sangha',           lat:  1.6150, lng: 16.0500 },
    { code: 'DD-LIKOUALA',     deptCode: 'LIKOUALA',       nom: 'Direction Départementale de la Likouala',         lat:  1.2290, lng: 17.6760 },
  ];
  const result: Record<string, string> = {};
  for (const d of defs) {
    const dd = await prisma.directionDepartementale.upsert({
      where:  { code: d.code },
      update: {},
      create: {
        nom: d.nom, code: d.code, lat: d.lat, lng: d.lng,
        departementId: deptIds[d.deptCode]!,
        actif: true, updatedAt: new Date(),
      },
    });
    result[d.code] = dd.id;
  }
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Commissariats (52)
// ─────────────────────────────────────────────────────────────────────────────
async function seedCommissariats(
  deptIds: Record<string, string>,
  ddIds: Record<string, string>,
) {
  console.log('  -> Commissariats (52)...');

  const defs: {
    nom: string; code: string; deptCode: string; ddCode: string;
    lat?: number; lng?: number; adresse?: string;
  }[] = [
    // ── Brazzaville (12) ──────────────────────────────────────────────────────
    { nom: 'Commissariat de Makelekele (1er Arr.)',    code: 'CC-BZV-01', deptCode: 'BRAZZAVILLE', ddCode: 'DD-BZV', lat: -4.3170, lng: 15.2780 },
    { nom: 'Commissariat de Bacongo (2e Arr.)',         code: 'CC-BZV-02', deptCode: 'BRAZZAVILLE', ddCode: 'DD-BZV', lat: -4.2940, lng: 15.2620 },
    { nom: 'Commissariat de Djiri (3e Arr.)',           code: 'CC-BZV-03', deptCode: 'BRAZZAVILLE', ddCode: 'DD-BZV', lat: -4.1600, lng: 15.3300 },
    { nom: 'Commissariat de Moungali (4e Arr.)',        code: 'CC-BZV-04', deptCode: 'BRAZZAVILLE', ddCode: 'DD-BZV', lat: -4.2500, lng: 15.2900 },
    { nom: 'Commissariat de Ouenzé (5e Arr.)',          code: 'CC-BZV-05', deptCode: 'BRAZZAVILLE', ddCode: 'DD-BZV', lat: -4.2320, lng: 15.2920 },
    { nom: 'Commissariat de Talangaï (6e Arr.)',        code: 'CC-BZV-06', deptCode: 'BRAZZAVILLE', ddCode: 'DD-BZV', lat: -4.2050, lng: 15.2990 },
    { nom: 'Commissariat de Mfilou (7e Arr.)',          code: 'CC-BZV-07', deptCode: 'BRAZZAVILLE', ddCode: 'DD-BZV', lat: -4.2810, lng: 15.2200 },
    { nom: 'Commissariat de Madibou (8e Arr.)',         code: 'CC-BZV-08', deptCode: 'BRAZZAVILLE', ddCode: 'DD-BZV', lat: -4.3490, lng: 15.2560 },
    { nom: 'Commissariat de Poto-Poto (9e Arr.)',       code: 'CC-BZV-09', deptCode: 'BRAZZAVILLE', ddCode: 'DD-BZV', lat: -4.2580, lng: 15.2840 },
    { nom: 'Commissariat de l\'Aéroport Maya-Maya',    code: 'CC-BZV-10', deptCode: 'BRAZZAVILLE', ddCode: 'DD-BZV', lat: -4.2517, lng: 15.2531, adresse: 'Aéroport International Maya-Maya' },
    { nom: 'Commissariat du Port de Brazzaville',      code: 'CC-BZV-11', deptCode: 'BRAZZAVILLE', ddCode: 'DD-BZV', lat: -4.2669, lng: 15.2879, adresse: 'Port fluvial de Brazzaville' },
    { nom: 'Commissariat de la Cité du Djoué',         code: 'CC-BZV-12', deptCode: 'BRAZZAVILLE', ddCode: 'DD-BZV', lat: -4.3300, lng: 15.2100 },

    // ── Pointe-Noire (9) ─────────────────────────────────────────────────────
    { nom: 'Commissariat de Lumumba (1er Arr.)',        code: 'CC-PNR-01', deptCode: 'POINTE_NOIRE', ddCode: 'DD-PNR', lat: -4.7760, lng: 11.8590 },
    { nom: 'Commissariat de Mvou-Mvou (2e Arr.)',       code: 'CC-PNR-02', deptCode: 'POINTE_NOIRE', ddCode: 'DD-PNR', lat: -4.7820, lng: 11.8650 },
    { nom: 'Commissariat de Tie-Tie (3e Arr.)',         code: 'CC-PNR-03', deptCode: 'POINTE_NOIRE', ddCode: 'DD-PNR', lat: -4.7700, lng: 11.8500 },
    { nom: 'Commissariat de Loandjili (4e Arr.)',       code: 'CC-PNR-04', deptCode: 'POINTE_NOIRE', ddCode: 'DD-PNR', lat: -4.7600, lng: 11.8900 },
    { nom: 'Commissariat de Ngoyo (5e Arr.)',           code: 'CC-PNR-05', deptCode: 'POINTE_NOIRE', ddCode: 'DD-PNR', lat: -4.7500, lng: 11.9000 },
    { nom: 'Commissariat de Mongo-Mpoukou (6e Arr.)',   code: 'CC-PNR-06', deptCode: 'POINTE_NOIRE', ddCode: 'DD-PNR', lat: -4.7400, lng: 11.8700 },
    { nom: 'Commissariat de l\'Aéroport A. A. Neto',   code: 'CC-PNR-07', deptCode: 'POINTE_NOIRE', ddCode: 'DD-PNR', lat: -4.8160, lng: 11.8856, adresse: 'Aéroport Agostinho Neto' },
    { nom: 'Commissariat du Port de Pointe-Noire',     code: 'CC-PNR-08', deptCode: 'POINTE_NOIRE', ddCode: 'DD-PNR', lat: -4.7756, lng: 11.8594, adresse: 'Port Autonome de Pointe-Noire' },
    { nom: 'Commissariat de Vindoulou',                code: 'CC-PNR-09', deptCode: 'POINTE_NOIRE', ddCode: 'DD-PNR', lat: -4.7900, lng: 11.8400 },

    // ── Niari (5) ─────────────────────────────────────────────────────────────
    { nom: 'Commissariat Central de Dolisie',           code: 'CC-NIR-01', deptCode: 'NIARI',   ddCode: 'DD-NIARI',   lat: -4.1820, lng: 12.3640 },
    { nom: 'Commissariat de Loudima',                   code: 'CC-NIR-02', deptCode: 'NIARI',   ddCode: 'DD-NIARI',   lat: -4.1160, lng: 13.0680 },
    { nom: 'Commissariat de Mossendjo',                 code: 'CC-NIR-03', deptCode: 'NIARI',   ddCode: 'DD-NIARI',   lat: -2.9500, lng: 12.7000 },
    { nom: 'Commissariat de Kimongo',                   code: 'CC-NIR-04', deptCode: 'NIARI',   ddCode: 'DD-NIARI',   lat: -4.5333, lng: 12.0500 },
    { nom: 'Commissariat de Kibangou',                  code: 'CC-NIR-05', deptCode: 'NIARI',   ddCode: 'DD-NIARI',   lat: -3.4660, lng: 12.3500 },

    // ── Cuvette (4) ───────────────────────────────────────────────────────────
    { nom: 'Commissariat Central d\'Owando',            code: 'CC-CUV-01', deptCode: 'CUVETTE', ddCode: 'DD-CUVETTE', lat:  0.0700, lng: 16.0500 },
    { nom: 'Commissariat de Makoua',                    code: 'CC-CUV-02', deptCode: 'CUVETTE', ddCode: 'DD-CUVETTE', lat:  0.0010, lng: 15.6340 },
    { nom: 'Commissariat de Fort-Rousset (Mossaka)',    code: 'CC-CUV-03', deptCode: 'CUVETTE', ddCode: 'DD-CUVETTE', lat: -1.2250, lng: 16.8000 },
    { nom: 'Commissariat de Boundji',                   code: 'CC-CUV-04', deptCode: 'CUVETTE', ddCode: 'DD-CUVETTE', lat: -1.0250, lng: 15.3760 },

    // ── Bouenza (4) ───────────────────────────────────────────────────────────
    { nom: 'Commissariat Central de Madingou',          code: 'CC-BOU-01', deptCode: 'BOUENZA', ddCode: 'DD-BOUENZA', lat: -4.2038, lng: 13.4826 },
    { nom: 'Commissariat de Nkayi',                     code: 'CC-BOU-02', deptCode: 'BOUENZA', ddCode: 'DD-BOUENZA', lat: -4.1600, lng: 13.2860 },
    { nom: 'Commissariat de Mouyondzi',                 code: 'CC-BOU-03', deptCode: 'BOUENZA', ddCode: 'DD-BOUENZA', lat: -4.0250, lng: 13.9610 },
    { nom: 'Commissariat de Loudima (Bouenza)',         code: 'CC-BOU-04', deptCode: 'BOUENZA', ddCode: 'DD-BOUENZA', lat: -4.1000, lng: 13.0680 },

    // ── Pool (4) ──────────────────────────────────────────────────────────────
    { nom: 'Commissariat Central de Kinkala',           code: 'CC-POOL-01', deptCode: 'POOL',    ddCode: 'DD-POOL',   lat: -4.1770, lng: 14.8670 },
    { nom: 'Commissariat de Kindamba',                  code: 'CC-POOL-02', deptCode: 'POOL',    ddCode: 'DD-POOL',   lat: -3.9760, lng: 14.5190 },
    { nom: 'Commissariat de Boko',                      code: 'CC-POOL-03', deptCode: 'POOL',    ddCode: 'DD-POOL',   lat: -4.7690, lng: 14.6480 },
    { nom: 'Commissariat de Mindouli',                  code: 'CC-POOL-04', deptCode: 'POOL',    ddCode: 'DD-POOL',   lat: -4.1630, lng: 14.4640 },

    // ── Plateaux (3) ─────────────────────────────────────────────────────────
    { nom: 'Commissariat Central de Djambala',          code: 'CC-PLA-01', deptCode: 'PLATEAUX', ddCode: 'DD-PLATEAUX', lat: -0.7220, lng: 15.5950 },
    { nom: 'Commissariat de Gamboma',                   code: 'CC-PLA-02', deptCode: 'PLATEAUX', ddCode: 'DD-PLATEAUX', lat: -1.8740, lng: 15.8660 },
    { nom: 'Commissariat d\'Abala',                     code: 'CC-PLA-03', deptCode: 'PLATEAUX', ddCode: 'DD-PLATEAUX', lat:  1.3900, lng: 15.6380 },

    // ── Sangha (3) ────────────────────────────────────────────────────────────
    { nom: 'Commissariat Central d\'Ouesso',            code: 'CC-SAN-01', deptCode: 'SANGHA',   ddCode: 'DD-SANGHA',   lat:  1.6150, lng: 16.0500 },
    { nom: 'Commissariat de Sembé',                     code: 'CC-SAN-02', deptCode: 'SANGHA',   ddCode: 'DD-SANGHA',   lat:  1.6490, lng: 14.5740 },
    { nom: 'Commissariat de Souanké',                   code: 'CC-SAN-03', deptCode: 'SANGHA',   ddCode: 'DD-SANGHA',   lat:  2.0600, lng: 14.1330 },

    // ── Likouala (3) ─────────────────────────────────────────────────────────
    { nom: 'Commissariat Central d\'Impfondo',          code: 'CC-LIK-01', deptCode: 'LIKOUALA', ddCode: 'DD-LIKOUALA', lat:  1.2290, lng: 17.6760 },
    { nom: 'Commissariat d\'Epena',                     code: 'CC-LIK-02', deptCode: 'LIKOUALA', ddCode: 'DD-LIKOUALA', lat:  1.3330, lng: 17.4750 },
    { nom: 'Commissariat de Dongou',                    code: 'CC-LIK-03', deptCode: 'LIKOUALA', ddCode: 'DD-LIKOUALA', lat:  2.7500, lng: 17.8750 },

    // ── Lékoumou (3) ─────────────────────────────────────────────────────────
    { nom: 'Commissariat Central de Sibiti',            code: 'CC-LEK-01', deptCode: 'LEKOUMOU', ddCode: 'DD-LEKOUMOU', lat: -3.5330, lng: 13.5500 },
    { nom: 'Commissariat de Komono',                    code: 'CC-LEK-02', deptCode: 'LEKOUMOU', ddCode: 'DD-LEKOUMOU', lat: -3.1660, lng: 13.2000 },
    { nom: 'Commissariat de Zanaga',                    code: 'CC-LEK-03', deptCode: 'LEKOUMOU', ddCode: 'DD-LEKOUMOU', lat: -2.8480, lng: 13.8220 },

    // ── Cuvette-Ouest (2) ─────────────────────────────────────────────────────
    { nom: 'Commissariat Central d\'Ewo',               code: 'CC-CUO-01', deptCode: 'CUVETTE_OUEST', ddCode: 'DD-CUVETTE_OUEST', lat: 0.3010, lng: 14.5200 },
    { nom: 'Commissariat de Kelle',                     code: 'CC-CUO-02', deptCode: 'CUVETTE_OUEST', ddCode: 'DD-CUVETTE_OUEST', lat: 0.0830, lng: 14.5300 },

    // ── Kouilou (2) ───────────────────────────────────────────────────────────
    { nom: 'Commissariat Central de Hinda',             code: 'CC-KOU-01', deptCode: 'KOUILOU', ddCode: 'DD-KOUILOU', lat: -4.1500, lng: 11.8900 },
    { nom: 'Commissariat de Kakamoeka',                 code: 'CC-KOU-02', deptCode: 'KOUILOU', ddCode: 'DD-KOUILOU', lat: -4.1700, lng: 11.5600 },
  ];

  const result: Record<string, string> = {};
  for (const d of defs) {
    const comm = await prisma.commissariat.upsert({
      where:  { code: d.code },
      update: {},
      create: {
        nom:                      d.nom,
        code:                     d.code,
        departementId:            deptIds[d.deptCode]!,
        directionDepartementaleId: ddIds[d.ddCode]!,
        lat:                      d.lat     ?? null,
        lng:                      d.lng     ?? null,
        adresse:                  d.adresse ?? null,
        actif:                    true,
        updatedAt:                new Date(),
      },
    });
    result[d.code] = comm.id;
  }
  console.log(`     ${defs.length} commissariats créés/ignorés`);
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Unités (96 — BSP, BPJ, BCR, BIR, BMO, BAF)
// ─────────────────────────────────────────────────────────────────────────────
async function seedUnites(commIds: Record<string, string>) {
  console.log('  -> Unites (96)...');

  const SIGLE_NOM: Record<string, string> = {
    BSP: 'Brigade de Sécurité Publique',
    BPJ: 'Brigade de Police Judiciaire',
    BCR: 'Brigade de Circulation Routière',
    BIR: 'Brigade d\'Intervention Rapide',
    BMO: 'Brigade de Maintien de l\'Ordre',
    BAF: 'Brigade des Affaires des Frontières',
  };

  // 2 ou 3 unités par commissariat selon l'importance
  const bigComms = [
    'CC-BZV-01','CC-BZV-02','CC-BZV-03','CC-BZV-04','CC-BZV-05','CC-BZV-06',
    'CC-BZV-07','CC-BZV-08','CC-BZV-09','CC-BZV-10','CC-BZV-11','CC-BZV-12',
    'CC-PNR-01','CC-PNR-02','CC-PNR-03','CC-PNR-04','CC-PNR-05','CC-PNR-06',
    'CC-PNR-07','CC-PNR-08','CC-PNR-09',
  ];
  const medComms = [
    'CC-NIR-01','CC-NIR-02','CC-NIR-03','CC-NIR-04','CC-NIR-05',
    'CC-CUV-01','CC-BOU-01','CC-BOU-02','CC-POOL-01','CC-PLA-01','CC-SAN-01',
    'CC-LIK-01','CC-LEK-01',
  ];

  const unitsForComm = (commCode: string): string[] => {
    if (bigComms.includes(commCode))  return ['BSP','BPJ','BCR'];
    if (medComms.includes(commCode))  return ['BSP','BPJ'];
    return ['BSP'];
  };

  let count = 0;
  for (const [commCode, commId] of Object.entries(commIds)) {
    const sigles = unitsForComm(commCode);
    for (const sigle of sigles) {
      const code = `${commCode}-${sigle}`;
      await prisma.unite.upsert({
        where:  { code },
        update: {},
        create: {
          nom:           SIGLE_NOM[sigle]!,
          sigle,
          code,
          commissariatId: commId,
          actif:         true,
          updatedAt:     new Date(),
        },
      });
      count++;
    }
  }
  console.log(`     ${count} unités créées/ignorées`);
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. Grades (12)
// ─────────────────────────────────────────────────────────────────────────────
async function seedGrades() {
  console.log('  -> Grades (12)...');
  const defs = [
    { code: 'GARDIEN_DE_LA_PAIX_2CL',   nom: 'Gardien de la Paix 2e Classe',    sigle: 'GP2', niveau: 1,  categorie: 'Gardien'          },
    { code: 'GARDIEN_DE_LA_PAIX_1CL',   nom: 'Gardien de la Paix 1re Classe',   sigle: 'GP1', niveau: 2,  categorie: 'Gardien'          },
    { code: 'BRIGADIER',                 nom: 'Brigadier',                        sigle: 'BRG', niveau: 3,  categorie: 'Sous-officier'    },
    { code: 'BRIGADIER_CHEF',            nom: 'Brigadier-Chef',                   sigle: 'BCH', niveau: 4,  categorie: 'Sous-officier'    },
    { code: 'INSPECTEUR',                nom: 'Inspecteur',                       sigle: 'INS', niveau: 5,  categorie: 'Officier'         },
    { code: 'INSPECTEUR_PRINCIPAL',      nom: 'Inspecteur Principal',             sigle: 'INP', niveau: 6,  categorie: 'Officier'         },
    { code: 'COMMISSAIRE',               nom: 'Commissaire',                      sigle: 'COM', niveau: 7,  categorie: 'Officier'         },
    { code: 'COMMISSAIRE_PRINCIPAL',     nom: 'Commissaire Principal',            sigle: 'CMP', niveau: 8,  categorie: 'Off. supérieur'   },
    { code: 'COMMISSAIRE_DIVISIONNAIRE', nom: 'Commissaire Divisionnaire',        sigle: 'CDV', niveau: 9,  categorie: 'Off. supérieur'   },
    { code: 'DIRECTEUR_DEPARTEMENTAL',   nom: 'Directeur Départemental',          sigle: 'DDT', niveau: 10, categorie: 'Direction'        },
    { code: 'DIRECTEUR_CENTRAL',         nom: 'Directeur Central',                sigle: 'DCT', niveau: 11, categorie: 'Direction'        },
    { code: 'DIRECTEUR_GENERAL_ADJOINT', nom: 'Directeur Général Adjoint',        sigle: 'DGA', niveau: 11, categorie: 'Direction'        },
    { code: 'DIRECTEUR_GENERAL',         nom: 'Directeur Général',                sigle: 'DGN', niveau: 12, categorie: 'Direction'        },
  ];
  const result: Record<string, string> = {};
  for (const g of defs) {
    const grade = await prisma.grade.upsert({
      where:  { code: g.code },
      update: {},
      create: { nom: g.nom, code: g.code, sigle: g.sigle, niveau: g.niveau, categorie: g.categorie, actif: true },
    });
    result[g.code] = grade.id;
  }
  console.log(`     ${defs.length} grades créés/ignorés`);
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. AppRoles (8) + Permissions (15) + RolePermissions
// ─────────────────────────────────────────────────────────────────────────────
async function seedRBACData() {
  console.log('  -> AppRoles (8) + Permissions (15)...');

  const roles = [
    { code: 'SUPERADMIN',      nom: 'Super Administrateur',       description: 'Accès total à toutes les fonctionnalités' },
    { code: 'DIRECTEUR',       nom: 'Directeur',                   description: 'Direction générale/nationale' },
    { code: 'COMMISSAIRE',     nom: 'Commissaire',                 description: 'Chef de commissariat' },
    { code: 'CHEF_UNITE',      nom: 'Chef d\'Unité',               description: 'Responsable d\'une unité opérationnelle' },
    { code: 'SUPERVISEUR',     nom: 'Superviseur',                  description: 'Supervision des agents' },
    { code: 'AGENT_TERRAIN',   nom: 'Agent de Terrain',            description: 'Agent opérationnel sur le terrain' },
    { code: 'GESTIONNAIRE_RH', nom: 'Gestionnaire RH',             description: 'Gestion des ressources humaines' },
    { code: 'LECTEUR',         nom: 'Lecteur',                     description: 'Accès en lecture seule' },
  ];

  const permissions = [
    { code: 'officers:create',     nom: 'Créer des agents' },
    { code: 'officers:read',       nom: 'Lire les agents' },
    { code: 'officers:update',     nom: 'Modifier des agents' },
    { code: 'officers:delete',     nom: 'Supprimer des agents' },
    { code: 'fines:create',        nom: 'Créer des amendes' },
    { code: 'fines:read',          nom: 'Lire les amendes' },
    { code: 'fines:update',        nom: 'Modifier des amendes' },
    { code: 'payments:read',       nom: 'Lire les paiements' },
    { code: 'payments:confirm',    nom: 'Confirmer les paiements' },
    { code: 'commissariats:read',  nom: 'Lire les commissariats' },
    { code: 'commissariats:write', nom: 'Gérer les commissariats' },
    { code: 'stats:read',          nom: 'Accéder aux statistiques' },
    { code: 'sanctions:create',    nom: 'Créer des sanctions' },
    { code: 'reports:export',      nom: 'Exporter des rapports' },
    { code: 'system:audit',        nom: 'Accéder aux journaux d\'audit' },
  ];

  const roleIds: Record<string, string> = {};
  const permIds: Record<string, string> = {};

  for (const r of roles) {
    const role = await prisma.appRole.upsert({
      where:  { code: r.code },
      update: {},
      create: { nom: r.nom, code: r.code, description: r.description, actif: true },
    });
    roleIds[r.code] = role.id;
  }
  for (const p of permissions) {
    const perm = await prisma.permission.upsert({
      where:  { code: p.code },
      update: {},
      create: { nom: p.nom, code: p.code },
    });
    permIds[p.code] = perm.id;
  }

  // Mappages rôle → permissions
  const mappings: Record<string, string[]> = {
    SUPERADMIN:      Object.keys(permIds),
    DIRECTEUR:       ['officers:read','officers:update','fines:read','fines:update','payments:read','commissariats:read','commissariats:write','stats:read','sanctions:create','reports:export','system:audit'],
    COMMISSAIRE:     ['officers:read','officers:update','fines:read','fines:update','payments:read','commissariats:read','stats:read','sanctions:create'],
    CHEF_UNITE:      ['officers:read','fines:create','fines:read','fines:update','payments:read','stats:read'],
    SUPERVISEUR:     ['officers:read','fines:read','fines:update','payments:read','stats:read'],
    AGENT_TERRAIN:   ['fines:create','fines:read','payments:read'],
    GESTIONNAIRE_RH: ['officers:create','officers:read','officers:update','officers:delete'],
    LECTEUR:         ['officers:read','fines:read','payments:read','commissariats:read','stats:read'],
  };

  for (const [roleCode, perms] of Object.entries(mappings)) {
    for (const permCode of perms) {
      const rid = roleIds[roleCode];
      const pid = permIds[permCode];
      if (!rid || !pid) continue;
      await prisma.rolePermission.upsert({
        where:  { appRoleId_permissionId: { appRoleId: rid, permissionId: pid } },
        update: {},
        create: { appRoleId: rid, permissionId: pid },
      });
    }
  }
  console.log('     RBAC configuré');
}

// ─────────────────────────────────────────────────────────────────────────────
// 9. Types d'infractions — Code de la route Congo Brazzaville (ekolo242.cg)
// ─────────────────────────────────────────────────────────────────────────────
async function seedInfractionTypes() {
  console.log("  -> Types d'infractions (liste complète Congo)...");
  const defs = [
    // ── VITESSE ──────────────────────────────────────────────────────────────
    { code: 'VIT-01', libelle: 'Excès de vitesse (1 à 20 km/h au-dessus de la limite)',         montant: 12000  },
    { code: 'VIT-02', libelle: 'Excès de vitesse (21 à 40 km/h au-dessus de la limite)',        montant: 24000  },
    { code: 'VIT-03', libelle: 'Excès de vitesse (41 à 60 km/h au-dessus de la limite)',        montant: 48000  },
    { code: 'VIT-04', libelle: 'Excès de vitesse (plus de 60 km/h au-dessus de la limite)',     montant: 96000  },
    { code: 'VIT-05', libelle: 'Vitesse excessive en agglomération (80+ km/h)',                   montant: 48000  },
    { code: 'VIT-06', libelle: 'Vitesse excessive à l\'approche d\'un passage piéton',           montant: 24000  },

    // ── ALCOOL & STUPÉFIANTS ─────────────────────────────────────────────────
    { code: 'ALC-01', libelle: 'Conduite sous l\'emprise de l\'alcool (taux entre 0,5 et 0,8 g/L)', montant: 50000  },
    { code: 'ALC-02', libelle: 'Conduite sous l\'emprise de l\'alcool (taux supérieur à 0,8 g/L)',   montant: 100000 },
    { code: 'ALC-03', libelle: 'Refus de se soumettre au test alcoolémie',                       montant: 100000 },
    { code: 'STU-01', libelle: 'Conduite sous l\'emprise de stupéfiants',                        montant: 150000 },
    { code: 'STU-02', libelle: 'Refus de se soumettre au dépistage de stupéfiants',             montant: 150000 },

    // ── DOCUMENTS DE BORD ────────────────────────────────────────────────────
    { code: 'DOC-01', libelle: 'Conduite sans permis de conduire (absence totale)',              montant: 24000  },
    { code: 'DOC-02', libelle: 'Permis de conduire périmé',                                      montant: 12000  },
    { code: 'DOC-03', libelle: 'Permis de conduire non adapté à la catégorie du véhicule',      montant: 24000  },
    { code: 'DOC-04', libelle: 'Défaut de carte grise (certificat d\'immatriculation)',          montant: 24000  },
    { code: 'DOC-05', libelle: 'Carte grise périmée ou non conforme',                            montant: 12000  },
    { code: 'DOC-06', libelle: 'Défaut d\'assurance responsabilité civile',                      montant: 24000  },
    { code: 'DOC-07', libelle: 'Assurance expirée',                                              montant: 24000  },
    { code: 'DOC-08', libelle: 'Défaut de visite technique obligatoire',                         montant: 12000  },
    { code: 'DOC-09', libelle: 'Visite technique expirée',                                       montant: 12000  },
    { code: 'DOC-10', libelle: 'Défaut de certificat de conformité pour véhicule importé',      montant: 24000  },

    // ── ÉQUIPEMENTS & SIGNALISATION VÉHICULE ────────────────────────────────
    { code: 'EQU-01', libelle: 'Feux de position non conformes ou manquants',                   montant: 12000  },
    { code: 'EQU-02', libelle: 'Feux de croisement (codes) non conformes ou hors d\'usage',    montant: 12000  },
    { code: 'EQU-03', libelle: 'Feux de route non conformes',                                   montant: 12000  },
    { code: 'EQU-04', libelle: 'Feux stop non conformes ou défectueux',                         montant: 12000  },
    { code: 'EQU-05', libelle: 'Feux de recul non conformes ou absents',                        montant: 12000  },
    { code: 'EQU-06', libelle: 'Feux de brouillard avant non conformes',                        montant: 12000  },
    { code: 'EQU-07', libelle: 'Feux de brouillard arrière non conformes',                      montant: 12000  },
    { code: 'EQU-08', libelle: 'Clignotants ou indicateurs de direction défectueux',            montant: 12000  },
    { code: 'EQU-09', libelle: 'Plaque d\'immatriculation illisible, absente ou non conforme', montant: 24000  },
    { code: 'EQU-10', libelle: 'Rétroviseurs manquants ou défectueux',                          montant: 12000  },
    { code: 'EQU-11', libelle: 'Klaxon défectueux ou absent',                                   montant: 12000  },
    { code: 'EQU-12', libelle: 'Essuie-glaces défectueux ou absents',                           montant: 12000  },
    { code: 'EQU-13', libelle: 'Pneumatiques (pneus) non conformes ou usés',                    montant: 24000  },
    { code: 'EQU-14', libelle: 'Freins défectueux (bruits, efficacité insuffisante)',            montant: 24000  },
    { code: 'EQU-15', libelle: 'Extincteur absent dans un véhicule de transport en commun',     montant: 12000  },
    { code: 'EQU-16', libelle: 'Triangle de signalisation absent ou défectueux',                montant: 12000  },

    // ── CEINTURE & PROTECTION CORPORELLE ────────────────────────────────────
    { code: 'CEI-01', libelle: 'Non-port de la ceinture de sécurité (conducteur)',              montant: 12000  },
    { code: 'CEI-02', libelle: 'Non-port de la ceinture de sécurité (passager avant)',          montant: 12000  },
    { code: 'CEI-03', libelle: 'Enfant non attaché ou sans dispositif de retenue adapté',       montant: 12000  },

    // ── DEUX-ROUES & MOTOCYCLES ──────────────────────────────────────────────
    { code: 'MOT-01', libelle: 'Non-port du casque homologué (conducteur moto)',                 montant: 6000   },
    { code: 'MOT-02', libelle: 'Non-port du casque homologué (passager moto)',                   montant: 6000   },
    { code: 'MOT-03', libelle: 'Transport de passager en surnombre sur deux-roues',             montant: 12000  },
    { code: 'MOT-04', libelle: 'Chargement non conforme sur deux-roues (charge excessive)',     montant: 12000  },
    { code: 'MOT-05', libelle: 'Conduite de moto sans permis de catégorie A',                   montant: 24000  },
    { code: 'MOT-06', libelle: 'Moto sans éclairage ou signalisation réglementaire',            montant: 12000  },
    { code: 'MOT-07', libelle: 'Conduite de moto par mineur de moins de 18 ans',               montant: 24000  },

    // ── COMPORTEMENT AU VOLANT ───────────────────────────────────────────────
    { code: 'COM-01', libelle: 'Usage du téléphone portable au volant (tenu en main)',          montant: 12000  },
    { code: 'COM-02', libelle: 'Non-respect du feu rouge ou du feu orange',                     montant: 24000  },
    { code: 'COM-03', libelle: 'Non-respect du panneau STOP',                                   montant: 24000  },
    { code: 'COM-04', libelle: 'Circulation en sens interdit',                                   montant: 24000  },
    { code: 'COM-05', libelle: 'Non-respect de la priorité à droite',                           montant: 12000  },
    { code: 'COM-06', libelle: 'Non-respect d\'un panneau de cédez-le-passage',                 montant: 12000  },
    { code: 'COM-07', libelle: 'Dépassement dangereux ou interdit',                             montant: 24000  },
    { code: 'COM-08', libelle: 'Non-respect de la distance de sécurité',                        montant: 12000  },
    { code: 'COM-09', libelle: 'Demi-tour interdit ou dangereux',                               montant: 12000  },
    { code: 'COM-10', libelle: 'Circulation sur voie réservée (bus, urgences)',                 montant: 12000  },
    { code: 'COM-11', libelle: 'Non-respect d\'un passage à niveau (franchissement barrière)',  montant: 48000  },
    { code: 'COM-12', libelle: 'Conduite en zigzag ou manœuvre dangereuse',                     montant: 24000  },
    { code: 'COM-13', libelle: 'Non-priorité accordée aux piétons sur passage protégé',        montant: 12000  },
    { code: 'COM-14', libelle: 'Non-priorité accordée aux véhicules d\'urgence (sirène)',      montant: 24000  },
    { code: 'COM-15', libelle: 'Fuite après accident (délit de fuite)',                         montant: 96000  },

    // ── STATIONNEMENT ────────────────────────────────────────────────────────
    { code: 'STA-01', libelle: 'Stationnement sur trottoir ou accotement (gênant piétons)',    montant: 6000   },
    { code: 'STA-02', libelle: 'Stationnement en double file bloquant la circulation',         montant: 12000  },
    { code: 'STA-03', libelle: 'Stationnement sur passage piéton ou à proximité',              montant: 12000  },
    { code: 'STA-04', libelle: 'Stationnement devant un accès pompiers ou hydrant',            montant: 12000  },
    { code: 'STA-05', libelle: 'Stationnement sur emplacement réservé (handicapés)',           montant: 24000  },
    { code: 'STA-06', libelle: 'Stationnement sur carrefour ou giratoire',                     montant: 12000  },
    { code: 'STA-07', libelle: 'Stationnement dans une zone d\'arrêt de bus',                  montant: 12000  },
    { code: 'STA-08', libelle: 'Arrêt ou stationnement dangereux sur la chaussée',             montant: 12000  },

    // ── SURCHARGE & GABARIT ──────────────────────────────────────────────────
    { code: 'SUR-01', libelle: 'Surcharge de poids (véhicule léger, dépassement < 20 %)',     montant: 24000  },
    { code: 'SUR-02', libelle: 'Surcharge de poids (véhicule léger, dépassement > 20 %)',     montant: 48000  },
    { code: 'SUR-03', libelle: 'Surcharge de poids (poids lourd, dépassement < 20 %)',        montant: 48000  },
    { code: 'SUR-04', libelle: 'Surcharge de poids (poids lourd, dépassement > 20 %)',        montant: 96000  },
    { code: 'SUR-05', libelle: 'Dépassement de gabarit en largeur (chargement)',               montant: 48000  },
    { code: 'SUR-06', libelle: 'Dépassement de gabarit en hauteur (chargement)',               montant: 48000  },
    { code: 'SUR-07', libelle: 'Chargement non arrimé (risque de chute)',                      montant: 24000  },

    // ── TRANSPORT EN COMMUN ──────────────────────────────────────────────────
    { code: 'TPC-01', libelle: 'Transport en commun sans autorisation de service (licence)',   montant: 48000  },
    { code: 'TPC-02', libelle: 'Nombre de passagers supérieur à la capacité autorisée',       montant: 24000  },
    { code: 'TPC-03', libelle: 'Transport de passagers debout en zone non autorisée',          montant: 24000  },
    { code: 'TPC-04', libelle: 'Taxis sans compteur conforme ou tarifaire',                    montant: 12000  },
    { code: 'TPC-05', libelle: 'Minibus/bus en mauvais état mécanique ou de carrosserie',     montant: 24000  },
    { code: 'TPC-06', libelle: 'Taxi non identifié (absence de plaque taxi, couleurs)',        montant: 12000  },

    // ── DÉPANNAGE & REMORQUAGE ───────────────────────────────────────────────
    { code: 'DEP-01', libelle: 'Véhicule en panne sans signalisation (triangle absent)',       montant: 12000  },
    { code: 'DEP-02', libelle: 'Remorquage non réglementaire (câble nu, absence de lumières)', montant: 24000  },
    { code: 'DEP-03', libelle: 'Dépannage sans gilet de sécurité haute visibilité',           montant: 12000  },
    { code: 'DEP-04', libelle: 'Remorque sans éclairage ni plaque réglementaire',             montant: 12000  },
    { code: 'DEP-05', libelle: 'Véhicule de dépannage sans feux spéciaux réglementaires',    montant: 24000  },

    // ── PIÉTONS & USAGERS VULNÉRABLES ───────────────────────────────────────
    { code: 'PIE-01', libelle: 'Traversée de la chaussée hors passage piéton',                montant: 6000   },
    { code: 'PIE-02', libelle: 'Cycliste sans éclairage de nuit',                              montant: 6000   },
    { code: 'PIE-03', libelle: 'Cycliste circulant sur trottoir interdit',                     montant: 6000   },

    // ── POLLUTION & NUISANCES ────────────────────────────────────────────────
    { code: 'POL-01', libelle: 'Véhicule présentant des émissions visibles excessives (fumées noires)', montant: 12000  },
    { code: 'POL-02', libelle: 'Usage du klaxon en zone de silence (hôpitaux, écoles)',       montant: 12000  },
    { code: 'POL-03', libelle: 'Jet de déchets sur la voie publique depuis un véhicule',      montant: 12000  },
  ];

  for (const inf of defs) {
    await prisma.infractionType.upsert({
      where:  { code: inf.code },
      update: { libelle: inf.libelle, montantBase: inf.montant },
      create: { code: inf.code, libelle: inf.libelle, montantBase: inf.montant, actif: true },
    });
  }
  console.log(`     ${defs.length} infractions créées/mises à jour`);
}

// ─────────────────────────────────────────────────────────────────────────────
// 10. Utilisateurs de démonstration
// ─────────────────────────────────────────────────────────────────────────────
async function seedUsers(
  deptIds:  Record<string, string>,
  gradeIds: Record<string, string>,
  commIds:  Record<string, string>,
) {
  console.log('  -> Utilisateurs de démonstration...');
  const pinHash = await bcrypt.hash(DEMO_PIN, PIN_ROUNDS);

  const users: {
    email: string; name: string; role: 'ADMIN'|'POLICE'|'CITOYEN';
    gradeCode?: string; niveauHierarchique?: string;
    deptCode?: string; commCode?: string; badgeNumber?: string; telephone?: string;
  }[] = [
    { email: 'admin@pnc.cg',         name: 'Directeur Général PNC',            role: 'ADMIN',  gradeCode: 'DIRECTEUR_GENERAL',        niveauHierarchique: 'DIRECTION_GENERALE' },
    { email: 'dir.bzv@pnc.cg',       name: 'Directeur Dept Brazzaville',       role: 'ADMIN',  gradeCode: 'COMMISSAIRE_DIVISIONNAIRE',  niveauHierarchique: 'DIRECTION_DEPT',  deptCode: 'BRAZZAVILLE' },
    { email: 'comm.moungali@pnc.cg', name: 'Commissaire Moungali',             role: 'ADMIN',  gradeCode: 'COMMISSAIRE_PRINCIPAL',      niveauHierarchique: 'COMMISSARIAT_CENTRAL', deptCode: 'BRAZZAVILLE', commCode: 'CC-BZV-04', badgeNumber: 'PNC-ADM-2024-001' },
    { email: 'agent1@pnc.cg',        name: 'Jean Mbemba',                      role: 'POLICE', gradeCode: 'INSPECTEUR',                 niveauHierarchique: 'AGENT',           deptCode: 'BRAZZAVILLE', commCode: 'CC-BZV-09', badgeNumber: 'PNC-2024-001', telephone: '+242066001001' },
    { email: 'agent2@pnc.cg',        name: 'Aline Okemba',                     role: 'POLICE', gradeCode: 'INSPECTEUR_PRINCIPAL',       niveauHierarchique: 'AGENT',           deptCode: 'BRAZZAVILLE', commCode: 'CC-BZV-04', badgeNumber: 'PNC-2024-002', telephone: '+242066001002' },
    { email: 'agent3@pnc.cg',        name: 'Patrick Loubota',                  role: 'POLICE', gradeCode: 'BRIGADIER',                  niveauHierarchique: 'AGENT',           deptCode: 'BRAZZAVILLE', commCode: 'CC-BZV-06', badgeNumber: 'PNC-2024-003', telephone: '+242066001003' },
    { email: 'citoyen1@gmail.com',   name: 'Marie Samba',                      role: 'CITOYEN', telephone: '+242055001001' },
    { email: 'citoyen2@gmail.com',   name: 'Thomas Ngolo',                     role: 'CITOYEN', telephone: '+242055001002' },
  ];

  for (const u of users) {
    await prisma.user.upsert({
      where:  { email: u.email },
      update: {},
      create: {
        email:              u.email,
        pinHash,
        name:               u.name,
        role:               u.role,
        gradeId:            u.gradeCode  ? gradeIds[u.gradeCode]  : null,
        departementId:      u.deptCode   ? deptIds[u.deptCode]    : null,
        commissariatId:     u.commCode   ? commIds[u.commCode]    : null,
        niveauHierarchique: (u.niveauHierarchique as any) ?? 'AGENT',
        badgeNumber:        u.badgeNumber  ?? null,
        telephone:          u.telephone    ?? null,
        mustChangePassword: false,
        emailVerified:      true,
        actif:              true,
      },
    });
  }
  console.log('     8 utilisateurs créés/ignorés');
}

// ─────────────────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────────────────
async function main() {
  console.log('\nSeed PNC Congo (v2 FK) — début\n');

  const dgpn     = await seedDirectionGenerale();
  await seedDirectionsNationales(dgpn.id);

  const deptIds  = await seedDepartements();
  const ddIds    = await seedDirectionsDepartementales(deptIds);
  const commIds  = await seedCommissariats(deptIds, ddIds);
  await seedUnites(commIds);

  const gradeIds = await seedGrades();
  await seedRBACData();
  await seedInfractionTypes();
  await seedUsers(deptIds, gradeIds, commIds);

  console.log('\nSeed terminé avec succès!\n');
  console.log('Comptes démo (PIN: Admin@1234!) :');
  console.log('  admin@pnc.cg          ADMIN  Direction Générale');
  console.log('  dir.bzv@pnc.cg        ADMIN  Direction Dept Brazzaville');
  console.log('  comm.moungali@pnc.cg  ADMIN  Commissariat Moungali');
  console.log('  agent1@pnc.cg         POLICE Poto-Poto       (PNC-2024-001)');
  console.log('  agent2@pnc.cg         POLICE Moungali        (PNC-2024-002)');
  console.log('  agent3@pnc.cg         POLICE Talangaï        (PNC-2024-003)');
  console.log('  citoyen1@gmail.com    CITOYEN');
  console.log('  citoyen2@gmail.com    CITOYEN\n');
}

main()
  .catch((e) => {
    console.error('\nSeed échoué :', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
