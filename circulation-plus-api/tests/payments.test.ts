import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { prisma } from '../src/config/database';
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

async function setupPaidFine(montantBase = 15000) {
  await createUser({
    email: 'pol@pnc.cg',
    pin: '1234',
    role: 'POLICE',
    telephone: '+242069999999',
  });
  const inf = await createInfractionType({ montantBase });
  const { token } = await login(app, 'pol@pnc.cg', '1234', 'police');

  const created = await app.inject({
    method: 'POST',
    url: '/api/fines',
    headers: authHeader(token),
    payload: {
      infractionTypeId: inf.id,
      driverPhone: '+242060000000',
      vehiclePlate: 'CG-PAY-01',
      latitude: -4.26,
      longitude: 15.24,
      deviceId: 'pay-dev',
      verbaliseLe: new Date().toISOString(),
    },
  });
  const fineId = created.json().data.id;

  const init = await app.inject({
    method: 'POST',
    url: '/api/payments/initiate',
    headers: authHeader(token),
    payload: { fineId, operateur: 'MTN', telephone: '+242060000000' },
  });
  return { token, fineId, init };
}

describe('Payments', () => {
  it('initiation → paymentUrl + reference', async () => {
    const { init } = await setupPaidFine();
    expect(init.statusCode).toBe(200);
    const body = init.json();
    expect(body.success).toBe(true);
    expect(body.data.paymentUrl).toContain('/__stub_pay/');
    expect(body.data.reference).toMatch(/^PAY-PV-/);
  });

  it('webhook sans signature → 401 INVALID_SIGNATURE, paiement reste PENDING', async () => {
    const { fineId } = await setupPaidFine();
    const payment = await prisma.payment.findUnique({ where: { fineId } });

    const res = await app.inject({
      method: 'POST',
      url: '/api/payments/confirm',
      headers: { 'content-type': 'application/json' },
      payload: JSON.stringify({
        transactionId: payment!.transactionId,
        status: 'CONFIRMED',
      }),
    });
    expect(res.statusCode).toBe(401);
    expect(res.json().code).toBe('INVALID_SIGNATURE');

    const after = await prisma.payment.findUnique({ where: { fineId } });
    expect(after!.status).toBe('PENDING');
  });

  it('webhook valide → transaction atomique + répartition exacte', async () => {
    const { fineId } = await setupPaidFine(15000);
    const payment = await prisma.payment.findUnique({ where: { fineId } });

    const res = await app.inject({
      method: 'POST',
      url: '/api/payments/confirm',
      headers: { 'content-type': 'application/json', 'x-stub-signature': 'stub' },
      payload: JSON.stringify({
        transactionId: payment!.transactionId,
        status: 'CONFIRMED',
      }),
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().data.confirmed).toBe(true);

    const fine = await prisma.fine.findUnique({ where: { id: fineId } });
    expect(fine!.status).toBe('PAID');

    const confirmed = await prisma.payment.findUnique({
      where: { fineId },
      include: { repartition: true },
    });
    expect(confirmed!.status).toBe('CONFIRMED');
    expect(confirmed!.confirmedAt).not.toBeNull();

    const r = confirmed!.repartition!;
    const sum = r.partDeveloppeur + r.partAgent + r.partPolice + r.partTresor;
    // montantTotal = montantBase (15000) + PART_DEVELOPPEUR (1000) = 16000
    expect(sum).toBe(16000);
    expect(r.partDeveloppeur).toBe(1000);
  });

  it('répartition exacte pour un montant arbitraire', async () => {
    const { fineId } = await setupPaidFine(23457);
    const payment = await prisma.payment.findUnique({ where: { fineId } });

    await app.inject({
      method: 'POST',
      url: '/api/payments/confirm',
      headers: { 'content-type': 'application/json', 'x-stub-signature': 'stub' },
      payload: JSON.stringify({
        transactionId: payment!.transactionId,
        status: 'CONFIRMED',
      }),
    });

    const r = await prisma.repartition.findUnique({
      where: { paymentId: payment!.id },
    });
    const sum =
      r!.partDeveloppeur + r!.partAgent + r!.partPolice + r!.partTresor;
    // montantTotal = montantBase (23457) + PART_DEVELOPPEUR (1000) = 24457
    expect(sum).toBe(24457);
  });

  it('webhook dupliqué → 200 idempotent, pas de double répartition', async () => {
    const { fineId } = await setupPaidFine(15000);
    const payment = await prisma.payment.findUnique({ where: { fineId } });
    const payload = JSON.stringify({
      transactionId: payment!.transactionId,
      status: 'CONFIRMED',
    });
    const headers = {
      'content-type': 'application/json',
      'x-stub-signature': 'stub',
    };

    const first = await app.inject({
      method: 'POST',
      url: '/api/payments/confirm',
      headers,
      payload,
    });
    expect(first.json().data.confirmed).toBe(true);

    const second = await app.inject({
      method: 'POST',
      url: '/api/payments/confirm',
      headers,
      payload,
    });
    expect(second.statusCode).toBe(200);
    expect(second.json().data.idempotent).toBe(true);

    const count = await prisma.repartition.count({
      where: { paymentId: payment!.id },
    });
    expect(count).toBe(1);
  });
});
