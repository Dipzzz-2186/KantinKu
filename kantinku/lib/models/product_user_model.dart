class ProductUser {
  final int id;
  final int userId;
  final int productId;

  ProductUser({
    required this.id,
    required this.userId,
    required this.productId,
  });

  factory ProductUser.fromJson(Map<String, dynamic> json) {
    return ProductUser(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userId,
      "product_id": productId,
    };
  }
}
