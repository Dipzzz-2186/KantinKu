class Order {
  final int id;
  final int userId;
  final String status;
  final double totalHarga;
  final String? tanggalPesanan;
  final String? snapRedirectUrl;

  Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.totalHarga,
    this.tanggalPesanan,
    this.snapRedirectUrl,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      status: json['status'],
      totalHarga: (json['total_harga'] as num).toDouble(),
      tanggalPesanan: json['tanggal_pesanan'],
      snapRedirectUrl:
          json['snap_redirect_url'], // Pastikan nama field ini sama persis dengan di JSON response
    );
  }

  Order copyWith() {
    return Order(
      id: id,
      userId: userId,
      status: status,
      totalHarga: totalHarga,
      tanggalPesanan: tanggalPesanan,
      snapRedirectUrl: snapRedirectUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userId,
      "status": status,
      "total_harga": totalHarga,
      "tanggal_pesanan": tanggalPesanan,
      "snap_redirect_url": snapRedirectUrl,
    };
  }
}
