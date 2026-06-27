/**
 * Normalisation des numéros de téléphone congolais (+242).
 *
 * Avant ce correctif, le rattachement amende ↔ compte citoyen comparait les
 * numéros de téléphone par égalité stricte de chaîne ("0612345678" ne
 * matchait pas "+242 06 12 34 56 78"), ce qui rendait l'attribution
 * automatique très peu fiable. Toutes les écritures (Driver.telephone,
 * User.telephone) doivent désormais passer par [normalizePhone] pour
 * garantir un format unique : "+242" + 9 chiffres.
 */
export function normalizePhone(raw: string): string {
  const trimmed = raw.trim();
  const digits = trimmed.replace(/[^\d]/g, '');
  // Retire un éventuel "00242" ou "242" en tête pour ne garder que le numéro
  // local à 9 chiffres (commençant par 0), puis réapplique le préfixe +242.
  let local = digits;
  if (local.startsWith('00242')) local = local.slice(5);
  else if (local.startsWith('242') && local.length > 9) local = local.slice(3);
  if (!local.startsWith('0')) local = `0${local}`;
  return `+242${local.slice(-9)}`;
}

/**
 * Variantes plausibles d'un même numéro (avec/sans indicatif), pour matcher
 * les données existantes qui n'ont pas encore été normalisées.
 */
export function phoneVariants(raw: string): string[] {
  const normalized = normalizePhone(raw);
  const local = normalized.replace('+242', ''); // "0XXXXXXXX"
  return [normalized, local, local.slice(1)]; // +242..., 0XXXXXXXX, XXXXXXXX
}
