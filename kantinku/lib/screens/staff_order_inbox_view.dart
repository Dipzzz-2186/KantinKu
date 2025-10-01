// file: screens/staff_order_inbox_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantinku/models/user_model.dart';
import '../services/api_service.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../utils/snackbar_utils.dart';
import 'dart:async'; // Untuk Timer (simulasi realtime)
import '../widgets/empty_state_message.dart'; // Import widget baru
import 'staff_order_detail_screen.dart'; // Import layar detail baru

class StaffOrderInboxView extends StatefulWidget {
  final int staffId;
  const StaffOrderInboxView({super.key, required this.staffId});

  @override
  _StaffOrderInboxViewState createState() => _StaffOrderInboxViewState();
}

class _StaffOrderInboxViewState extends State<StaffOrderInboxView> {
  final ApiService api = ApiService();
  List<Order> _inboxOrders = [];
  bool _isLoading = true;
  List<User> _allUsers = []; // Simpan semua pengguna untuk referensi
  List<Product> _allProducts = []; // Simpan semua produk untuk referensi
  Timer? _timer; // Timer untuk polling (simulasi realtime)

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _fetchInboxOrders();
    // Refresh setiap 10 detik (Simulasi Realtime)
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchInboxOrders(showNotification: true);
    });
  }

  Future<void> _fetchInboxOrders({bool showNotification = false}) async {
    // Jangan tampilkan loading indicator saat polling, agar tidak mengganggu
    if (mounted && !showNotification) {
      setState(() => _isLoading = true);
    }

    try {
      // FIX: Ambil semua data yang diperlukan secara bersamaan
      final results = await Future.wait([
        api.fetchStaffOrderInbox(
          widget.staffId,
        ), // Ini sudah include_items=true
        if (_allProducts.isEmpty) api.fetchProducts(),
        if (_allUsers.isEmpty) api.fetchUsers(),
      ]);

      // FIX: Tambahkan null-check untuk setiap hasil dari Future.wait
      final orders = results[0] as List<Order>;
      if (results.length > 1 && results[1] != null && _allProducts.isEmpty) {
        _allProducts = results[1] as List<Product>;
      }
      if (results.length > 2 && results[2] != null && _allUsers.isEmpty) {
        _allUsers = results[2] as List<User>;
      }

      // FIX: Filter pesanan di sisi client untuk menampilkan status yang relevan.
      // Pesanan akan tetap di inbox selama statusnya 'paid', 'cooking', atau 'ready_for_pickup'.
      final relevantOrders = orders.where((order) {
        final status = order.status.toLowerCase();
        return status == 'paid' ||
            status == 'cooking' ||
            status == 'ready_for_pickup';
      }).toList();

      if (mounted) {
        final newOrdersCount = relevantOrders.length - _inboxOrders.length;
        setState(() {
          _inboxOrders = relevantOrders;
        });

        if (showNotification && newOrdersCount > 0) {
          SnackbarUtils.showMessage(
            context,
            'Ada $newOrdersCount pesanan baru!',
          );
        }
      }
    } catch (e) {
      SnackbarUtils.showMessage(
        context,
        'Gagal memuat pesanan masuk: ${e.toString()}',
      );
    } finally {
      if (!showNotification) setState(() => _isLoading = false);
    }
  }

  void _navigateToDetail(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StaffOrderDetailScreen(
          order: order,
          allProducts: _allProducts,
          allUsers: _allUsers, // Teruskan daftar pengguna
          onStatusUpdated: () => _fetchInboxOrders(), // Callback untuk refresh
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _inboxOrders.isEmpty
        ? RefreshIndicator(
            onRefresh: () => _fetchInboxOrders(),
            child: const EmptyStateMessage(
              message: "Tidak ada pesanan yang perlu disiapkan.",
            ),
          )
        : RefreshIndicator(
            onRefresh: () => _fetchInboxOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _inboxOrders.length,
              itemBuilder: (context, index) {
                final order = _inboxOrders[index];
                final formattedDate = order.tanggalPesanan != null
                    ? DateFormat(
                        'HH:mm',
                      ).format(DateTime.parse(order.tanggalPesanan!))
                    : 'N/A';

                // Ambil nama customer dari list allUsers
                final customerName = _allUsers
                    .firstWhere(
                      (user) => user.id == order.userId,
                      orElse: () => User(id: 0, namaPengguna: 'N/A', role: ''),
                    )
                    .namaPengguna;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade200, width: 1.5),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    title: Text(
                      'Pesanan #${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Pemesan: $customerName • Total: Rp ${order.totalHarga.toStringAsFixed(0)}',
                    ),
                    trailing: Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    onTap: () => _navigateToDetail(order),
                  ),
                );
              },
            ),
          );
  }
}
