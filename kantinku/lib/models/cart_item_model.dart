class CartItem {
  final int id;
  final int userId;
  final int productId;
  final int jumlah;

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.jumlah,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
      jumlah: json['jumlah'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userId,
      "product_id": productId,
      "jumlah": jumlah,
    };
  }
}
