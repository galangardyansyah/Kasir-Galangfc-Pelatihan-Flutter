import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/product_model.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageController = TextEditingController(); // Controller baru untuk link foto

  String formatCurrency(double price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  BoxDecoration _mainGradient(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark 
          ? [const Color(0xFF1A237E), const Color(0xFF121212)] 
          : [Colors.blue.shade900, Colors.blue.shade600],
      ),
    );
  }

  void _showFormDialog(BuildContext context, {Product? product}) {
    if (product != null) {
      _nameController.text = product.name;
      _priceController.text = product.price.toStringAsFixed(0);
      _imageController.text = product.imageUrl; // Set link lama jika edit
    } else {
      _nameController.clear();
      _priceController.clear();
      _imageController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product == null ? "Tambah Produk Baru" : "Edit Produk",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Nama Produk",
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: "Harga (IDR)",
                  prefixIcon: const Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // KOLOM INPUT LINK GAMBAR BARU
              TextField(
                controller: _imageController,
                decoration: InputDecoration(
                  labelText: "Link Foto (URL)",
                  hintText: "Paste link gambar dari Google/ImgBB",
                  prefixIcon: const Icon(Icons.link_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final name = _nameController.text;
                    final price = double.tryParse(_priceController.text) ?? 0;
                    final imageUrl = _imageController.text; // Ambil data URL

                    if (product == null) {
                      // Kamu perlu pastikan FirestoreService.addProduct mendukung parameter imageUrl
                      _firestoreService.addProduct(name, price, imageUrl: imageUrl);
                    } else {
                      _firestoreService.updateProduct(product.id, name, price, imageUrl: imageUrl);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Simpan Data", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(decoration: _mainGradient(context)),
              title: const Text("Dashboard", 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              IconButton(
                onPressed: () => FirebaseAuth.instance.signOut(), 
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // RINGKASAN
          SliverToBoxAdapter(
            child: StreamBuilder<Map<String, dynamic>>(
              stream: _firestoreService.getTodaySummary(),
              builder: (context, snapshot) {
                final data = snapshot.data ?? {'omzet': 0.0, 'items': 0};
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Ringkasan Hari Ini", 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, 
                        color: isDark ? Colors.white : Colors.blueGrey.shade900)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildModernStatCard(context, "Omzet", formatCurrency(data['omzet'].toDouble()), Icons.payments_rounded, Colors.blue.shade700),
                          const SizedBox(width: 12),
                          _buildModernStatCard(context, "Terjual", "${data['items']} Item", Icons.shopping_bag_rounded, Colors.orange.shade700),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          _buildSectionTitle(context, "Katalog Produk"),

          StreamBuilder<List<Product>>(
            stream: _firestoreService.getProducts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              final products = snapshot.data!;
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildProductItem(context, products[index]),
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(context),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        label: const Text("Tambah Produk"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        // MENAMPILKAN FOTO PRODUK
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 50,
            height: 50,
            color: Colors.blue.withOpacity(0.1),
            child: product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    // Jika link error, tampilkan icon standar
                    errorBuilder: (context, error, stackTrace) => 
                      Icon(Icons.inventory_2, color: Colors.blue.shade800),
                  )
                : Icon(Icons.inventory_2, color: Colors.blue.shade800),
          ),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(formatCurrency(product.price), style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 22),
          onPressed: () => _showFormDialog(context, product: product),
        ),
      ),
    );
  }

  Widget _buildModernStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
        child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ),
    );
  }
}