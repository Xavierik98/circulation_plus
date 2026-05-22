import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/interpellation_state.dart';
import '../models/department_model.dart';

/// Génère et partage/imprime le Procès-Verbal de contravention au format PDF.
class PvPdfService {
  // ─── Couleurs PNC ──────────────────────────────────────────────────────────
  static const _navy    = PdfColor.fromInt(0xFF0F1D3A);
  static const _blue    = PdfColor.fromInt(0xFF1A56DB);
  static const _gold    = PdfColor.fromInt(0xFFD4A843);
  static const _green   = PdfColor.fromInt(0xFF009A44);
  static const _yellow  = PdfColor.fromInt(0xFFFCD116);
  static const _red     = PdfColor.fromInt(0xFFDC2626);
  static const _grey100 = PdfColor.fromInt(0xFFF1F5F9);
  static const _grey400 = PdfColor.fromInt(0xFF94A3B8);
  static const _grey700 = PdfColor.fromInt(0xFF334155);
  static const _white   = PdfColors.white;

  /// Génère le PDF et ouvre le dialogue d'impression/partage natif.
  static Future<void> printPv({
    required InterpellationState interp,
    required String reference,
    required String agentName,
    required String agentBadge,
  }) async {
    final doc = pw.Document(
      title: 'PV $reference',
      author: 'Circulation+ / PNC',
      subject: 'Procès-Verbal de Contravention',
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (context) => _buildPage(
          context,
          interp: interp,
          reference: reference,
          agentName: agentName,
          agentBadge: agentBadge,
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'PV_$reference.pdf',
    );
  }

  // ─── Page principale ───────────────────────────────────────────────────────
  static pw.Widget _buildPage(
    pw.Context context, {
    required InterpellationState interp,
    required String reference,
    required String agentName,
    required String agentBadge,
  }) {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // ── En-tête ────────────────────────────────────────────────
        _buildHeader(reference, dateStr, timeStr),

        // ── Corps ─────────────────────────────────────────────────
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Alerte refus ou mention normale
                if (interp.signatureRefused) _buildRefusalBanner(),

                pw.SizedBox(height: 10),

                // Conducteur + véhicule (2 colonnes)
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                        child: _buildSection(
                      title: 'CONDUCTEUR',
                      icon: '👤',
                      rows: [
                        _row('Nom', interp.driverName.isNotEmpty ? interp.driverName : '—'),
                        _row('Permis', interp.driverLicense.isNotEmpty ? interp.driverLicense : 'Non présenté'),
                        _row('Téléphone', interp.driverPhone.isNotEmpty ? interp.driverPhone : '—'),
                      ],
                    )),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                        child: _buildSection(
                      title: 'VÉHICULE',
                      icon: '🚗',
                      rows: [
                        _row('Plaque', interp.vehiclePlate.isNotEmpty ? interp.vehiclePlate : '—'),
                        _row('Marque', interp.vehicleBrand.isNotEmpty ? interp.vehicleBrand : '—'),
                        _row('Modèle', interp.vehicleModel.isNotEmpty ? interp.vehicleModel : '—'),
                        _row('Couleur', interp.vehicleColor.isNotEmpty ? interp.vehicleColor : '—'),
                      ],
                    )),
                  ],
                ),

                pw.SizedBox(height: 12),

                // Lieu
                _buildSection(
                  title: 'LIEU DE L\'INFRACTION',
                  icon: '📍',
                  rows: [
                    _row(
                      'Département',
                      interp.departement?.label ?? '—',
                    ),
                    _row(
                      'Lieu précis',
                      interp.lieuPrecis.isNotEmpty ? interp.lieuPrecis : '—',
                    ),
                    if (interp.gpsLat != null && interp.gpsLng != null)
                      _row(
                        'GPS',
                        '${interp.gpsLat!.toStringAsFixed(5)}, ${interp.gpsLng!.toStringAsFixed(5)}',
                      ),
                  ],
                ),

                pw.SizedBox(height: 12),

                // Infractions
                _buildInfractionsTable(interp),

                pw.SizedBox(height: 12),

                // Montant
                _buildAmountRow(interp),

                pw.SizedBox(height: 12),

                // Documents saisis (si refus)
                if (interp.signatureRefused && interp.documentsSeizes.isNotEmpty)
                  _buildSeizedDocuments(interp),

                pw.Spacer(),

                // Signatures
                _buildSignatureRow(
                  agentName: agentName,
                  agentBadge: agentBadge,
                  signatureRefused: interp.signatureRefused,
                  driverName: interp.driverName,
                ),
              ],
            ),
          ),
        ),

        // ── Pied de page ───────────────────────────────────────────
        _buildFooter(reference, dateStr),
      ],
    );
  }

  // ─── En-tête ───────────────────────────────────────────────────────────────
  static pw.Widget _buildHeader(
      String reference, String dateStr, String timeStr) {
    return pw.Container(
      color: _navy,
      padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: pw.Row(
        children: [
          // Logo PNC cercle
          pw.Container(
            width: 64,
            height: 64,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: _white,
              border: pw.Border.all(color: _gold, width: 2),
            ),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    '⚖',
                    style: const pw.TextStyle(fontSize: 22),
                  ),
                  pw.Text(
                    'PNC',
                    style: pw.TextStyle(
                      color: _navy,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 16),

          // Titre + institution
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PROCÈS-VERBAL DE CONTRAVENTION',
                  style: pw.TextStyle(
                    color: _white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Police Nationale du Congo — Circulation+',
                  style: const pw.TextStyle(
                    color: _gold,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'République du Congo · Ministère de l\'Intérieur',
                  style: const pw.TextStyle(
                    color: _grey400,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),

          // Référence + date
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: _gold,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  reference,
                  style: pw.TextStyle(
                    color: _navy,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                '$dateStr à $timeStr',
                style: const pw.TextStyle(color: _grey400, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Bannière refus ────────────────────────────────────────────────────────
  static pw.Widget _buildRefusalBanner() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFEF2F2),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFFCA5A5),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Text('⚠ ', style: const pw.TextStyle(fontSize: 12, color: _red)),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'REFUS DE SIGNATURE DU CONDUCTEUR',
                  style: pw.TextStyle(
                    color: _red,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.Text(
                  'Procédure de saisie de documents engagée. '
                  'Une convocation sera émise dans les 7 jours. '
                  'Les documents saisis seront restitués après paiement au Trésor public.',
                  style: const pw.TextStyle(
                    color: _grey700,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section générique ─────────────────────────────────────────────────────
  static pw.Widget _buildSection({
    required String title,
    required String icon,
    required List<pw.Widget> rows,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Titre section
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE2E8F0),
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Text('$icon ', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: _grey700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              children: rows,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                color: _grey400,
                fontSize: 8,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                color: _grey700,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tableau des infractions ───────────────────────────────────────────────
  static pw.Widget _buildInfractionsTable(InterpellationState interp) {
    final infractions = interp.selectedInfractions;
    if (infractions.isEmpty) return pw.SizedBox.shrink();

    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // En-tête tableau
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE2E8F0),
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Text('📋 ', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  'INFRACTIONS CONSTATÉES',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: _grey700,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.Spacer(),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: _blue,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    '${infractions.length} infraction${infractions.length > 1 ? 's' : ''}',
                    style: pw.TextStyle(
                        color: _white,
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Lignes infractions
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: pw.Column(
              children: [
                // Header colonnes
                pw.Row(
                  children: [
                    pw.Expanded(
                        flex: 2,
                        child: pw.Text('Code',
                            style: pw.TextStyle(
                                fontSize: 7,
                                color: _grey400,
                                fontWeight: pw.FontWeight.bold))),
                    pw.Expanded(
                        flex: 5,
                        child: pw.Text('Infraction',
                            style: pw.TextStyle(
                                fontSize: 7,
                                color: _grey400,
                                fontWeight: pw.FontWeight.bold))),
                    pw.SizedBox(
                      width: 60,
                      child: pw.Text('Montant',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                              fontSize: 7,
                              color: _grey400,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                pw.Divider(color: const PdfColor.fromInt(0xFFE2E8F0), height: 8),
                ...infractions.map((inf) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                              flex: 2,
                              child: pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: pw.BoxDecoration(
                                  color: const PdfColor.fromInt(0xFFE2E8F0),
                                  borderRadius: pw.BorderRadius.circular(3),
                                ),
                                child: pw.Text(inf.code,
                                    style: const pw.TextStyle(
                                        fontSize: 7, color: _grey700)),
                              )),
                          pw.SizedBox(width: 6),
                          pw.Expanded(
                              flex: 5,
                              child: pw.Text(inf.labelFr,
                                  style: const pw.TextStyle(
                                      fontSize: 8, color: _grey700))),
                          pw.SizedBox(
                            width: 60,
                            child: pw.Text(
                              '${_fmt(inf.fineAmount)} F',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _grey700),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Montant total ─────────────────────────────────────────────────────────
  static pw.Widget _buildAmountRow(InterpellationState interp) {
    const devFee = 1000;
    final base = interp.baseAmount;
    final total = interp.totalAmount;

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Amendes : ${_fmt(base)} FCFA',
                  style: const pw.TextStyle(color: _grey400, fontSize: 8),
                ),
                pw.Text(
                  'Frais plateforme : ${_fmt(devFee)} FCFA',
                  style: const pw.TextStyle(color: _grey400, fontSize: 8),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Délai de paiement : 30 jours · +50% après délai',
                  style: const pw.TextStyle(
                    color: _yellow,
                    fontSize: 7,
                  ),
                ),
                pw.Text(
                  'Paiement : Trésor public ou Mobile Money',
                  style: const pw.TextStyle(color: _grey400, fontSize: 7),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'TOTAL À PAYER',
                style: const pw.TextStyle(
                  color: _grey400,
                  fontSize: 7,
                  letterSpacing: 0.8,
                ),
              ),
              pw.Text(
                '${_fmt(total)} FCFA',
                style: pw.TextStyle(
                  color: _white,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Documents saisis ──────────────────────────────────────────────────────
  static pw.Widget _buildSeizedDocuments(InterpellationState interp) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFFBEB),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFFCD34D)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '📁 DOCUMENTS SAISIS (${interp.documentsSeizes.length})',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF92400E),
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Wrap(
            spacing: 8,
            runSpacing: 4,
            children: interp.documentsSeizes
                .map((d) => pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFFCD34D).shade(0.3),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        d.label,
                        style: pw.TextStyle(
                          fontSize: 7,
                          color: const PdfColor.fromInt(0xFF92400E),
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ─── Zone signatures ───────────────────────────────────────────────────────
  static pw.Widget _buildSignatureRow({
    required String agentName,
    required String agentBadge,
    required bool signatureRefused,
    required String driverName,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Signature agent
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SIGNATURE AGENT',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: _grey700,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  height: 30,
                  child: pw.Center(
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text('✓ ',
                            style: const pw.TextStyle(
                                fontSize: 12, color: _green)),
                        pw.Text(
                          'Signé électroniquement',
                          style: const pw.TextStyle(
                              fontSize: 8, color: _green),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  agentName.isNotEmpty ? agentName : 'Agent PNC',
                  style: pw.TextStyle(
                      fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  agentBadge.isNotEmpty ? 'Badge : $agentBadge' : '',
                  style: const pw.TextStyle(fontSize: 7, color: _grey400),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        // Signature conducteur
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: signatureRefused
                    ? const PdfColor.fromInt(0xFFFCA5A5)
                    : const PdfColor.fromInt(0xFFE2E8F0),
              ),
              color: signatureRefused
                  ? const PdfColor.fromInt(0xFFFEF2F2)
                  : _white,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SIGNATURE CONDUCTEUR',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: signatureRefused ? _red : _grey700,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  height: 30,
                  child: pw.Center(
                    child: signatureRefused
                        ? pw.Text(
                            '⚠ REFUS DE SIGNATURE',
                            style: pw.TextStyle(
                                fontSize: 8,
                                color: _red,
                                fontWeight: pw.FontWeight.bold),
                          )
                        : pw.Container(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(
                                    color: _grey400),
                              ),
                            ),
                          ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  driverName.isNotEmpty ? driverName : 'Conducteur',
                  style: pw.TextStyle(
                      fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
                if (signatureRefused)
                  pw.Text(
                    'Constaté par procès-verbal — Art. CR-Congo',
                    style: const pw.TextStyle(fontSize: 7, color: _red),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Pied de page ──────────────────────────────────────────────────────────
  static pw.Widget _buildFooter(String reference, String dateStr) {
    return pw.Column(
      children: [
        // Bande drapeau Congo : vert / jaune / rouge
        pw.Row(
          children: [
            pw.Expanded(child: pw.Container(height: 4, color: _green)),
            pw.Expanded(child: pw.Container(height: 4, color: _yellow)),
            pw.Expanded(child: pw.Container(height: 4, color: _red)),
          ],
        ),
        pw.Container(
          color: _navy,
          padding:
              const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'République du Congo · Ministère de l\'Intérieur · Police Nationale du Congo',
                  style: const pw.TextStyle(color: _grey400, fontSize: 7),
                ),
              ),
              pw.Text(
                'Ref: $reference · Émis le $dateStr · Circulation+ v1.0',
                style: const pw.TextStyle(color: _grey400, fontSize: 7),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Format FCFA : 25000 → "25 000"
  static String _fmt(int amount) {
    if (amount < 1000) return amount.toString();
    final t = amount ~/ 1000;
    final r = amount % 1000;
    return r == 0 ? '$t 000' : '$t ${r.toString().padLeft(3, '0')}';
  }
}
