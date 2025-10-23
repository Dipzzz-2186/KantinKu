import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:kantinku/models/product_sales_summary_model.dart';
import 'package:kantinku/models/sales_data_model.dart';
import 'package:kantinku/models/staff_dashboard_data_model.dart';
import 'package:kantinku/services/api_service.dart';
import 'package:kantinku/widgets/empty_state_message.dart';
import 'package:kantinku/utils/excel_export_utils.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/product_model.dart';

enum ExportType { daily, weekly, total }

class StaffDashboardView extends StatefulWidget {
  final int staffId;
  final String staffName;
  const StaffDashboardView({
    super.key,
    required this.staffId,
    required this.staffName,
  });

  @override
  State<StaffDashboardView> createState() => _StaffDashboardViewState();
}

class _StaffDashboardViewState extends State<StaffDashboardView> {
  final ApiService api = ApiService();
  late Future<StaffDashboardData> _dashboardDataFuture;
  bool _isExporting = false;

  // Enhanced Color Palette
  static const primaryColor = Color(0xFF5D4037);
  static const secondaryColor = Color(0xFF8D6E63);
  static const backgroundColor = Color(0xFFFFFBF5);
  static const accentColor = Color(0xFFE65100);
  static const textColor = Color(0xFF3E2723);

  // Warna untuk PieChart - More vibrant
  final List<Color> pieChartColors = [
    const Color(0xFF5D4037),
    const Color(0xFFE65100),
    const Color(0xFFFFA726),
    const Color(0xFF66BB6A),
    const Color(0xFF42A5F5),
    const Color(0xFFAB47BC),
  ];

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = api.fetchStaffDashboardData(widget.staffId);
  }

  Future<void> _handleExport(ExportType type) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final exportData = await api.fetchStaffExportData(widget.staffId);
      final List<Order> allOrders = exportData['orders'] ?? [];
      final List<OrderItem> allItems = exportData['items'] ?? [];
      final List<Product> allProducts = exportData['products'] ?? [];

      if (allItems.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Tidak ada data penjualan untuk diekspor.')),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      List<int>? fileBytes;
      String fileName = '';
      final staffNameSafe = widget.staffName.replaceAll(' ', '_');
      final dateSuffix = DateFormat('yyyyMMdd').format(DateTime.now());

      switch (type) {
        case ExportType.daily:
          fileBytes = await ExcelExportUtils.exportDailyReport(
            orders: allOrders,
            items: allItems,
            products: allProducts,
            staffName: widget.staffName,
          );
          fileName = 'Rekap_${staffNameSafe}_Harian_${dateSuffix}.xlsx';
          break;
        case ExportType.weekly:
          fileBytes = await ExcelExportUtils.exportWeeklyReport(
            orders: allOrders,
            items: allItems,
            products: allProducts,
            staffName: widget.staffName,
          );
          fileName = 'Rekap_${staffNameSafe}_Mingguan_${dateSuffix}.xlsx';
          break;
        case ExportType.total:
          fileBytes = await ExcelExportUtils.exportTotalReport(
            orders: allOrders,
            items: allItems,
            products: allProducts,
            staffName: widget.staffName,
          );
          fileName = 'Rekap_${staffNameSafe}_Total_${dateSuffix}.xlsx';
          break;
      }

      if (fileBytes != null && mounted) {
        await ExcelExportUtils.saveFile(fileBytes, fileName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Laporan berhasil dibuat: $fileName')),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Gagal membuat file: tidak ada data untuk diekspor.'),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Gagal membuat file Excel: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String formatAxisValue(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}jt';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }

  List<SalesData> _prepareChartData(List<SalesData> dailySales) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final salesMap = {
      for (var sale in dailySales)
        DateTime(sale.date.year, sale.date.month, sale.date.day): sale.totalSales
    };

    return List.generate(7, (i) {
      final day = startOfWeek.add(Duration(days: i));
      final dateOnly = DateTime(day.year, day.month, day.day);
      final sales = salesMap[dateOnly] ?? 0.0;
      return SalesData(date: day, totalSales: sales);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (_isExporting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: primaryColor,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: PopupMenuButton<ExportType>(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                     boxShadow: [
                        BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                        )
                    ]
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                tooltip: 'Ekspor Laporan',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (ExportType type) {
                  _handleExport(type);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<ExportType>>[
                  const PopupMenuItem<ExportType>(
                    value: ExportType.daily,
                    child: Row(
                      children: [
                        Icon(Icons.today, size: 20, color: primaryColor),
                        SizedBox(width: 12),
                        Text('Rekap Harian'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<ExportType>(
                    value: ExportType.weekly,
                    child: Row(
                      children: [
                        Icon(Icons.date_range, size: 20, color: primaryColor),
                        SizedBox(width: 12),
                        Text('Rekap Mingguan'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<ExportType>(
                    value: ExportType.total,
                    child: Row(
                      children: [
                        Icon(Icons.summarize, size: 20, color: primaryColor),
                        SizedBox(width: 12),
                        Text('Rekap Total'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: FutureBuilder<StaffDashboardData>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: primaryColor,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat data dashboard...',
                    style: TextStyle(
                      color: primaryColor.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.dailySales.isEmpty) {
            return const EmptyStateMessage(
              message: 'Belum ada data penjualan.',
              icon: Icons.show_chart_outlined,
            );
          }

          final dashboardData = snapshot.data!;
          final totalRevenue = dashboardData.totalRevenue;
          final productSales = dashboardData.productSales;

          final chartSalesData = _prepareChartData(dashboardData.dailySales);
          final maxYValue = chartSalesData.isEmpty
              ? 10.0
              : (chartSalesData.map((d) => d.totalSales).reduce((a, b) => a > b ? a : b) * 1.2);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dashboardDataFuture = api.fetchStaffDashboardData(widget.staffId);
              });
            },
            color: primaryColor,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard Penjualan',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      Text(
                        widget.staffName,
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTotalRevenueCard(totalRevenue),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  'Pendapatan Harian',
                  'Data untuk minggu ini',
                  Icons.trending_up,
                ),
                const SizedBox(height: 16),
                _buildLineChartCard(chartSalesData, maxYValue),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  'Produk Terlaris',
                  'Berdasarkan jumlah pesanan',
                  Icons.stars,
                ),
                const SizedBox(height: 16),
                _buildPieChartCard(productSales),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryColor, secondaryColor],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRevenueCard(double totalRevenue) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            secondaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Total',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Total Pendapatan',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatCurrency(totalRevenue),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChartCard(List<SalesData> salesData, double maxY) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          height: 280,
          child: LineChart(
            LineChartData(
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value >= meta.max) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        space: 8.0,
                        child: Text(
                          formatAxisValue(value),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    // --- PERBAIKAN: Tambahkan baris ini ---
                    interval: 1, // Ini akan memaksa label untuk muncul hanya di titik 0, 1, 2, dst.
                    getTitlesWidget: (value, meta) {
                      // Tambahkan pengecekan untuk menghindari error jika value di luar jangkauan
                      if (value.toInt() >= salesData.length) {
                        return const SizedBox.shrink();
                      }
                      final date = salesData[value.toInt()].date;
                      return SideTitleWidget(
                        meta: meta,
                        space: 8.0,
                        child: Text(
                          DateFormat('E', 'id_ID').format(date),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                    reservedSize: 32,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(salesData.length, (index) {
                    final data = salesData[index];
                    return FlSpot(index.toDouble(), data.totalSales);
                  }),
                  isCurved: true,
                  gradient: const LinearGradient(
                    colors: [accentColor, primaryColor],
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: primaryColor,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.2),
                        primaryColor.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChartCard(List<ProductSalesSummary> productSales) {
    if (productSales.isEmpty) {
      return const EmptyStateMessage(
        message: 'Belum ada produk yang terjual.',
        icon: Icons.pie_chart_outline,
      );
    }

    final totalOrders =
        productSales.fold<int>(0, (sum, item) => sum + item.totalOrders);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 60,
                  sections: List.generate(productSales.length, (index) {
                    final data = productSales[index];
                    final percentage = (data.totalOrders / totalOrders) * 100;
                    final isTouched = false;
                    final radius = isTouched ? 65.0 : 55.0;
                    return PieChartSectionData(
                      color: pieChartColors[index % pieChartColors.length],
                      value: data.totalOrders.toDouble(),
                      title: '${percentage.toStringAsFixed(0)}%',
                      radius: radius,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            ...List.generate(productSales.length, (index) {
              final data = productSales[index];
              final percentage = (data.totalOrders / totalOrders) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: pieChartColors[index % pieChartColors.length],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data.productName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${data.totalOrders} pcs',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pieChartColors[index % pieChartColors.length]
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: pieChartColors[index % pieChartColors.length],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}