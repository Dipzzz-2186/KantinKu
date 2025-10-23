// file: lib/models/sales_data_model.dart

class SalesData {
  final DateTime date;
  final double totalSales;

  SalesData({required this.date, required this.totalSales});

  factory SalesData.fromJson(Map<String, dynamic> json) {
    return SalesData(
      date: DateTime.parse(json['tanggal']),
      totalSales: (json['total_penjualan'] as num).toDouble(),
    );
  }
}
