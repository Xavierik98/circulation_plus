import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import type { FastifyInstance } from 'fastify';
import {
  makeApp,
  createUser,
  createInfractionType,
  login,
  authHeader,
} from './helpers';

let app: FastifyInstance;

beforeAll(async () => {
  app = await makeApp();
});

afterAll(async () => {
  await app.close();
});

function fineBody(infractionTypeId: string, plate = 'CG-1234-AB') {
  return {
    infractionTypeId,
    driverPhone: '+242060000000',
    driverName: 'Joseph Bantsimba',
    vehiclePlate: plate,
    numeroPermis: 'CG-PERM-TEST',
    latitude: -4.2634,
    longitude: 15.2429,
    signatureAgent: 'data:image/png;base64,iVBORw0KGgo=',
    deviceId: 'terminal-001',
    verbaliseLe: new Date().toISOString(),
  };
}

describe('Fines', () => {
  it('création par POLICE → 201 + référence PV-YYYY-NNNNNN', async () => {
    await createUser({ email: 'pol@pnc.cg', pin: '1234', role: 'POLICE' });
    const inf = await createInfractionType({ montantBase: 15000 });
    const { token } = await login(app, 'pol@pnc.cg', '1234', 'police');

    const res = await app.inject({
      method: 'POST',
      url: '/api/fines',
      headers: authHeader(token),
      payload: fineBody(inf.id),
    });

    expect(res.statusCode).toBe(201);
    const body = res.json();
    expect(body.success).toBe(true);
    expect(body.data.reference).toMatch(/^PV-\d{4}-\d{6}$/);
    // montantTotal = montantBase (15000) + PART_DEVELOPPEUR (1000)
    expect(body.data.montantTotal).toBe(16000);
    const echeance = new Date(body.data.dateEcheance).getTime();
    const verb = new Date(body.data.verbaliseLe).getTime();
    expect(Math.round((echeance - verb) / (24 * 3600 * 1000))).toBe(30);
  });

  it('création par CITOYEN → 403 FORBIDDEN', async () => {
    await createUser({ email: 'cit@pnc.cg', pin: '1234', role: 'CITOYEN' });
    const inf = await createInfractionType();
    const { token } = await login(app, 'cit@pnc.cg', '1234', 'citizen');

    const res = await app.inject({
      method: 'POST',
      url: '/api/fines',
      headers: authHeader(token),
      payload: fineBody(inf.id),
    });
    expect(res.statusCode).toBe(403);
    expect(res.json().code).toBe('FORBIDDEN');
  });

  it('doublon même agent + plaque < 30 min → 409 DUPLICATE_FINE', async () => {
    await createUser({ email: 'pol@pnc.cg', pin: '1234', role: 'POLICE' });
    const inf = await createInfractionType();
    const { token } = await login(app, 'pol@pnc.cg', '1234', 'police');

    const first = await app.inject({
      method: 'POST',
      url: '/api/fines',
      headers: authHeader(token),
      payload: fineBody(inf.id, 'CG-9999-ZZ'),
    });
    expect(first.statusCode).toBe(201);

    const dup = await app.inject({
      method: 'POST',
      url: '/api/fines',
      headers: authHeader(token),
      payload: fineBody(inf.id, 'CG-9999-ZZ'),
    });
    expect(dup.statusCode).toBe(409);
    expect(dup.json().code).toBe('DUPLICATE_FINE');
  });

  it('sync offline par lots → created / failed / errors', async () => {
    await createUser({ email: 'pol@pnc.cg', pin: '1234', role: 'POLICE' });
    const inf = await createInfractionType();
    const { token } = await login(app, 'pol@pnc.cg', '1234', 'police');

    const valid1 = { ...fineBody(inf.id, 'CG-AAA-11'), deviceId: 'dev-1' };
    const valid2 = { ...fineBody(inf.id, 'CG-BBB-22'), deviceId: 'dev-2' };
    const invalid = {
      ...fineBody('00000000-0000-0000-0000-000000000000', 'CG-CCC-33'),
      deviceId: 'dev-3',
    };

    const res = await app.inject({
      method: 'POST',
      url: '/api/fines/sync',
      headers: authHeader(token),
      payload: { fines: [valid1, valid2, invalid] },
    });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.data.created).toBe(2);
    expect(body.data.failed).toBe(1);
    expect(body.data.errors).toHaveLength(1);
    expect(body.data.errors[0].deviceId).toBe('dev-3');
  });

  it('un agent POLICE ne voit pas la fine d’un autre agent → 404', async () => {
    const a = await createUser({ email: 'a@pnc.cg', pin: '1234', role: 'POLICE' });
    await createUser({ email: 'b@pnc.cg', pin: '1234', role: 'POLICE' });
    const inf = await createInfractionType();

    const aLogin = await login(app, 'a@pnc.cg', '1234', 'police');
    const created = await app.inject({
      method: 'POST',
      url: '/api/fines',
      headers: authHeader(aLogin.token),
      payload: fineBody(inf.id, 'CG-OWN-01'),
    });
    const fineId = created.json().data.id;
    expect(created.json().data.officer.id).toBe(a.id);

    const bLogin = await login(app, 'b@pnc.cg', '1234', 'police');
    const res = await app.inject({
      method: 'GET',
      url: `/api/fines/${fineId}`,
      headers: authHeader(bLogin.token),
    });
    expect(res.statusCode).toBe(404);
    expect(res.json().code).toBe('FINE_NOT_FOUND');
  });
});
