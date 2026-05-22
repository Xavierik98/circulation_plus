import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

const infractions = await prisma.infractionType.findMany({ orderBy: { code: 'asc' } });
console.log('\n=== TOTAL infractions en base :', infractions.length, '===\n');

// Afficher par catégorie
const cats = [...new Set(infractions.map(i => i.code.substring(0,3)))];
for (const cat of cats) {
  const list = infractions.filter(i => i.code.startsWith(cat));
  console.log(`\n--- Catégorie ${cat} (${list.length} infractions) ---`);
  list.forEach(i => {
    console.log(`  ${i.code} | ${i.label.substring(0,50).padEnd(50)} | Amende: ${i.montantBase} XAF | +1000 dev = Total: ${i.montantBase + 1000} XAF`);
  });
}

const min = Math.min(...infractions.map(i => i.montantBase));
const max = Math.max(...infractions.map(i => i.montantBase));
console.log('\n=== RÉSUMÉ ===');
console.log(`Amende min : ${min} XAF  →  citoyen paie : ${min + 1000} XAF`);
console.log(`Amende max : ${max} XAF  →  citoyen paie : ${max + 1000} XAF`);
console.log(`Part développeur : 1 000 XAF fixe sur CHAQUE contravention`);

await prisma.$disconnect();
