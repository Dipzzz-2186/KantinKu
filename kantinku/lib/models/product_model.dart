class Product {
  final int id;
  final String namaProduk;
  final int harga;
  final int kategoriId;
  final String? gambar;
  final bool isActive; // Menambahkan field isActive

  Product({
    required this.id,
    required this.namaProduk,
    required this.harga,
    required this.kategoriId,
    this.gambar,
    this.isActive = true, // Default true jika tidak disediakan
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      namaProduk: json['nama_produk'],
      harga: json['harga'],
      kategoriId: json['kategori_id'],
      gambar: json['gambar'],
      isActive: json['is_active'] ?? true, // Default true jika tidak ada di JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nama_produk": namaProduk,
      "harga": harga,
      "kategori_id": kategoriId,
      "gambar": gambar,
      "is_active": isActive,
    };
  }
}
