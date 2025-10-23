// file: screens/staff_order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Models
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/order_item_model.dart';
import '../models/user_model.dart';

// Services & Utils
import '../services/api_service.dart';
import '../utils/snackbar_utils.dart';

// Widgets
import '../widgets/order_action_button.dart';
import '../widgets/order_item_tile.dart';

class StaffOrderDetailScreen extends StatefulWidget {
  final Order order;
  final List<Product> allProducts;
  final List<User> allUsers;
  final VoidCallback onStatusUpdated;
  final int staffId;

  const StaffOrderDetailScreen({
    super.key,
    required this.order,
    required this.allProducts,
    required this.allUsers,
    required this.onStatusUpdated,
    required this.staffId,
  });

  @override
  State<StaffOrderDetailScreen> createState() => _StaffOrderDetailScreenState();
}

class _StaffOrderDetailScreenState extends State<StaffOrderDetailScreen> {
  final ApiService api = ApiService();
  late Future<List<OrderItem>> _orderItemsFuture;
  late Order _currentOrder;

  static const primaryColor = Color(0xFF5D4037);
  static const secondaryColor = Color(0xFF8D6E63);
  static const backgroundColor = Color(0xFFFFFBF5);
  static const accentColor = Color(0xFFE65100);

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _orderItemsFuture = _fetchOrderItems();
  }

  Future<List<OrderItem>> _fetchOrderItems() async {
    return api.fetchOrderItemsByOrderId(widget.order.id);
  }

  Future<void> _updateItemStatus(OrderItem item, String newStatus) async {
    try {
      await api.updateOrderItemStatus(item.id, newStatus);
      SnackbarUtils.showMessage(
        context,
        'Status item diperbarui menjadi ${_getStatusText(newStatus)}',
      );
      setState(() {
        _orderItemsFuture = _fetchOrderItems();
      });
      await _checkAndUpdateOrderStatus();
      widget.onStatusUpdated();
    } catch (e) {
      SnackbarUtils.showMessage(
        context,
        'Gagal update status item: ${e.toString()}',
      );
    }
  }

  Future<void> _checkAndUpdateOrderStatus() async {
    try {
      final updatedOrder = await api.updateOverallOrderStatus(widget.order.id);
      if (updatedOrder.status != _currentOrder.status) {
        SnackbarUtils.showMessage(
          context,
          'Status pesanan #${_currentOrder.id} kini: ${_getStatusText(updatedOrder.status)}',
        );
        if (mounted) {
          setState(() {
            _currentOrder = updatedOrder;
          });
        }
      }
    } catch (e) {
      debugPrint('❗ Gagal sinkronisasi status order utama: $e');
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Dibayar';
      case 'cooking':
        return 'Sedang Dimasak';
      case 'ready_for_pickup':
        return 'Siap Diambil';
      case 'completed':
        return 'Selesai';
      case 'pending':
        return 'Menunggu Pembayaran';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF2E7D32);
      case 'cooking':
        return const Color(0xFFEF6C00);
      case 'ready_for_pickup':
        return const Color(0xFF1565C0);
      case 'completed':
        return const Color(0xFF00897B);
      case 'pending':
        return const Color(0xFFF57C00);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'cooking':
        return Icons.restaurant;
      case 'ready_for_pickup':
        return Icons.shopping_bag;
      case 'completed':
        return Icons.done_all;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Detail Pesanan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'ID: #${_currentOrder.id}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _orderItemsFuture = _fetchOrderItems();
          });
        },
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(),
              const SizedBox(height: 16),
              _buildCustomerInfoSection(),
              const SizedBox(height: 16),
              _buildOrderDetailsSection(),
              const SizedBox(height: 24),
              _buildSectionHeader('Daftar Produk', Icons.shopping_basket),
              const SizedBox(height: 12),
              FutureBuilder<List<OrderItem>>(
                future: _orderItemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              color: primaryColor,
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Memuat item pesanan...',
                              style: TextStyle(
                                color: primaryColor.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text('Gagal memuat item: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: primaryColor.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            const Text('Tidak ada item ditemukan.'),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _buildOrderItemTile(items[index]),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final statusColor = _getStatusColor(_currentOrder.status);
    final statusIcon = _getStatusIcon(_currentOrder.status);
    final statusText = _getStatusText(_currentOrder.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor,
            statusColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              statusIcon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Pesanan',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3E2723),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfoSection() {
    final customer = _getCustomer(_currentOrder.userId);
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Info Pemesan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E2723),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            if (customer != null) ...[
              _buildInfoRow(
                  Icons.account_circle, 'Nama', customer.namaPengguna),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.phone, 'No. Telepon',
                  customer.nomorTelepon ?? '-'),
            ] else
              const Text('Data pemesan tidak ditemukan.'),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsSection() {
    final formattedDate = _currentOrder.tanggalPesanan != null
        ? DateFormat('dd MMM yyyy, HH:mm')
            .format(DateTime.parse(_currentOrder.tanggalPesanan!))
        : 'Tidak diketahui';
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Rincian Pesanan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E2723),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today, 'Tanggal Pesan', formattedDate),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFF8E1),
                    Color(0xFFFFECB3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6D4C41),
                    ),
                  ),
                  Text(
                    'Rp ${NumberFormat('#,###', 'id_ID').format(_currentOrder.totalHarga)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF6D4C41),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF3E2723),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItemTile(OrderItem item) {
    final product = widget.allProducts.firstWhere(
      (p) => p.id == item.productId,
      orElse: () => Product(
          id: 0, namaProduk: '[Produk Dihapus]', harga: 0, kategoriId: 0),
    );

    final isMyProduct = true;

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            OrderItemTile(item: item, product: product),
            if (isMyProduct && item.status.toLowerCase() != 'completed') ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              _buildItemActionButtons(item),
            ] else if (item.status.toLowerCase() == 'completed') ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              _buildItemActionButtons(item),
            ]
          ],
        ),
      ),
    );
  }

  User? _getCustomer(int userId) {
    try {
      return widget.allUsers.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }

  Widget _buildItemActionButtons(OrderItem item) {
    final status = item.status.toLowerCase();
    switch (status) {
      case 'paid':
        return OrderActionButton(
          newStatus: 'cooking',
          label: 'Mulai Masak',
          icon: Icons.restaurant,
          color: const Color(0xFFEF6C00),
          onPressed: () => _updateItemStatus(item, 'cooking'),
        );
      case 'cooking':
        return OrderActionButton(
          newStatus: 'ready_for_pickup',
          label: 'Siap Diambil',
          icon: Icons.shopping_bag,
          color: const Color(0xFF1565C0),
          onPressed: () => _updateItemStatus(item, 'ready_for_pickup'),
        );
      case 'ready_for_pickup':
        return OrderActionButton(
          newStatus: 'completed',
          label: 'Selesaikan Item',
          icon: Icons.check_circle,
          color: const Color(0xFF00897B),
          onPressed: () => _updateItemStatus(item, 'completed'),
        );
      case 'completed':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 22),
              SizedBox(width: 10),
              Text(
                'Item Selesai',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Status: ${_getStatusText(item.status)}',
            style: const TextStyle(color: Colors.grey),
          ),
        );
    }
  }
}