import { beforeEach, afterAll } from 'vitest';
import { prisma } from '../src/config/database';
import { redis } from '../src/config/redis';

// ── Données de référence injectées après chaque truncate ─────────────────────

const DEPARTEMENTS = [
  { code: 'BRAZZAVILLE',   nom: 'Brazzaville',       chefLieu: 'Brazzaville'  },
  { code: 'POINTE_NOIRE',  nom: 'Pointe-Noire',       chefLieu: 'Pointe-Noire' },
  { code: 'POOL',          nom: 'Pool',                chefLieu: 'Kinkala'      },
  { code: 'BOUENZA',       nom: 'Bouenza',             chefLieu: 'Madingou'     },
  { code: 'NIARI',         nom: 'Niari',               chefLieu: 'Dolisie'      },
  { code: 'LEKOUMOU',      nom: 'Lékoumou',            chefLieu: 'Sibiti'       },
  { code: 'KOUILOU',       nom: 'Kouilou',             chefLieu: 'Hinda'        },
  { code: 'PLATEAUX',      nom: 'Plateaux',            chefLieu: 'Djambala'     },
  { code: 'CUVETTE',       nom: 'Cuvette',             chefLieu: 'Owando'       },
  { code: 'CUVETTE_OUEST', nom: 'Cuvette-Ouest',       chefLieu: 'Ewo'          },
  { code: 'SANGHA',        nom: 'Sangha',              chefLieu: 'Ouesso'       },
  { code: 'LIKOUALA',      nom: 'Likouala',            chefLieu: 'Impfondo'     },
];

const GRADES = [
  { code: 'GARDIEN_DE_LA_PAIX_2CL',   nom: 'Gardien de la Paix 2e Classe',    niveau: 1,  categorie: 'Gardien'          },
  { code: 'GARDIEN_DE_LA_PAIX_1CL',   nom: 'Gardien de la Paix 1re Classe',   niveau: 2,  categorie: 'Gardien'          },
  { code: 'BRIGADIER',                 nom: 'Brigadier',                        niveau: 3,  categorie: 'Sous-officier'    },
  { code: 'BRIGADIER_CHEF',            nom: 'Brigadier-Chef',                   niveau: 4,  categorie: 'Sous-officier'    },
  { code: 'INSPECTEUR',                nom: 'Inspecteur',                       niveau: 5,  categorie: 'Officier'         },
  { code: 'INSPECTEUR_PRINCIPAL',      nom: 'Inspecteur Principal',             niveau: 6,  categorie: 'Officier'         },
  { code: 'COMMISSAIRE',               nom: 'Commissaire',                      niveau: 7,  categorie: 'Officier'         },
  { code: 'COMMISSAIRE_PRINCIPAL',     nom: 'Commissaire Principal',            niveau: 8,  categorie: 'Off. supérieur'   },
  { code: 'COMMISSAIRE_DIVISIONNAIRE', nom: 'Commissaire Divisionnaire',        niveau: 9,  categorie: 'Off. supérieur'   },
  { code: 'DIRECTEUR_DEPARTEMENTAL',   nom: 'Directeur Départemental',          niveau: 10, categorie: 'Direction'        },
  { code: 'DIRECTEUR_CENTRAL',         nom: 'Directeur Central',                niveau: 11, categorie: 'Direction'        },
  { code: 'DIRECTEUR_GENERAL_ADJOINT', nom: 'Directeur Général Adjoint',        niveau: 11, categorie: 'Direction'        },
  { code: 'DIRECTEUR_GENERAL',         nom: 'Directeur Général',                niveau: 12, categorie: 'Direction'        },
];

async function seedRefData() {
  // Seed departements
  for (const d of DEPARTEMENTS) {
    await prisma.departement.upsert({
      where:  { code: d.code },
      update: {},
      create: { id: `dept-${d.code}`, nom: d.nom, code: d.code, chefLieu: d.chefLieu, updatedAt: new Date() },
    });
  }

  // Seed grades
  for (const g of GRADES) {
    await prisma.grade.upsert({
      where:  { code: g.code },
      update: {},
      create: { id: `grade-${g.code}`, nom: g.nom, code: g.code, niveau: g.niveau, categorie: g.categorie },
    });
  }
}

// Isolation : on vide toutes les tables et Redis avant chaque test,
// puis on ré-injecte les données de référence statiques (grades, départements).
beforeEach(async () => {
  const tables = await prisma.$queryRaw<{ tablename: string }[]>`
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public' AND tablename <> '_prisma_migrations'`;
  if (tables.length > 0) {
    const list = tables.map((t) => `"public"."${t.tablename}"`).join(', ');
    await prisma.$executeRawUnsafe(
      `TRUNCATE ${list} RESTART IDENTITY CASCADE`,
    );
  }
  await redis.flushdb();
  await seedRefData();
});

afterAll(async () => {
  await prisma.$disconnect();
  redis.disconnect();
});
