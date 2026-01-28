import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key});

  String formatCurrency(double price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Analisis Penjualan", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Pastikan koleksi namanya 'transactions'
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .orderBy('timestamp', descending: true) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada data transaksi"));
          }

          double totalOmzet = 0;
          Map<String, int> produkTerlarisMap = {};
          List<FlSpot> spots = [];

          final allDocs = snapshot.data!.docs;

          // 1. Logika Pengolahan Data
          for (var doc in allDocs) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Hitung total omzet (menggunakan totalPrice atau hitung dari cashPaid - change)
            double untung = (data['totalPrice'] ?? (data['cashPaid'] - data['change'])).toDouble();
            totalOmzet += untung;

            // Logika Produk Terlaris (SESUAI GAMBAR: items -> qty)
            if (data['items'] != null) {
              List items = data['items'];
              for (var item in items) {
                String namaProduk = item['name'] ?? 'Produk';
                int jumlah = item['qty'] ?? 0; // SESUAI GAMBAR: qty
                produkTerlarisMap[namaProduk] = (produkTerlarisMap[namaProduk] ?? 0) + jumlah;
              }
            }
          }

          // 2. Sorting Top 3 Produk
          var sortedProduk = produkTerlarisMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          var top3Produk = sortedProduk.take(3).toList();

          // 3. Data Grafik (7 Transaksi Terakhir)
          final last7Docs = allDocs.take(7).toList().reversed.toList();
          for (int i = 0; i < last7Docs.length; i++) {
            final d = last7Docs[i].data() as Map<String, dynamic>;
            double nilai = (d['totalPrice'] ?? (d['cashPaid'] - d['change'])).toDouble();
            spots.add(FlSpot(i.toDouble(), nilai));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeadlineCard(isDark, totalOmzet, allDocs.length),
                const SizedBox(height: 24),
                
                Text("Produk Terlaris", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 12),
                
                if (top3Produk.isEmpty)
                  const Text("Belum ada data barang terjual")
                else
                  ...top3Produk.map((e) => _buildTopProductTile(e.key, e.value, isDark)).toList(),

                const SizedBox(height: 24),
                Text("Tren Penjualan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 16),
                _buildChartContainer(context, spots),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET HELPER (Sama seperti sebelumnya) ---

  Widget _buildHeadlineCard(bool isDark, double total, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade600]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Akumulasi Omzet", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 4),
          Text(formatCurrency(total), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 20),
          Text("Total $count Transaksi", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTopProductTile(String name, int qty, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text("$qty pcs", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer(BuildContext context, List<FlSpot> spots) {
    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.05)),
            ),
          ],
        ),
      ),
    );
  }
}