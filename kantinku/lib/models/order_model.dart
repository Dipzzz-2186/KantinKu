class Order {
  final int id;
  final int userId;
  final String status;
  final double totalHarga;

  Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.totalHarga,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      status: json['status'],
      totalHarga: (json['total_harga'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userId,
      "status": status,
      "total_harga": totalHarga,
    };
  }
}
