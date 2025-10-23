class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int jumlah;
  final double hargaUnit;
  final double subtotal;
  final String status;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.jumlah,
    required this.hargaUnit,
    required this.subtotal,
    required this.status,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      jumlah: json['jumlah'],
      hargaUnit: (json['harga_unit'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      status: json['status'] ?? 'paid',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "order_id": orderId,
      "product_id": productId,
      "jumlah": jumlah,
      "harga_unit": hargaUnit,
      "subtotal": subtotal,
      "status": status,
    };
  }
}
