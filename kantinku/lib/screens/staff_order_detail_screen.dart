// file: screens/staff_order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:kantinku/models/user_model.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../utils/snackbar_utils.dart';
import '../models/order_item_model.dart';
import '../widgets/info_card.dart'; // <-- Import widget baru
import '../widgets/order_action_button.dart'; // <-- Import widget baru
import '../widgets/order_item_tile.dart'; // <-- Import widget baru

class StaffOrderDetailScreen extends StatefulWidget {
  final Order order;
  final List<Product> allProducts;
  final List<User> allUsers;
  final VoidCallback onStatusUpdated;

  const StaffOrderDetailScreen({
    super.key,
    required this.order,
    required this.allProducts,
    required this.onStatusUpdated,
    required this.allUsers,
  });

  @override
  State<StaffOrderDetailScreen> createState() => _StaffOrderDetailScreenState();
}

class _StaffOrderDetailScreenState extends State<StaffOrderDetailScreen> {
  final ApiService api = ApiService();
  bool _isUpdating = false;
  late Future<List<OrderItem>> _orderItemsFuture;

  @override
  void initState() {
    super.initState();
    // Panggil API untuk mengambil item pesanan berdasarkan ID order
    _orderItemsFuture = api.fetchOrderItemsByOrderId(widget.order.id);
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await api.updateOrderStatus(widget.order.id, newStatus);
      SnackbarUtils.showMessage(
        context,
        'Status pesanan #${widget.order.id} diperbarui!',
      );
      widget.onStatusUpdated(); // Panggil callback untuk refresh inbox
      Navigator.pop(context); // Kembali ke layar inbox
    } catch (e) {
      SnackbarUtils.showMessage(context, 'Gagal: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail Pesanan #${widget.order.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 20),
            const Text(
              'Daftar Produk Dipesan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            FutureBuilder<List<OrderItem>>(
              future: _orderItemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Gagal memuat item: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Tidak ada item ditemukan.'));
                }

                final items = snapshot.data!;
                // Gunakan data item yang baru diambil untuk membangun UI
                return Column(
                  children: items.map((item) {
                    return _buildOrderItemTile(item);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isUpdating
            ? const Center(child: CircularProgressIndicator())
            : _buildActionButtons(),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final customer = _getCustomer(widget.order.userId);
    final formattedDate = widget.order.tanggalPesanan != null
        ? DateFormat(
            'dd MMM yyyy, HH:mm',
          ).format(DateTime.parse(widget.order.tanggalPesanan!))
        : 'N/A';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoCard(
              title: 'Info Pemesan',
              children: customer != null
                  ? [
                      Text('Nama: ${customer.namaPengguna}'),
                      Text('No. Telepon: ${customer.nomorTelepon ?? '-'}'),
                    ]
                  : [const Text('Data pemesan tidak ditemukan.')],
            ),
            const SizedBox(height: 15),
            InfoCard(
              title: 'Rincian Pesanan',
              children: [
                Text('Tanggal Pesan: $formattedDate'),
                Text('Status: ${widget.order.status.toUpperCase()}'),
                Text(
                  'Total: Rp ${widget.order.totalHarga.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemTile(OrderItem item) {
    final product = widget.allProducts.firstWhere(
      (p) => p.id == item.productId,
      orElse: () => Product(
        id: 0,
        namaProduk: '[Produk Tidak Dikenal]',
        harga: 0,
        kategoriId: 0,
      ),
    );
    return OrderItemTile(item: item, product: product);
  }

  User? _getCustomer(int userId) {
    try {
      return widget.allUsers.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }

  Widget _buildActionButtons() {
    final status = widget.order.status.toLowerCase();

    // Alur: paid -> cooking -> ready_for_pickup -> completed
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == 'paid')
          OrderActionButton(
            newStatus: 'cooking',
            label: 'Mulai Masak',
            icon: Icons.soup_kitchen,
            color: Colors.orange,
            onPressed: () => _updateStatus('cooking'),
          )
        else if (status == 'cooking')
          OrderActionButton(
            newStatus: 'ready_for_pickup',
            label: 'Siap Diambil',
            icon: Icons.check_circle,
            color: Colors.blue,
            onPressed: () => _updateStatus('ready_for_pickup'),
          )
        else if (status == 'ready_for_pickup')
          OrderActionButton(
            newStatus: 'completed',
            label: 'Selesaikan Pesanan',
            icon: Icons.done_all,
            color: Colors.green,
            onPressed: () => _updateStatus('completed'),
          ),
        if (widget.order.status.toLowerCase() != 'completed')
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton.icon(
              onPressed: () =>
                  _updateStatus('cancelled'), // Panggil fungsi update status
              icon: const Icon(Icons.cancel, color: Colors.red),
              label: const Text(
                'Batalkan Pesanan',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
      ],
    );
  }
}
