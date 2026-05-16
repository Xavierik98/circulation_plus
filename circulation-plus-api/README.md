# Circulation+ API

Backend de gestion des contraventions routières — Police Nationale du Congo-Brazzaville.

Stack : Node.js 20, Fastify, TypeScript (strict), Prisma, PostgreSQL 16, Redis 7.

## Démarrage (Docker)

```bash
cp .env.example .env
docker-compose up -d
docker-compose exec api npx prisma migrate deploy
docker-compose exec api npx prisma db seed
```

## Démarrage (local)

Nécessite PostgreSQL 16 et Redis 7 accessibles (voir `DATABASE_URL` / `REDIS_URL` dans `.env`).

```bash
cp .env.example .env
npm install
npx prisma migrate dev --name init
npx prisma db seed
npm run dev
```

Vérification :

```bash
curl http://localhost:3000/api/infractions   # { "success": true, "data": [ ...15 infractions ] }
curl http://localhost:3000/docs               # Documentation Swagger (HTML)
curl http://localhost:3000/health             # { "success": true, "data": { "status": "ok" } }
```

## Comptes seed (PIN par défaut)

| Rôle    | Email             | PIN  | Badge        |
|---------|-------------------|------|--------------|
| ADMIN   | admin@pnc.cg      | 0000 | —            |
| POLICE  | agent1@pnc.cg     | 0000 | PNC-2024-001 |
| POLICE  | agent2@pnc.cg     | 0000 | PNC-2024-002 |
| POLICE  | agent3@pnc.cg     | 0000 | PNC-2024-003 |
| CITOYEN | citoyen1@pnc.cg   | 0000 | —            |
| CITOYEN | citoyen2@pnc.cg   | 0000 | —            |

## Mode stub (sans credentials)

Si les variables d'environnement d'un fournisseur externe (Africa's Talking, CinetPay,
Firebase, Cloudflare R2) sont vides, l'adaptateur correspondant bascule automatiquement
en mode stub journalisé. Le projet démarre et la chaîne complète (verbalisation →
paiement → répartition → PDF) fonctionne **sans aucune clé**.

## Tests

```bash
npm test
```

Nécessite une base PostgreSQL de test (`DATABASE_URL` de test) et Redis.
