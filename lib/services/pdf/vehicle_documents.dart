import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/config/app_info.dart';
import '../../core/utils/formatters.dart';
import '../../models/vehicle_listing.dart';
import '../../models/vehicle_order.dart';
import '../../models/vehicle_request.dart';

/// Generation des documents PDF vehicule (facture puis contrat).
/// Textes volontairement sans accents (comme le reste de l'app) : la police
/// PDF par defaut suffit, sans embarquer d'asset de police.
class VehicleDocuments {
  const VehicleDocuments._();

  static final _navy = PdfColor.fromInt(0xFF1E3A5F);
  static final _gold = PdfColor.fromInt(0xFFC9A24B);
  static final _grey = PdfColor.fromInt(0xFF6B7280);

  static String _shortRef(String? id) =>
      (id ?? '').replaceAll('-', '').substring(0, 8).toUpperCase();

  static String _vehicleTitle(VehicleListing? v, String ref) =>
      v?.title ?? 'Vehicule $ref';

  // -----------------------------------------------------------------
  // FACTURE
  // -----------------------------------------------------------------
  static Future<Uint8List> buildInvoice({
    required VehicleOrder order,
    VehicleListing? vehicle,
    VehicleRequest? request,
  }) async {
    final doc = pw.Document();
    final title = _vehicleTitle(vehicle, order.vehicleReference);
    final now = DateTime.now();

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header(docTitle: 'FACTURE', numero: 'FA-${_shortRef(order.id)}', date: now),
          pw.SizedBox(height: 18),
          _parties(request, order),
          pw.SizedBox(height: 16),
          _sectionTitle('Vehicule'),
          pw.Text('$title  (Ref ${order.vehicleReference})'),
          pw.SizedBox(height: 16),
          _sectionTitle('Montants'),
          _amountsTable(order),
          pw.SizedBox(height: 16),
          _notice(),
          pw.Spacer(),
          _footer(),
        ],
      ),
    ));
    return doc.save();
  }

  // -----------------------------------------------------------------
  // CONTRAT
  // -----------------------------------------------------------------
  static Future<Uint8List> buildContract({
    required VehicleOrder order,
    VehicleListing? vehicle,
    VehicleRequest? request,
  }) async {
    final doc = pw.Document();
    final title = _vehicleTitle(vehicle, order.vehicleReference);
    final now = DateTime.now();
    final client = (request?.customerName ?? '').isNotEmpty
        ? request!.customerName
        : (order.clientName ?? 'Le client');
    final total = Formatters.fcfa(order.totalPrice);
    final deposit = Formatters.fcfa(order.depositAmount);
    final balance = Formatters.fcfa(order.balanceAmount);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => [
        _header(
            docTitle: 'CONTRAT',
            numero: 'CT-${_shortRef(order.id)}',
            date: now),
        pw.SizedBox(height: 16),
        pw.Center(
          child: pw.Text('CONTRAT D\'IMPORTATION DE VEHICULE',
              style: pw.TextStyle(
                  fontSize: 15, fontWeight: pw.FontWeight.bold, color: _navy)),
        ),
        pw.SizedBox(height: 16),
        pw.Text('Entre les soussignes :',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Bullet(
            text:
                'Le Vendeur : ${AppInfo.publisher} (${AppInfo.appName}), '
                '${AppInfo.supportPhone}, ${AppInfo.supportEmail}.'),
        pw.Bullet(
            text: 'Le Client : $client'
                '${(request?.phone ?? '').isNotEmpty ? ', ${request!.phone}' : ''}'
                '${(request?.city ?? '').isNotEmpty ? ', ${request!.city}' : ''}.'),
        pw.SizedBox(height: 12),
        _article('Article 1 - Objet',
            'Le Vendeur s\'engage a importer depuis la Coree du Sud le vehicule '
            'suivant pour le compte du Client : $title (reference '
            '${order.vehicleReference}).'),
        _article('Article 2 - Prix et paiement',
            'Le prix total convenu est de $total. Le Client verse un acompte '
            'de 70% ($deposit) a la commande, puis le solde de 30% ($balance) '
            'avant la remise du vehicule. Paiement par virement ou en especes.'),
        _article('Article 3 - Delais',
            'Le vehicule est achemine par container maritime. Le delai estime '
            'est de 60 a 90 jours a compter de la confirmation de commande.'),
        _article('Article 4 - Dedouanement',
            'Le dedouanement au port d\'arrivee est integralement a la charge '
            'du Client.'),
        _article('Article 5 - Remise du vehicule',
            'Le vehicule est remis au Client apres reception de la totalite du '
            'paiement (acompte + solde) et accomplissement des formalites.'),
        pw.SizedBox(height: 24),
        pw.Text('Fait le ${Formatters.date(now)}.'),
        pw.SizedBox(height: 30),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _signature('Le Vendeur'),
            _signature('Le Client'),
          ],
        ),
        pw.SizedBox(height: 20),
        _footer(),
      ],
    ));
    return doc.save();
  }

  // -----------------------------------------------------------------
  // Blocs reutilisables
  // -----------------------------------------------------------------
  static pw.Widget _header(
      {required String docTitle, required String numero, required DateTime date}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('TerangaMobility',
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold, color: _navy)),
          pw.Text('PARTS & VEHICULES',
              style: pw.TextStyle(
                  fontSize: 9, letterSpacing: 2, color: _gold)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(docTitle,
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold, color: _navy)),
          pw.Text('N° $numero', style: pw.TextStyle(color: _grey)),
          pw.Text('Date : ${Formatters.date(date)}',
              style: pw.TextStyle(color: _grey)),
        ]),
      ],
    );
  }

  static pw.Widget _parties(VehicleRequest? r, VehicleOrder o) {
    final name = (r?.customerName ?? '').isNotEmpty
        ? r!.customerName
        : (o.clientName ?? '-');
    final phone = (r?.phone ?? '').isNotEmpty ? r!.phone : null;
    final String whatsapp = (r?.whatsapp ?? '').isNotEmpty
        ? r!.whatsapp!
        : (o.clientWhatsapp ?? '');
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _sectionTitle('Vendeur'),
              pw.Text(AppInfo.publisher),
              pw.Text(AppInfo.supportPhone),
              pw.Text(AppInfo.supportEmail),
              pw.Text(AppInfo.publisherSite.replaceFirst('https://', '')),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _sectionTitle('Client'),
              pw.Text(name),
              if (phone != null) pw.Text(phone),
              if (whatsapp.isNotEmpty) pw.Text('WhatsApp $whatsapp'),
              pw.Text([r?.city, r?.country]
                  .where((e) => e != null && e.isNotEmpty)
                  .join(', ')),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _amountsTable(VehicleOrder o) {
    pw.TableRow row(String label, String value, {bool bold = false, String? tag}) {
      return pw.TableRow(children: [
        pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
            child: pw.Text(label,
                style: bold
                    ? pw.TextStyle(fontWeight: pw.FontWeight.bold)
                    : null)),
        pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
            child: pw.Text(tag ?? '', style: pw.TextStyle(color: _grey))),
        pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
            child: pw.Text(value,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal))),
      ]);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE5E7EB)),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.4),
        2: const pw.FlexColumnWidth(1.6),
      },
      children: [
        row('Prix total', Formatters.fcfa(o.totalPrice), bold: true),
        row('Acompte (70%)', Formatters.fcfa(o.depositAmount),
            tag: o.depositPaid ? 'Paye' : 'A payer'),
        row('Solde (30%)', Formatters.fcfa(o.balanceAmount),
            tag: o.balancePaid ? 'Paye' : 'A payer'),
      ],
    );
  }

  static pw.Widget _notice() => pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFFDF6E3),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          'Delai d\'acheminement : 60 a 90 jours par container maritime. '
          'Le dedouanement est a la charge du client.',
          style: pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF7A5A00)),
        ),
      );

  static pw.Widget _sectionTitle(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(t.toUpperCase(),
            style: pw.TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: pw.FontWeight.bold,
                color: _navy)),
      );

  static pw.Widget _article(String title, String body) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(body, textAlign: pw.TextAlign.justify),
        ]),
      );

  static pw.Widget _signature(String who) => pw.Column(children: [
        pw.Container(width: 160, height: 1, color: _grey),
        pw.SizedBox(height: 4),
        pw.Text(who, style: pw.TextStyle(color: _grey)),
      ]);

  static pw.Widget _footer() => pw.Column(children: [
        pw.Divider(color: PdfColor.fromInt(0xFFE5E7EB)),
        pw.Text(
          '${AppInfo.publisher}  •  ${AppInfo.supportPhone}  •  ${AppInfo.supportEmail}',
          style: pw.TextStyle(fontSize: 9, color: _grey),
        ),
      ]);
}
