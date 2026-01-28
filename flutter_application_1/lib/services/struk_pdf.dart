import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<pw.Document> generateStrukPdf({
  required Map<String, dynamic> transaksi,
}) async {
  final pdf = pw.Document();

  final items =
      List<Map<String, dynamic>>.from(transaksi['items']);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'TOKO ANDA',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Center(child: pw.Text('Struk Pembelian')),
            pw.SizedBox(height: 12),
            pw.Divider(),

            pw.Text('Tanggal: ${transaksi['date']}'),
            pw.SizedBox(height: 8),
            pw.Divider(),

            ...items.map((item) {
              return pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      '${item['name']} (${item['qty']}x)',
                    ),
                  ),
                  pw.Text('Rp ${item['subtotal']}'),
                ],
              );
            }).toList(),

            pw.Divider(),
            pw.SizedBox(height: 8),

            pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL'),
                pw.Text('Rp ${transaksi['total']}'),
              ],
            ),
            pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('BAYAR'),
                pw.Text('Rp ${transaksi['cashPaid']}'),
              ],
            ),
            pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('KEMBALIAN'),
                pw.Text('Rp ${transaksi['change']}'),
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Center(child: pw.Text('Terima Kasih')),
          ],
        );
      },
    ),
  );

  return pdf;
}

/// 🔵 SIMPAN PDF KE FILE (UNTUK SHARE WHATSAPP)
Future<File> saveStrukPdf({
  required Map<String, dynamic> transaksi,
}) async {
  final pdf = await generateStrukPdf(transaksi: transaksi);

  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/struk_${DateTime.now().millisecondsSinceEpoch}.pdf',
  );

  await file.writeAsBytes(await pdf.save());
  return file;
}
