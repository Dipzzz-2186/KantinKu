class Payment {
  final int id;
  final int orderId;
  final String? transaksiIdMidtrans;
  final String metodePembayaran;
  final double jumlahPembayaran;
  final String? tanggalPembayaran;
  final String statusPembayaran;
  final String? nomorVa;
  final String? qrCodeUrl;
  final String? waktuPenyelesaian;

  Payment({
    required this.id,
    required this.orderId,
    this.transaksiIdMidtrans,
    required this.metodePembayaran,
    required this.jumlahPembayaran,
    this.tanggalPembayaran,
    required this.statusPembayaran,
    this.nomorVa,
    this.qrCodeUrl,
    this.waktuPenyelesaian,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      orderId: json['order_id'],
      transaksiIdMidtrans: json['transaksi_id_midtrans'],
      metodePembayaran: json['metode_pembayaran'],
      jumlahPembayaran: (json['jumlah_pembayaran'] as num).toDouble(),
      tanggalPembayaran: json['tanggal_pembayaran'],
      statusPembayaran: json['status_pembayaran'],
      nomorVa: json['nomor_va'],
      qrCodeUrl: json['qr_code_url'],
      waktuPenyelesaian: json['waktu_penyelesaian'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "order_id": orderId,
      "transaksi_id_midtrans": transaksiIdMidtrans,
      "metode_pembayaran": metodePembayaran,
      "jumlah_pembayaran": jumlahPembayaran,
      "tanggal_pembayaran": tanggalPembayaran,
      "status_pembayaran": statusPembayaran,
      "nomor_va": nomorVa,
      "qr_code_url": qrCodeUrl,
      "waktu_penyelesaian": waktuPenyelesaian,
    };
  }
}
