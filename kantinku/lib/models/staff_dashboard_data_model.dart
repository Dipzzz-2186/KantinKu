// filepath: c:\KantinKu\kantinku\lib\models\staff_dashboard_data_model.dart
import 'product_sales_summary_model.dart';
import 'sales_data_model.dart';

class StaffDashboardData {
  final List<SalesData> dailySales;
  final List<ProductSalesSummary> productSales;
  final double totalRevenue;

  StaffDashboardData({
    required this.dailySales,
    required this.productSales,
    required this.totalRevenue,
  });
}