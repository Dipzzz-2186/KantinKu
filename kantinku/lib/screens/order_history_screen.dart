// file: screens/order_history_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/order_item_model.dart';
import '../models/product_model.dart';
import '../widgets/order_card.dart';
import '../utils/snackbar_utils.dart';
import 'payment_screen.dart';
import '../widgets/empty_state_message.dart';
import 'order_detail_screen.dart';
import 'dart:async';

class OrderHistoryScreen extends StatefulWidget {
  final User user;

  const OrderHistoryScreen({super.key, required this.user});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  final ApiService api = ApiService();
  late Future<List<dynamic>> _dataFuture;
  late TabController _tabController;
  String _selectedFilter = 'all';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _selectedFilter = 'all';
              break;
            case 1:
              _selectedFilter = 'pending';
              break;
            case 2:
              _selectedFilter = 'completed';
              break;
            case 3:
              _selectedFilter = 'cancelled';
              break;
          }
        });
      }
    });
    _loadData();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Memanggil _loadData akan secara otomatis memuat ulang data
      // dan memperbarui UI melalui FutureBuilder.
      _loadData();
    });
  }

  void _loadData() {
    setState(() {
      _dataFuture = _fetchAndProcessData();
    });
  }

  Future<List<dynamic>> _fetchAndProcessData() async {
    final results = await Future.wait([
      api.fetchOrders(includeItems: true),
      api.fetchProducts(),
      api.fetchUsers(),
    ]);

    final List<Order> orders = results[0] as List<Order>;
    final now = DateTime.now();

    final filteredOrders = orders.where((order) {
      if (order.status.toLowerCase() == 'pending' &&
          order.tanggalPesanan != null) {
        try {
          final orderDate = DateTime.parse(order.tanggalPesanan!);
          if (now.difference(orderDate).inMinutes >= 15) {
            return false;
          }
        } catch (e) {
          // Ignore date parsing errors
        }
      }
      return true;
    }).toList();

    return [filteredOrders, results[1], results[2]];
  }

  Future<void> _handleReorder(Order order) async {
    try {
      SnackbarUtils.showMessage(
        context,
        'Memuat ulang pesanan #${order.id}...',
      );

      final orderItems = await api.fetchOrderItemsByOrderId(order.id);
      final activeProducts = await api.fetchProducts();
      final activeProductIds = activeProducts.map((p) => p.id).toSet();

      List<OrderItem> validItems = [];
      for (var item in orderItems) {
        if (activeProductIds.contains(item.productId)) {
          validItems.add(item);
        }
      }

      if (validItems.isEmpty) {
        SnackbarUtils.showMessage(
          context,
          'Tidak ada item yang aktif untuk dipesan ulang.',
        );
        return;
      }

      for (var item in validItems) {
        await api.addToCart(item.productId, item.jumlah);
      }

      SnackbarUtils.showMessage(
        context,
        'Berhasil: ${validItems.length} item ditambahkan ke keranjang!',
      );

      Navigator.pop(context);
    } catch (e) {
      SnackbarUtils.showMessage(
        context,
        'Gagal memesan ulang: ${e.toString()}',
      );
    }
  }

  Future<void> _handleContinuePayment(Order order) async {
    final redirectUrl = order.snapRedirectUrl;

    if (redirectUrl != null && redirectUrl.isNotEmpty) {
      SnackbarUtils.showMessage(context, 'Mempersiapkan pembayaran...');
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(redirectUrl: redirectUrl),
          ),
        );

        if (result == true) {
          SnackbarUtils.showMessage(context, 'Pembayaran berhasil!');
        }
        _loadData();
      }
    } else {
      SnackbarUtils.showMessage(
        context,
        'Gagal melanjutkan: URL pembayaran untuk pesanan ini tidak ditemukan. Silakan coba buat pesanan baru.',
      );
    }
  }

  void _navigateToDetail(
    Order order,
    List<Product> allProducts,
    List<User> allUsers,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(
          order: order,
          allProducts: allProducts,
          allUsers: allUsers,
        ),
      ),
    );
  }

  List<Order> _filterOrders(List<Order> orders) {
    if (_selectedFilter == 'all') return orders;
    return orders
        .where((order) =>
            order.status.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

  int _getOrderCount(List<Order> orders, String status) {
    if (status == 'all') return orders.length;
    return orders
        .where((order) => order.status.toLowerCase() == status.toLowerCase())
        .length;
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF5D4037);
    const backgroundColor = Color(0xFFFFFBF5);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Riwayat Pesanan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Lihat semua pesanan Anda',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: primaryColor,
            child: FutureBuilder<List<dynamic>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                final orders = snapshot.hasData
                    ? snapshot.data![0] as List<Order>
                    : <Order>[];

                return TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        children: [
                          const Text('Semua'),
                          if (orders.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_getOrderCount(orders, 'all')}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        children: [
                          const Text('Pending'),
                          if (orders.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_getOrderCount(orders, 'pending')}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        children: [
                          const Text('Selesai'),
                          if (orders.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_getOrderCount(orders, 'completed')}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        children: [
                          const Text('Dibatalkan'),
                          if (orders.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_getOrderCount(orders, 'cancelled')}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
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
                    'Memuat riwayat pesanan...',
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
                      'Gagal memuat riwayat pesanan',
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
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return RefreshIndicator(
              onRefresh: () async => _loadData(),
              color: primaryColor,
              child: const EmptyStateMessage(
                message: 'Belum ada riwayat pesanan.',
              ),
            );
          }

          final List<Order> allOrders = snapshot.data![0] as List<Order>;
          final List<Product> allProducts = snapshot.data![1] as List<Product>;
          final List<User> allUsers = snapshot.data![2] as List<User>;

          // Sort orders by ID descending
          allOrders.sort((a, b) => (b.id).compareTo(a.id));

          // Filter orders based on selected tab
          final filteredOrders = _filterOrders(allOrders);

          if (filteredOrders.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _loadData(),
              color: primaryColor,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 60),
                  Icon(
                    _selectedFilter == 'all'
                        ? Icons.receipt_long_outlined
                        : _selectedFilter == 'pending'
                            ? Icons.pending_actions_outlined
                            : _selectedFilter == 'completed'
                                ? Icons.check_circle_outline
                                : Icons.cancel_outlined,
                    size: 80,
                    color: primaryColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFilter == 'all'
                        ? 'Belum ada riwayat pesanan'
                        : _selectedFilter == 'pending'
                            ? 'Tidak ada pesanan pending'
                            : _selectedFilter == 'completed'
                                ? 'Belum ada pesanan selesai'
                                : 'Tidak ada pesanan dibatalkan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFilter == 'all'
                        ? 'Mulai pesan sekarang!'
                        : 'Coba filter lain atau pesan sekarang',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primaryColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            color: primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OrderCard(
                    order: order,
                    allProducts: allProducts,
                    onReorder: () => _handleReorder(order),
                    onContinuePayment: () => _handleContinuePayment(order),
                    onTap: () =>
                        _navigateToDetail(order, allProducts, allUsers),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}