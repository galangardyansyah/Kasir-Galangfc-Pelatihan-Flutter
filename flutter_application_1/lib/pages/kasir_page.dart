import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../services/struk_pdf.dart';
import 'scan_page.dart';

class KasirPage extends StatefulWidget {
  const KasirPage({super.key});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  final List<Map<String, dynamic>> _cart = [];
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final _rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _ribuan = NumberFormat("#,###", "id_ID");

  int _cashPaidRaw = 0;

  @override
  void dispose() {
    _cashController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int get _totalPrice => _cart.fold(
        0,
        (sum, item) => sum + ((item['price'] as num).toInt() * (item['qty'] as int)),
      );

  int get _change => _cashPaidRaw - _totalPrice;

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final index = _cart.indexWhere((item) => item['name'] == product['name']);
      if (index >= 0) {
        _cart[index]['qty']++;
      } else {
        _cart.add({
          'name': product['name'],
          'price': (product['price'] as num).toInt(),
          'qty': 1,
        });
      }
    });
  }

  void _updateQty(int index, int change) {
    setState(() {
      _cart[index]['qty'] += change;
      if (_cart[index]['qty'] <= 0) {
        _cart.removeAt(index);
      }
    });
  }

  Future<void> _payAndPrint() async {
    if (_cart.isEmpty) return;
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    
    final now = DateTime.now();
    final transaksi = {
      'date': '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      'totalPrice': _totalPrice,
      'totalItems': _cart.fold(0, (sum, item) => sum + (item['qty'] as int)),
      'cashPaid': _cashPaidRaw,
      'change': _change,
      'timestamp': FieldValue.serverTimestamp(),
      'items': _cart.toList(),
    };

    try {
      await FirebaseFirestore.instance.collection('transactions').add(transaksi);
      if (mounted) Navigator.pop(context);
      final pdf = await generateStrukPdf(transaksi: transaksi);
      await Printing.layoutPdf(onLayout: (_) async => pdf.save());
      setState(() { _cart.clear(); _cashController.clear(); _cashPaidRaw = 0; });
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _showCartDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25))
          ),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 15),
              const Text("🛒 Detail Keranjang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              Expanded(
                child: _cart.isEmpty 
                ? const Center(child: Text("Keranjang kosong"))
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text(_cart[i]['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(_rupiah.format(_cart[i]['price'])),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () { _updateQty(i, -1); setDialogState(() {}); setState(() {}); }),
                        Text("${_cart[i]['qty']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green), onPressed: () { _updateQty(i, 1); setDialogState(() {}); setState(() {}); }),
                      ]),
                    ),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanProduct() async {
    final productId = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanPage()));
    if (productId == null) return;
    final doc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
    if (doc.exists) {
      final data = doc.data()!;
      _addToCart({'name': data['name'], 'price': data['price']});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('KASIR GALANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: _scanProduct),
        ],
      ),
      
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs.where((doc) => doc['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase())).toList();
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String imageUrl = data.containsKey('imageUrl') ? data['imageUrl'].toString() : '';
                    
                    return Card(
                      color: isDark ? const Color(0xFF1B263B) : Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 50, height: 50,
                            child: imageUrl.isNotEmpty 
                                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image))
                                : const Icon(Icons.inventory_2),
                          ),
                        ),
                        title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(_rupiah.format(data['price']), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_box, color: Colors.blue, size: 30), 
                          onPressed: () => _addToCart(data)
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // PANEL PEMBAYARAN
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B263B) : Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // TOMBOL DETAIL KERANJANG DI SINI
                if (_cart.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: InkWell(
                      onTap: _showCartDetails,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade800,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shopping_cart, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Lihat Detail Pesanan (${_cart.length})",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Bayar:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    Text(_rupiah.format(_totalPrice), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _cashController,
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final raw = val.replaceAll(RegExp(r'[^0-9]'), '');
                    _cashPaidRaw = int.tryParse(raw) ?? 0;
                    _cashController.value = TextEditingValue(
                      text: _ribuan.format(_cashPaidRaw), 
                      selection: TextSelection.collapsed(offset: _ribuan.format(_cashPaidRaw).length)
                    );
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    labelText: "Jumlah Tunai", 
                    prefixText: "Rp ",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: (_cart.isNotEmpty && _cashPaidRaw >= _totalPrice) ? _payAndPrint : null,
                    child: const Text("CETAK STRUK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}