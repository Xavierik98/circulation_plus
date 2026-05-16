import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { makeApp, createUser, login } from './helpers';

let app: FastifyInstance;

beforeAll(async () => {
  app = await makeApp();
});

afterAll(async () => {
  await app.close();
});

describe('Auth', () => {
  it('connexion valide → token + refreshToken + user', async () => {
    await createUser({
      email: 'agent@pnc.cg',
      pin: '1234',
      role: 'POLICE',
      name: 'Jean Mbemba',
      badgeNumber: 'PNC-2024-001',
    });

    const res = await login(app, 'agent@pnc.cg', '1234', 'police');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeTruthy();
    expect(res.body.data.refreshToken).toBeTruthy();
    expect(res.body.data.user.role).toBe('POLICE');
    expect(res.body.data.user.badgeNumber).toBe('PNC-2024-001');
  });

  it('mauvais PIN → 401 INVALID_CREDENTIALS', async () => {
    await createUser({ email: 'agent@pnc.cg', pin: '1234', role: 'POLICE' });
    const res = await login(app, 'agent@pnc.cg', '9999', 'police');
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.code).toBe('INVALID_CREDENTIALS');
  });

  it('5 tentatives échouées → 6ᵉ bloquée 429 ACCOUNT_LOCKED', async () => {
    await createUser({ email: 'agent@pnc.cg', pin: '1234', role: 'POLICE' });

    for (let i = 0; i < 4; i += 1) {
      const r = await login(app, 'agent@pnc.cg', '0001', 'police');
      expect(r.status).toBe(401);
    }
    // 5ᵉ échec : déclenche le verrou.
    const fifth = await login(app, 'agent@pnc.cg', '0001', 'police');
    expect(fifth.status).toBe(429);
    expect(fifth.body.code).toBe('ACCOUNT_LOCKED');

    // Même un PIN correct est refusé pendant le blocage.
    const locked = await login(app, 'agent@pnc.cg', '1234', 'police');
    expect(locked.status).toBe(429);
    expect(locked.body.code).toBe('ACCOUNT_LOCKED');
  });

  it('refresh token valide → nouveau access token', async () => {
    await createUser({ email: 'agent@pnc.cg', pin: '1234', role: 'POLICE' });
    const { refreshToken } = await login(app, 'agent@pnc.cg', '1234', 'police');

    const res = await app.inject({
      method: 'POST',
      url: '/api/auth/refresh',
      payload: { refreshToken },
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.token).toBeTruthy();
    expect(body.data.refreshToken).toBeTruthy();
  });

  it('refresh token invalide → 401 INVALID_REFRESH', async () => {
    const res = await app.inject({
      method: 'POST',
      url: '/api/auth/refresh',
      payload: { refreshToken: 'totally.invalid.token' },
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().code).toBe('INVALID_REFRESH');
  });

  it('route protégée sans token → 401 NO_TOKEN', async () => {
    const res = await app.inject({ method: 'GET', url: '/api/auth/me' });
    expect(res.statusCode).toBe(401);
    expect(res.json().code).toBe('NO_TOKEN');
  });

  it('logout invalide le refresh token', async () => {
    await createUser({ email: 'agent@pnc.cg', pin: '1234', role: 'POLICE' });
    const { token, refreshToken } = await login(app, 'agent@pnc.cg', '1234', 'police');

    const out = await app.inject({
      method: 'POST',
      url: '/api/auth/logout',
      headers: { authorization: `Bearer ${token}` },
      payload: { refreshToken },
    });
    expect(out.statusCode).toBe(200);

    const reuse = await app.inject({
      method: 'POST',
      url: '/api/auth/refresh',
      payload: { refreshToken },
    });
    expect(reuse.statusCode).toBe(401);
  });
});
