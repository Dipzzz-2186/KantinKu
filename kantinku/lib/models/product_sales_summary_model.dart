// filepath: c:\KantinKu\kantinku\lib\models\product_sales_summary_model.dart
class ProductSalesSummary {
  final String productName;
  final int totalOrders;

  ProductSalesSummary({required this.productName, required this.totalOrders});

  factory ProductSalesSummary.fromJson(Map<String, dynamic> json) {
    return ProductSalesSummary(
      productName: json['nama_produk'],
      totalOrders: json['jumlah_pesanan'],
    );
  }
}