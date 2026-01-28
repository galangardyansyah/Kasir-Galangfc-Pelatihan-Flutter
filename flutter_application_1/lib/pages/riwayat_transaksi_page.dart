import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../services/struk_pdf.dart';

class RiwayatTransaksiPage extends StatelessWidget {
  const RiwayatTransaksiPage({super.key});

  // Fungsi helper format rupiah
  String formatIDR(dynamic amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(amount ?? 0);
  }

  Future<void> _deleteTransaction(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('transactions').doc(docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi berhasil dihapus')));
      }
    }
  }

  Future<void> _printStruk(Map<String, dynamic> transaksi) async {
    final pdf = await generateStrukPdf(transaksi: transaksi);
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _shareStruk(Map<String, dynamic> transaksi) async {
    try {
      final file = await saveStrukPdf(transaksi: transaksi);
      await Share.shareXFiles([XFile(file.path)], text: 'Struk Pembelian');
    } catch (e) {
      debugPrint('ERROR SHARE: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada transaksi'));
          }

          final transactions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final doc = transactions[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
              final ts = data['timestamp'] as Timestamp?;
              final date = ts != null ? ts.toDate() : DateTime.now();
              
              final totalPrice = (data['totalPrice'] as num? ?? 0).toInt();
              final cashPaid = (data['cashPaid'] as num? ?? 0).toInt();
              final change = (data['change'] as num? ?? 0).toInt();

              final transaksiPdf = {
                'date': DateFormat('dd/MM/yyyy HH:mm').format(date),
                'items': items,
                'totalPrice': totalPrice,
                'cashPaid': cashPaid,
                'change': change,
              };

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ExpansionTile(
                  leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
                  title: Text(
                    formatIDR(totalPrice),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(date)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRowInfo('Total:', formatIDR(totalPrice)),
                          _buildRowInfo('Bayar:', formatIDR(cashPaid)),
                          _buildRowInfo('Kembalian:', formatIDR(change), isGreen: true),
                          const Divider(height: 32),
                          const Text('Detail Produk:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          
                          // Bagian Detail Produk yang sudah diperbaiki
                          ...items.map((item) {
                            // Ambil subtotal, jika null/0, hitung manual dari price * qty
                            final qty = item['qty'] ?? 1;
                            final price = item['price'] ?? 0;
                            final subtotal = (item['subtotal'] != null && item['subtotal'] != 0) 
                                             ? item['subtotal'] 
                                             : (price * qty);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(child: Text("${item['name'] ?? 'Produk'} (x$qty)")),
                                  Text(formatIDR(subtotal)),
                                ],
                              ),
                            );
                          }),
                          
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.print, size: 18),
                                  label: const Text('Cetak'),
                                  onPressed: () => _printStruk(transaksiPdf),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.share, size: 18),
                                  label: const Text('WA'),
                                  onPressed: () => _shareStruk(transaksiPdf),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red,
                                onPressed: () => _deleteTransaction(context, doc.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Widget tambahan biar kode lebih rapi
  Widget _buildRowInfo(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isGreen ? FontWeight.bold : FontWeight.normal,
              color: isGreen ? Colors.green : Colors.black,
            ),
          )
        ],
      ),
    );
  }
}