// Enveloppe de réponse standardisée — appliquée à TOUTES les réponses.
//   succès : { success: true, data: ... }
//   erreur : { success: false, error: "message", code: "ERROR_CODE" }

export interface SuccessEnvelope<T> {
  success: true;
  data: T;
}

export interface ErrorEnvelope {
  success: false;
  error: string;
  code: string;
}

export function ok<T>(data: T): SuccessEnvelope<T> {
  return { success: true, data };
}

export function fail(error: string, code: string): ErrorEnvelope {
  return { success: false, error, code };
}

export interface Paginated<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
}

// La forme paginée documentée devient le CONTENU de `data`
// => { success: true, data: { data: [...], total, page, limit } }
export function paginated<T>(
  items: T[],
  total: number,
  page: number,
  limit: number,
): Paginated<T> {
  return { data: items, total, page, limit };
}
