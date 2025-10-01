// file: screens/order_history_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/order_item_model.dart';
import '../models/product_model.dart';
import '../widgets/order_card.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/empty_state_message.dart'; // Import widget baru
import 'order_detail_screen.dart'; // Import OrderDetailScreen

class OrderHistoryScreen extends StatefulWidget {
  final User user;

  const OrderHistoryScreen({super.key, required this.user});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final ApiService api = ApiService();
  // FIX: Gunakan satu Future untuk menampung data yang sudah diproses
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // FIX: Ubah _loadData menjadi async dan memproses data
  void _loadData() {
    setState(() {
      _dataFuture = _fetchAndProcessData();
    });
  }

  // FIX: Fungsi baru untuk mengambil dan menggabungkan data
  Future<List<dynamic>> _fetchAndProcessData() async {
    // Ambil semua data yang diperlukan secara bersamaan untuk efisiensi.
    // fetchOrders(includeItems: true) akan mengambil pesanan beserta item-itemnya.
    final results = await Future.wait([
      api.fetchOrders(
        includeItems: true,
      ), // <-- PENTING: Ambil pesanan DENGAN itemnya
      api.fetchProducts(),
      api.fetchUsers(), // <-- Ambil juga data semua user
    ]);

    // Kembalikan semua hasil dalam satu list
    return results;
  }

  Future<void> _handleReorder(Order order) async {
    try {
      SnackbarUtils.showMessage(
        context,
        'Memuat ulang pesanan #${order.id}...',
      );

      // FIX: Ambil item dari API karena order.items sudah tidak ada
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

      // Tambahkan item yang valid ke keranjang melalui API
      for (var item in validItems) {
        await api.addToCart(item.productId, item.jumlah);
      }

      SnackbarUtils.showMessage(
        context,
        'Berhasil: ${validItems.length} item ditambahkan ke keranjang!',
      );

      // Navigasi kembali ke ProductScreen (yang akan refresh cart icon)
      Navigator.pop(context);
    } catch (e) {
      SnackbarUtils.showMessage(
        context,
        'Gagal memesan ulang: ${e.toString()}',
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
          allUsers: allUsers, // <-- Teruskan data user
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
      ), // AppBar dipindahkan ke sini
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat riwayat pesanan: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: const EmptyStateMessage(
                message: 'Belum ada riwayat pesanan.',
              ),
            );
          }

          final List<Order> orders = snapshot.data![0] as List<Order>;
          final List<Product> allProducts = snapshot.data![1] as List<Product>;
          final List<User> allUsers = snapshot.data![2] as List<User>;

          if (orders.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: const EmptyStateMessage(
                message: 'Belum ada riwayat pesanan.',
              ),
            );
          }

          // FIX: Urutkan pesanan secara menurun berdasarkan ID.
          // Ini akan selalu dieksekusi saat data berhasil dimuat.
          orders.sort((a, b) => (b.id).compareTo(a.id));

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderCard(
                  order: order,
                  allProducts: allProducts,
                  onReorder: () => _handleReorder(order), // <-- Perbaikan onTap
                  onTap: () => _navigateToDetail(order, allProducts, allUsers),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
