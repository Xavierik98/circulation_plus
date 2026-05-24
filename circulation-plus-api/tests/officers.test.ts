import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { makeApp, createUser, login, authHeader } from './helpers';
import { prisma } from '../src/config/database';

let app: FastifyInstance;

beforeAll(async () => {
  app = await makeApp();
});

afterAll(async () => {
  await app.close();
});

// ── Helpers ────────────────────────────────────────────────────────────────────

async function makeAdmin(email = 'admin@pnc.cg', pin = 'Test@1234!') {
  await createUser({ email, pin, role: 'ADMIN', name: 'Admin Test' });
  const { token } = await login(app, email, pin, 'admin');
  return token;
}

async function makeOfficer(email = 'agent@pnc.cg', pin = 'Test@1234!') {
  await createUser({
    email,
    pin,
    role: 'POLICE',
    name: 'Agent Test',
    badgeNumber: 'PNC-TEST-001',
    telephone: '+242066000001',
  });
}

// ── Tests ──────────────────────────────────────────────────────────────────────

describe('Officers API', () => {
  describe('GET /api/officers', () => {
    it('ADMIN peut lister les agents', async () => {
      const token = await makeAdmin();
      await makeOfficer();

      const res = await app.inject({
        method: 'GET',
        url: '/api/officers',
        headers: authHeader(token),
      });

      expect(res.statusCode).toBe(200);
      const body = res.json();
      expect(body.success).toBe(true);
      expect(body.data.data).toBeInstanceOf(Array);
      expect(body.data.total).toBeGreaterThanOrEqual(1);
    });

    it('agent POLICE ne peut pas lister les agents (403)', async () => {
      await makeOfficer();
      const { token } = await login(app, 'agent@pnc.cg', 'Test@1234!', 'police');

      const res = await app.inject({
        method: 'GET',
        url: '/api/officers',
        headers: authHeader(token),
      });

      expect(res.statusCode).toBe(403);
    });

    it('sans token → 401', async () => {
      const res = await app.inject({ method: 'GET', url: '/api/officers' });
      expect(res.statusCode).toBe(401);
    });
  });

  describe('POST /api/officers', () => {
    it('ADMIN creer un agent avec email @pnc.cg', async () => {
      const token = await makeAdmin();

      const res = await app.inject({
        method: 'POST',
        url: '/api/officers',
        headers: authHeader(token),
        payload: {
          name: 'Nouveau Agent',
          email: 'nouveau.agent@pnc.cg',
          telephone: '+242066000099',
          badgeNumber: 'PNC-NEW-001',
          rank: 'INSPECTEUR',
          department: 'BRAZZAVILLE',
          password: 'Test@1234!',
        },
      });

      expect(res.statusCode).toBe(200);
      const body = res.json();
      expect(body.data.email).toBe('nouveau.agent@pnc.cg');
      expect(body.data.mustChangePassword).toBe(true);
    });

    it('email hors domaine @pnc.cg → 400 INVALID_OFFICER_DOMAIN', async () => {
      const token = await makeAdmin();

      const res = await app.inject({
        method: 'POST',
        url: '/api/officers',
        headers: authHeader(token),
        payload: {
          name: 'Agent Invalide',
          email: 'agent@gmail.com',
          telephone: '+242066000088',
          badgeNumber: 'PNC-BAD-001',
          rank: 'INSPECTEUR',
          department: 'BRAZZAVILLE',
          password: 'Test@1234!',
        },
      });

      expect(res.statusCode).toBe(400);
    });

    it('doublon email → 409 OFFICER_EXISTS', async () => {
      const token = await makeAdmin();
      await makeOfficer();

      const res = await app.inject({
        method: 'POST',
        url: '/api/officers',
        headers: authHeader(token),
        payload: {
          name: 'Agent Doublon',
          email: 'agent@pnc.cg',
          telephone: '+242066000077',
          badgeNumber: 'PNC-DUP-001',
          rank: 'INSPECTEUR',
          department: 'BRAZZAVILLE',
          password: 'Test@1234!',
        },
      });

      expect(res.statusCode).toBe(409);
      expect(res.json().code).toBe('OFFICER_EXISTS');
    });
  });

  describe('PATCH /api/officers/:id', () => {
    it('ADMIN peut desactiver un agent', async () => {
      const token = await makeAdmin();
      await makeOfficer();

      const officer = await prisma.user.findFirst({ where: { role: 'POLICE' } });
      expect(officer).not.toBeNull();

      const res = await app.inject({
        method: 'PATCH',
        url: `/api/officers/${officer!.id}`,
        headers: authHeader(token),
        payload: { actif: false },
      });

      expect(res.statusCode).toBe(200);
      expect(res.json().data.actif).toBe(false);
    });
  });

  describe('GET /api/officers/:id/activity', () => {
    it('retourne historique connexions (vide si aucune)', async () => {
      const token = await makeAdmin();
      await makeOfficer();

      const officer = await prisma.user.findFirst({ where: { role: 'POLICE' } });

      const res = await app.inject({
        method: 'GET',
        url: `/api/officers/${officer!.id}/activity`,
        headers: authHeader(token),
      });

      expect(res.statusCode).toBe(200);
      const body = res.json();
      expect(body.data.items).toBeInstanceOf(Array);
      expect(body.data.total).toBeGreaterThanOrEqual(0);
    });

    it('agent introuvable → 404', async () => {
      const token = await makeAdmin();

      const res = await app.inject({
        method: 'GET',
        url: '/api/officers/00000000-0000-0000-0000-000000000000/activity',
        headers: authHeader(token),
      });

      expect(res.statusCode).toBe(404);
    });
  });
});
