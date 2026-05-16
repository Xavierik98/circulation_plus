// Paramètres de limitation de débit.
//  - Global : 100 requêtes / minute / IP (enregistré dans app.ts)
//  - Login  : 10 requêtes / minute / IP (override au niveau de la route)

export const GLOBAL_RATE_LIMIT = {
  max: 100,
  timeWindow: '1 minute',
};

export const LOGIN_RATE_LIMIT = {
  max: 10,
  timeWindow: '1 minute',
};
