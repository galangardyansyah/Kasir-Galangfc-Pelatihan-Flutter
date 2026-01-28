import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class FirestoreService {
  final CollectionReference _products = FirebaseFirestore.instance.collection('products');
  final CollectionReference _transactions = FirebaseFirestore.instance.collection('transactions');

  // ==========================================
  // MANAJEMEN PRODUK
  // ==========================================

  // UPDATE: Sekarang menerima parameter imageUrl
  Future<void> addProduct(String name, double price, {String imageUrl = ""}) {
    return _products.add({
      'name': name,
      'price': price,
      'imageUrl': imageUrl, // Menyimpan link foto ke Firestore
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Product>> getProducts() {
    return _products.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // UPDATE: Sekarang menerima parameter imageUrl untuk pembaharuan data
  Future<void> updateProduct(String id, String name, double price, {String imageUrl = ""}) {
    return _products.doc(id).update({
      'name': name, 
      'price': price,
      'imageUrl': imageUrl, // Memperbarui link foto di Firestore
    });
  }

  Future<void> deleteProduct(String id) {
    return _products.doc(id).delete();
  }

  // ==========================================
  // MANAJEMEN TRANSAKSI & DASHBOARD
  // ==========================================

  Stream<Map<String, dynamic>> getTodaySummary() {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _transactions
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      double totalOmzet = 0;
      int totalItems = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalOmzet += (data['totalPrice'] as num? ?? 0).toDouble();
        totalItems += (data['totalItems'] as num? ?? 0).toInt();
      }

      return {
        'omzet': totalOmzet,
        'items': totalItems,
      };
    });
  }
}