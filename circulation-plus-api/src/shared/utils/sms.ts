// Templates SMS officiels (français) — texte exact imposé par le cahier des charges.

function formatDate(d: Date): string {
  return d.toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
}

export const smsTemplates = {
  verbalisation(params: {
    ref: string;
    date: Date;
    montant: number;
    echeance: Date;
  }): string {
    return (
      `Contravention #${params.ref} émise le ${formatDate(params.date)}. ` +
      `Montant : ${params.montant} XAF.\n` +
      ` Payez avant le ${formatDate(params.echeance)} via Mobile Money.\n` +
      ` Réf. paiement : ${params.ref}. Police Nationale Congo.`
    );
  },

  paiementConfirmeContrevenant(params: { ref: string; montant: number }): string {
    return (
      `Paiement reçu pour PV #${params.ref}. Montant : ${params.montant} XAF.\n` +
      ` Vos pièces vous sont restituées. Merci. PNC Congo.`
    );
  },

  paiementConfirmeAgent(params: { ref: string; montant: number }): string {
    return (
      `PV #${params.ref} réglé (${params.montant} XAF). \n` +
      ` Restituez les pièces au conducteur. PNC.`
    );
  },

  convocation1(params: { permis: string; lieu: string; date: Date; ref: string }): string {
    return (
      `Votre permis n°${params.permis} présente une irrégularité.\n` +
      ` Présentez-vous au ${params.lieu} avant le ${formatDate(params.date)}.\n` +
      ` Réf: ${params.ref}. Police Nationale Congo.`
    );
  },

  convocation2(params: { ref: string; lieu: string }): string {
    return (
      `RAPPEL URGENT - Convocation ${params.ref} non honorée.\n` +
      ` Présentez-vous IMMÉDIATEMENT au ${params.lieu}.\n` +
      ` Sans réponse, votre dossier sera transmis au Procureur. PNC.`
    );
  },

  rappelEcheance(params: { ref: string; montant: number; echeance: Date }): string {
    return (
      `⚠️ RAPPEL : Votre amende #${params.ref} (${params.montant} XAF) expire le ${formatDate(params.echeance)}.\n` +
      ` Payez via Mobile Money avant cette date pour éviter des majorations. PNC Congo.`
    );
  },
};
