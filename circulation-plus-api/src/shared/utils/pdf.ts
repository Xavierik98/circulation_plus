import PDFDocument from 'pdfkit';
import QRCode from 'qrcode';

export interface FinePdfData {
  reference: string;
  verbaliseLe: Date;
  createdAt: Date;
  lieu: string | null;
  latitude: number | null;
  longitude: number | null;
  agentNom: string;
  agentBadge: string | null;
  conducteurNom: string | null;
  conducteurTelephone: string | null;
  conducteurPermis: string | null;
  vehiculePlaque: string | null;
  vehiculeMarque: string | null;
  vehiculeModele: string | null;
  infractionCode: string;
  infractionLibelle: string;
  montantTotal: number;
  signatureAgent: string | null;
  signatureContrevenant: string | null;
  refusSignature: boolean;
  verifyUrl: string;
}

function decodeSignature(b64: string | null): Buffer | null {
  if (!b64) return null;
  try {
    const cleaned = b64.replace(/^data:image\/\w+;base64,/, '');
    return Buffer.from(cleaned, 'base64');
  } catch {
    return null;
  }
}

// Génère le PDF officiel du procès-verbal de contravention.
export async function generateFinePdf(data: FinePdfData): Promise<Buffer> {
  const qrDataUrl = await QRCode.toDataURL(data.verifyUrl, { margin: 1, width: 120 });
  const qrBuffer = Buffer.from(qrDataUrl.split(',')[1] ?? '', 'base64');

  const doc = new PDFDocument({ size: 'A4', margin: 50 });
  const chunks: Buffer[] = [];
  doc.on('data', (chunk: Buffer) => chunks.push(chunk));

  const done = new Promise<Buffer>((resolve) => {
    doc.on('end', () => resolve(Buffer.concat(chunks)));
  });

  // En-tête
  doc
    .fontSize(10)
    .text('POLICE NATIONALE DU CONGO-BRAZZAVILLE', { align: 'center' })
    .moveDown(0.3);
  doc
    .fontSize(18)
    .text('PROCÈS-VERBAL DE CONTRAVENTION', { align: 'center' })
    .moveDown(0.5);
  doc.fontSize(12).text(`Référence : ${data.reference}`, { align: 'center' });
  doc.moveDown(1);

  const line = (label: string, value: string): void => {
    doc.fontSize(10).text(`${label} : ${value}`);
  };

  doc.fontSize(13).text('Verbalisation', { underline: true }).moveDown(0.3);
  line('Date/heure', data.verbaliseLe.toLocaleString('fr-FR'));
  line('Horodatage serveur', data.createdAt.toLocaleString('fr-FR'));
  line('Lieu', data.lieu ?? 'Non précisé');
  if (data.latitude !== null && data.longitude !== null) {
    line('Coordonnées', `${data.latitude}, ${data.longitude}`);
  }
  doc.moveDown(0.6);

  doc.fontSize(13).text('Agent verbalisateur', { underline: true }).moveDown(0.3);
  line('Nom', data.agentNom);
  line('Matricule', data.agentBadge ?? '—');
  line('Unité', 'Police Nationale du Congo-Brazzaville');
  doc.moveDown(0.6);

  doc.fontSize(13).text('Conducteur', { underline: true }).moveDown(0.3);
  line('Nom', data.conducteurNom ?? 'Non disponible');
  line('Téléphone', data.conducteurTelephone ?? '—');
  line('Numéro de permis', data.conducteurPermis ?? '—');
  doc.moveDown(0.6);

  doc.fontSize(13).text('Véhicule', { underline: true }).moveDown(0.3);
  line('Plaque', data.vehiculePlaque ?? '—');
  line(
    'Marque / Modèle',
    `${data.vehiculeMarque ?? '—'} / ${data.vehiculeModele ?? '—'}`,
  );
  doc.moveDown(0.6);

  doc.fontSize(13).text('Infraction', { underline: true }).moveDown(0.3);
  line('Code', data.infractionCode);
  line('Libellé', data.infractionLibelle);
  line('Montant', `${data.montantTotal} XAF`);
  doc.moveDown(1);

  // Signatures
  doc.fontSize(13).text('Signatures', { underline: true }).moveDown(0.3);
  const sigY = doc.y;
  const agentSig = decodeSignature(data.signatureAgent);
  doc.fontSize(10).text('Agent :', 50, sigY);
  if (agentSig) {
    try {
      doc.image(agentSig, 50, sigY + 12, { fit: [150, 60] });
    } catch {
      doc.text('(signature illisible)', 50, sigY + 12);
    }
  } else {
    doc.text('—', 50, sigY + 12);
  }

  doc.fontSize(10).text('Contrevenant :', 320, sigY);
  if (data.refusSignature) {
    doc.text('Refus de signer', 320, sigY + 12);
  } else {
    const contreSig = decodeSignature(data.signatureContrevenant);
    if (contreSig) {
      try {
        doc.image(contreSig, 320, sigY + 12, { fit: [150, 60] });
      } catch {
        doc.text('(signature illisible)', 320, sigY + 12);
      }
    } else {
      doc.text('—', 320, sigY + 12);
    }
  }

  // QR code de vérification
  doc.image(qrBuffer, 50, sigY + 100, { fit: [110, 110] });
  doc
    .fontSize(8)
    .text('Vérifiez l’authenticité de ce PV :', 170, sigY + 130)
    .text(data.verifyUrl, 170, sigY + 145);

  // Pied de page
  doc
    .fontSize(8)
    .text(
      'Document officiel — Police Nationale du Congo-Brazzaville',
      50,
      780,
      { align: 'center' },
    );

  doc.end();
  return done;
}
