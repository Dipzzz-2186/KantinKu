class Product {
  final int id;
  final String namaProduk;
  final String? deskripsi; // <-- 1. Tambahkan field deskripsi (nullable)
  final int harga;
  final int kategoriId;
  final String? gambar;
  final bool isActive;

  Product({
    required this.id,
    required this.namaProduk,
    this.deskripsi, // <-- 2. Tambahkan di constructor
    required this.harga,
    required this.kategoriId,
    this.gambar,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      namaProduk: json['nama_produk'],
      deskripsi: json['deskripsi'], // <-- 3. Tambahkan dari JSON
      harga: json['harga'],
      kategoriId: json['kategori_id'],
      gambar: json['gambar'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nama_produk": namaProduk,
      "deskripsi": deskripsi, // <-- 4. Tambahkan ke JSON
      "harga": harga,
      "kategori_id": kategoriId,
      "gambar": gambar,
      "is_active": isActive,
    };
  }
}