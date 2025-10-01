class Order {
  final int id;
  final int userId;
  final String status;
  final double totalHarga;
  final String? tanggalPesanan;
  // FIX: Tambahkan kembali list of items. Ini akan diisi secara terpisah.

  Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.totalHarga,
    this.tanggalPesanan,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      status: json['status'],
      totalHarga: (json['total_harga'] as num).toDouble(),
      tanggalPesanan: json['tanggal_pesanan'],
    );
  }

  // Helper method untuk membuat salinan Order dengan item yang baru
  Order copyWith() {
    return Order(
      id: id,
      userId: userId,
      status: status,
      totalHarga: totalHarga,
      tanggalPesanan: tanggalPesanan,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userId,
      "status": status,
      "total_harga": totalHarga,
      "tanggal_pesanan": tanggalPesanan,
    };
  }
}
