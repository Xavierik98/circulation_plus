# Circulation+ — Guide d'intégration Backend ↔ Flutter

Ce document est destiné à l'équipe Flutter qui reprend le travail après l'ajout du backend.
Il explique **ce qui a changé**, **pourquoi**, et **comment travailler avec la nouvelle couche data**.

---

## 1. Architecture globale

```
circulation_plus/
├── lib/                        ← Flutter (inchangé côté écrans)
│   ├── data/
│   │   ├── api_client.dart     ← Dio + intercepteurs JWT + unwrap enveloppe
│   │   ├── mappers.dart        ← JSON backend (FR) → modèles Flutter (EN)
│   │   ├── repositories.dart   ← Accès HTTP par domaine métier
│   │   └── providers.dart      ← Providers Riverpod consommés par les écrans
│   └── features/               ← Écrans (quasi-inchangés visuellement)
│
└── circulation-plus-api/       ← Backend Node/Fastify (NOUVEAU)
    ├── prisma/
    │   ├── schema.prisma
    │   └── seed.ts
    ├── src/
    │   ├── app.ts              ← Factory Fastify (tests + prod)
    │   ├── server.ts           ← Point d'entrée
    │   ├── adapters/           ← SMS / Push / Storage / Paiement (réel ou stub)
    │   ├── config/             ← env.ts (Zod), database, redis
    │   └── modules/            ← auth, fines, payments, officers, stats…
    ├── tests/                  ← Vitest (17 tests)
    └── docker-compose.yml
```

---

## 2. Démarrer le backend (5 commandes)

```bash
cd circulation-plus-api

# 1. Lancer Postgres 16 + Redis 7
docker-compose up -d

# 2. Copier les variables d'environnement
cp .env.example .env
# (aucune clé externe requise — tout tourne en mode stub)

# 3. Créer les tables
npx prisma migrate dev --name init

# 4. Injecter les données de démo
npx prisma db seed

# 5. Lancer l'API
npm run dev
# → http://localhost:3000
```

Vérification rapide :

```bash
curl http://localhost:3000/health
# {"status":"ok","timestamp":"…"}

curl http://localhost:3000/api/infractions | jq '.data | length'
# 15
```

Documentation Swagger interactive : **http://localhost:3000/docs**

---

## 3. Comptes de démonstration (seed)

| Rôle    | Email               | PIN  | Badge         |
|---------|---------------------|------|---------------|
| ADMIN   | admin@pnc.cg        | 0000 | —             |
| POLICE  | agent1@pnc.cg       | 0000 | PNC-2024-001  |
| POLICE  | agent2@pnc.cg       | 0000 | PNC-2024-002  |
| POLICE  | agent3@pnc.cg       | 0000 | PNC-2024-003  |
| CITOYEN | citoyen1@pnc.cg     | 0000 | —             |
| CITOYEN | citoyen2@pnc.cg     | 0000 | —             |

---

## 4. Contrats API — ce que Flutter doit savoir

### 4.1 Enveloppe universelle

**Toutes** les réponses du backend respectent ce format :

```jsonc
// Succès
{ "success": true, "data": { … } }

// Erreur
{ "success": false, "error": "Message lisible", "code": "ERROR_CODE" }
```

`api_client.dart` déballe automatiquement cette enveloppe :
- retourne directement `data` en cas de succès
- lève une `ApiException(message, code)` en cas d'échec

**Vous n'avez jamais à lire `success` dans un écran** — le provider gère déjà l'état `error`.

### 4.2 Authentification

```
POST /api/auth/login
Body : { "email": "agent1@pnc.cg", "pin": "0000", "role": "POLICE" }

→ data: { "token": "<JWT 15min>", "refreshToken": "<JWT 7j>", "user": { … } }
```

Le token est stocké dans `FlutterSecureStorage` (clé `secure_access_token`).
`api_client.dart` l'injecte automatiquement sur chaque requête (`Authorization: Bearer …`).

Le refresh est **transparent** : si le token expire, le client tente automatiquement
`POST /api/auth/refresh` et rejoue la requête — l'écran ne voit rien.

### 4.3 Noms de champs backend vs modèles Flutter

Le backend utilise des noms **français** ; les modèles Flutter restent en **anglais**.
Les mappers dans `lib/data/mappers.dart` font la traduction :

| Backend (JSON)         | Flutter (modèle)       |
|------------------------|------------------------|
| `montantTotal`         | `amount`               |
| `verbaliseLe`          | `issuedAt`             |
| `dateEcheance`         | `deadline`             |
| `infractionType.code`  | `infractionCode`       |
| `statut: "EN_ATTENTE"` | `status: FineStatus.pending` |
| `driver.nom + prenom`  | `driverName`           |
| `vehicle.plaque`       | `vehiclePlate`         |
| `role: "POLICE"`       | `UserRole.police`      |

### 4.4 Pagination

Les listes paginées retournent :

```jsonc
{
  "success": true,
  "data": {
    "data": [ … ],   // les items
    "total": 42,
    "page": 1,
    "limit": 20
  }
}
```

Les repositories lisent `response['data']` pour extraire la liste.

---

## 5. La couche data Flutter — où tout se trouve

### `lib/data/api_client.dart`
Instance Dio unique. **Ne pas instancier Dio directement dans un écran.**

```dart
// Exemple d'appel brut (dans un repository)
final data = await ApiClient.instance.request(
  method: 'GET',
  path: '/api/fines',
  queryParameters: {'page': 1, 'limit': 20},
);
```

### `lib/data/repositories.dart`
Un repository par domaine :

| Classe               | Responsabilité                              |
|----------------------|---------------------------------------------|
| `AuthRepository`     | login, me, logout, session locale           |
| `FineRepository`     | liste PV, détail, création, PDF             |
| `OfficerRepository`  | liste agents, stats                         |
| `NotificationRepository` | liste notifications                     |
| `InfractionRepository` | catalogue (mis en cache 1h par le backend) |
| `DriverRepository`   | historique conducteur                       |
| `StatsRepository`    | revenus, heatmap (admin)                    |

### `lib/data/providers.dart`
Providers Riverpod à utiliser dans les `ConsumerWidget` :

```dart
// Dans un écran
final finesAsync = ref.watch(myFinesProvider);
final officers  = ref.watch(officersProvider('recherche'));
final notifs    = ref.watch(notificationsProvider);
final stats     = ref.watch(revenueStatsProvider);
```

---

## 6. Changement de flux de connexion

**Avant** : identifiant texte libre + code OTP mock (`1234`)
**Après** : email + PIN 4 chiffres (bcrypt côté backend)

Ce changement était **obligatoire** — le backend ne supporte que email+PIN.

L'écran `lib/features/auth/presentation/login_screen.dart` a été mis à jour :
- Champ email (clavier type `emailAddress`)
- Champ PIN (4 chiffres, `obscureText: true`)
- Bouton unique "Se connecter" (plus de flux OTP en deux étapes)
- Hint de démo : `admin@pnc.cg` / `0000`

Le routeur (`go_router`) est **inchangé** — la redirection par rôle fonctionne toujours.

---

## 7. Écrans rewirés vs encore sur mock

### ✅ Branchés sur le vrai backend

| Écran | Provider utilisé |
|-------|-----------------|
| Login | `authProvider` (email + PIN) |
| Citizen Dashboard | `myFinesProvider` |
| Citizen Notifications | `notificationsProvider` |
| Police Notifications | `notificationsProvider` |
| Police — Sélection infractions | `infractionsProvider` |
| Officers Management (admin) | `officersProvider` |

### ⏳ Encore sur données statiques (à faire)

| Écran | Fichier | Provider à brancher |
|-------|---------|---------------------|
| Détail PV citoyen | `fine_details_screen.dart` | `fineDetailProvider(id)` |
| Écran paiement | `payment_screen.dart` | `FineRepository.initiatePayment` |
| Reçu paiement | `receipt_screen.dart` | `fineDetailProvider` |
| Historique conducteur | `driver_history_screen.dart` | `DriverRepository.history` |
| Calcul amende (police) | `fine_calculation_screen.dart` | `FineRepository.create` |
| OCR preview | `ocr_preview_screen.dart` | `FineRepository.create` |
| Dashboard admin (graphes) | `admin_dashboard.dart` | `revenueStatsProvider` |

---

## 8. Configurer l'URL de l'API selon l'environnement

```bash
# Émulateur Android (localhost ne fonctionne pas dans l'émulateur)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Simulateur iOS / physique sur même réseau Wi-Fi
flutter run --dart-define=API_BASE_URL=http://192.168.1.X:3000

# Par défaut (web ou desktop local)
flutter run
# → utilise http://localhost:3000
```

La constante est définie dans `lib/core/constants/app_constants.dart`.

---

## 9. Services externes en mode stub (développement sans credentials)

Quand les variables d'environnement d'un service sont absentes ou vides, le backend
bascule automatiquement sur un stub journalisé. **Le projet tourne et répond correctement
sans aucune clé externe.**

| Service | Variable requise | Comportement stub |
|---------|-----------------|-------------------|
| SMS (Africa's Talking) | `AT_API_KEY` | Log console + `{ok:true}` |
| Push (FCM) | `FIREBASE_PROJECT_ID` | Log console |
| Stockage PDF (R2) | `R2_ACCOUNT_ID` | Fichier local dans `.storage-stub/` |
| Paiement (CinetPay) | `CINETPAY_API_KEY` | URL stub auto-confirmée |

Le paiement stub : `GET /__stub_pay/:ref` déclenche automatiquement le webhook
confirmant le paiement — la chaîne complète (Fine→PAID + Repartition) s'exécute
sans aucun accès à CinetPay.

---

## 10. Lancer les tests backend

```bash
cd circulation-plus-api

# Créer la DB de test (une seule fois)
createdb circulation_test

# Lancer les 17 tests
npm test
```

Les tests couvrent : auth (login OK, mauvais PIN, verrou 5 échecs, refresh),
fines (création, doublon 30min, RLS inter-agents), payments (signature webhook,
atomicité, somme Repartition exacte, idempotence).

---

## 11. Variables d'environnement — référence rapide

Fichier `.env` à créer depuis `.env.example` dans `circulation-plus-api/`.

**Requis pour lancer l'API :**
```env
NODE_ENV=development
PORT=3000
BASE_URL=http://localhost:3000
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/circulation_plus
REDIS_URL=redis://localhost:6379
JWT_SECRET=un-secret-de-32-caracteres-minimum
JWT_REFRESH_SECRET=un-autre-secret-de-32-caracteres
CORS_ORIGINS=http://localhost:3000,http://localhost:4000
PART_DEVELOPPEUR=1000
PART_AGENT=0
PART_POLICE=0
PART_TRESOR=0
DELAI_CONVOCATION_JOURS=14
DELAI_RELANCE_JOURS=7
```

**Optionnels (stub si absent) :**
```env
AT_USERNAME=
AT_API_KEY=
CINETPAY_API_KEY=
CINETPAY_SITE_ID=
FIREBASE_PROJECT_ID=
R2_ACCOUNT_ID=
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET=
```
