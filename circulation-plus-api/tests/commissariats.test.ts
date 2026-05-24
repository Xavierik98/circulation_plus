import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { makeApp, createUser, login, authHeader } from './helpers';

let app: FastifyInstance;

beforeAll(async () => {
  app = await makeApp();
});

afterAll(async () => {
  await app.close();
});

async function makeAdmin(
  email = 'admin@pnc.cg',
  pin = 'Test@1234!',
  niveau: 'DIRECTION_GENERALE' | 'DIRECTION_DEPT' = 'DIRECTION_GENERALE',
) {
  await createUser({ email, pin, role: 'ADMIN', name: 'Admin Test', niveauHierarchique: niveau });
  const { token } = await login(app, email, pin, 'admin');
  return token;
}

describe('Commissariats API', () => {
  describe('GET /api/commissariats', () => {
    it('ADMIN peut lister les commissariats', async () => {
      const token = await makeAdmin();

      const res = await app.inject({
        method: 'GET',
        url: '/api/commissariats',
        headers: authHeader(token),
      });

      expect(res.statusCode).toBe(200);
      const body = res.json();
      expect(body.success).toBe(true);
      expect(body.data.data).toBeInstanceOf(Array);
    });

    it('sans token -> 401', async () => {
      const res = await app.inject({ method: 'GET', url: '/api/commissariats' });
      expect(res.statusCode).toBe(401);
    });
  });

  describe('POST /api/commissariats', () => {
    it('DIRECTION_GENERALE peut creer un commissariat', async () => {
      const token = await makeAdmin('dg@pnc.cg', 'Test@1234!', 'DIRECTION_GENERALE');

      const res = await app.inject({
        method: 'POST',
        url: '/api/commissariats',
        headers: authHeader(token),
        payload: {
          nom: 'Commissariat Test',
          code: 'CC-TEST-001',
          departement: 'BRAZZAVILLE',
          lat: -4.2634,
          lng: 15.2429,
        },
      });

      expect(res.statusCode).toBe(200);
      const body = res.json();
      expect(body.data.code).toBe('CC-TEST-001');
      expect(body.data.actif).toBe(true);
    });

    it('code duplique -> 409 COMMISSARIAT_CODE_EXISTS', async () => {
      const token = await makeAdmin('dg@pnc.cg', 'Test@1234!', 'DIRECTION_GENERALE');

      await app.inject({
        method: 'POST',
        url: '/api/commissariats',
        headers: authHeader(token),
        payload: { nom: 'Premier', code: 'CC-DUP-001', departement: 'BRAZZAVILLE' },
      });

      const res = await app.inject({
        method: 'POST',
        url: '/api/commissariats',
        headers: authHeader(token),
        payload: { nom: 'Doublon', code: 'CC-DUP-001', departement: 'BRAZZAVILLE' },
      });

      expect(res.statusCode).toBe(409);
      expect(res.json().code).toBe('COMMISSARIAT_CODE_EXISTS');
    });

    it('DIRECTION_DEPT ne peut pas creer (403)', async () => {
      const token = await makeAdmin('dir.dept@pnc.cg', 'Test@1234!', 'DIRECTION_DEPT');

      const res = await app.inject({
        method: 'POST',
        url: '/api/commissariats',
        headers: authHeader(token),
        payload: { nom: 'Interdit', code: 'CC-INTERDIT-001', departement: 'POOL' },
      });

      expect(res.statusCode).toBe(403);
    });
  });

  describe('PATCH /api/commissariats/:id', () => {
    it('DIRECTION_GENERALE peut modifier un commissariat', async () => {
      const token = await makeAdmin('dg@pnc.cg', 'Test@1234!', 'DIRECTION_GENERALE');

      const created = await app.inject({
        method: 'POST',
        url: '/api/commissariats',
        headers: authHeader(token),
        payload: { nom: 'A Modifier', code: 'CC-MOD-001', departement: 'NIARI' },
      });
      const id = created.json().data.id as string;

      const res = await app.inject({
        method: 'PATCH',
        url: `/api/commissariats/${id}`,
        headers: authHeader(token),
        payload: { nom: 'Nom Modifie', actif: false },
      });

      expect(res.statusCode).toBe(200);
      expect(res.json().data.nom).toBe('Nom Modifie');
      expect(res.json().data.actif).toBe(false);
    });
  });

  describe('GET /api/commissariats/:id', () => {
    it('retourne le detail avec enfants', async () => {
      const token = await makeAdmin('dg@pnc.cg', 'Test@1234!', 'DIRECTION_GENERALE');

      const created = await app.inject({
        method: 'POST',
        url: '/api/commissariats',
        headers: authHeader(token),
        payload: { nom: 'Parent Detail', code: 'CC-PARENT-DET', departement: 'SANGHA' },
      });
      const id = created.json().data.id as string;

      const res = await app.inject({
        method: 'GET',
        url: `/api/commissariats/${id}`,
        headers: authHeader(token),
      });

      expect(res.statusCode).toBe(200);
      const body = res.json().data;
      expect(body.id).toBe(id);
      expect(body.enfants).toBeInstanceOf(Array);
    });

    it('id inconnu -> 404', async () => {
      const token = await makeAdmin();

      const res = await app.inject({
        method: 'GET',
        url: '/api/commissariats/00000000-0000-0000-0000-000000000000',
        headers: authHeader(token),
      });

      expect(res.statusCode).toBe(404);
    });
  });
});
