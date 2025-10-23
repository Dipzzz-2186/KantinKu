import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantinku/models/user_model.dart';
import '../services/api_service.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../utils/snackbar_utils.dart';
import 'dart:async';
import '../widgets/empty_state_message.dart';
import 'staff_order_detail_screen.dart';

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
  List<User> _allUsers = [];
  List<Product> _allProducts = [];
  Timer? _timer;

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
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchInboxOrders(showNotification: true);
    });
  }

  Future<void> _fetchInboxOrders({bool showNotification = false}) async {
    if (mounted && !showNotification) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        api.fetchStaffOrderInbox(widget.staffId),
        if (_allProducts.isEmpty) api.fetchProducts(),
        if (_allUsers.isEmpty) api.fetchUsers(),
      ]);

      final orders = results[0] as List<Order>;
      if (results.length > 1 && _allProducts.isEmpty) {
        _allProducts = results[1] as List<Product>;
      }
      if (results.length > 2 && _allUsers.isEmpty) {
        _allUsers = results[2] as List<User>;
      }

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
          allUsers: _allUsers,
          staffId: widget.staffId,
          onStatusUpdated: () => _fetchInboxOrders(),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.orange.shade300;
      case 'cooking':
        return Colors.blue.shade300;
      case 'ready_for_pickup':
        return Colors.green.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.payments_outlined;
      case 'cooking':
        return Icons.restaurant_menu_rounded;
      case 'ready_for_pickup':
        return Icons.delivery_dining_rounded;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _inboxOrders.isEmpty
        ? RefreshIndicator(
            onRefresh: _fetchInboxOrders,
            child: const EmptyStateMessage(
              message: "Tidak ada pesanan yang perlu disiapkan.",
            ),
          )
        : RefreshIndicator(
            onRefresh: _fetchInboxOrders,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _inboxOrders.length,
              itemBuilder: (context, index) {
                final order = _inboxOrders[index];
                final formattedDate = order.tanggalPesanan != null
                    ? DateFormat('HH:mm').format(DateTime.parse(order.tanggalPesanan!))
                    : 'N/A';

                final customerName = _allUsers
                    .firstWhere(
                      (user) => user.id == order.userId,
                      orElse: () => User(id: 0, namaPengguna: 'N/A', role: ''),
                    )
                    .namaPengguna;

                final statusColor = _getStatusColor(order.status);
                final statusIcon = _getStatusIcon(order.status);

                return GestureDetector(
                  onTap: () => _navigateToDetail(order),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor,
                        child: Icon(statusIcon, color: Colors.white),
                      ),
                      title: Text(
                        'Pesanan #${order.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Pemesan: $customerName',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total: Rp ${order.totalHarga.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
  }
}
