class Category {
  final int id;
  final String kategori;

  Category({
    required this.id,
    required this.kategori,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      kategori: json['kategori'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "kategori": kategori,
    };
  }
}
