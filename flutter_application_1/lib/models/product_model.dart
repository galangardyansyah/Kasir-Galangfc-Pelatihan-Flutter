class Product {
  String id;
  String name;
  double price;
  String imageUrl; // Field baru untuk menyimpan link foto produk

  Product({
    required this.id, 
    required this.name, 
    required this.price, 
    this.imageUrl = "", // Default kosong jika tidak ada foto
  });

  // Fungsi: Mengubah data dari Firebase (Map) menjadi Object Dart (Product)
  factory Product.fromMap(Map<String, dynamic> data, String documentId) {
    return Product(
      id: documentId,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '', // Mengambil link foto dari database
    );
  }

  // Fungsi: Mengubah Object Dart ke Map untuk disimpan kembali ke Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name, 
      'price': price,
      'imageUrl': imageUrl, // Menyimpan link foto ke database
    };
  }
}