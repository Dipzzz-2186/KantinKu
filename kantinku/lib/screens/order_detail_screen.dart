// file: screens/order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/product_model.dart';
import '../models/payment_model.dart';
import '../models/user_model.dart';
import '../widgets/info_card.dart'; // <-- Import widget baru
import '../widgets/payment_details_card.dart'; // <-- Import widget baru
import '../widgets/order_item_tile.dart'; // <-- Import widget baru

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  final List<Product> allProducts;
  final List<User> allUsers; // <-- Tambahkan ini

  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.allProducts,
    required this.allUsers, // <-- Tambahkan ini
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiService api = ApiService();
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    // Ambil data item dan pembayaran secara bersamaan.
    _dataFuture = Future.wait([
      api.fetchOrderItemsByOrderId(widget.order.id),
      api.fetchPaymentsByOrderId(widget.order.id),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail Pesanan #${widget.order.id}')),
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final List<OrderItem> orderItems =
                snapshot.data![0] as List<OrderItem>;
            final List<Payment> payments = snapshot.data![1] as List<Payment>;
            final Payment? payment = payments.isNotEmpty
                ? payments.first
                : null;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(payment),
                  const SizedBox(height: 20),
                  const Text(
                    'Daftar Produk Dipesan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  ...orderItems.map((item) {
                    final product = widget.allProducts.firstWhere(
                      (p) => p.id == item.productId,
                      orElse: () => Product(
                        id: 0,
                        namaProduk: '[Produk Tidak Dikenal]',
                        harga: 0,
                        kategoriId: 0,
                      ),
                    );
                    return _buildOrderItemTile(item, product);
                  }).toList(),
                ],
              ),
            );
          } else {
            // FIX: Tampilkan pesan jika tidak ada data sama sekali (misal, setelah error)
            return const Center(
              child: Text("Tidak ada detail untuk ditampilkan."),
            );
          }
        },
      ),
    );
  }

  Widget _buildSummaryCard(Payment? payment) {
    final orderStatus = widget.order.status.toLowerCase();
    final statusColor = (orderStatus == 'paid' || orderStatus == 'settlement')
        ? Colors.green
        : Colors.orange;

    final formattedDate = widget.order.tanggalPesanan != null
        ? DateFormat(
            'dd MMM yyyy, HH:mm',
          ).format(DateTime.parse(widget.order.tanggalPesanan!))
        : 'N/A';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoCard(
              title: 'Info Pemesan',
              children: _buildCustomerInfoWidgets(),
            ),
            const SizedBox(height: 15),
            InfoCard(
              title: 'Rincian Pesanan',
              children: [
                Text(
                  'Status Pesanan: ${widget.order.status}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text('Tanggal Pesan: $formattedDate'),
                Text(
                  'Total Bayar: Rp ${widget.order.totalHarga.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Tampilkan detail pembayaran hanya jika ada Payment dan status Paid/Settlement
            if (payment != null &&
                (orderStatus == 'paid' || orderStatus == 'settlement')) ...[
              const SizedBox(height: 15),
              PaymentDetailsCard(payment: payment),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCustomerInfoWidgets() {
    try {
      final user = widget.allUsers.firstWhere(
        (u) => u.id == widget.order.userId,
      );
      return [
        Text('Nama: ${user.namaPengguna}'),
        Text('No. Telepon: ${user.nomorTelepon ?? '-'}'),
      ];
    } catch (e) {
      return [const Text('Data pemesan tidak ditemukan')];
    }
  }

  Widget _buildOrderItemTile(OrderItem item, Product product) {
    return OrderItemTile(item: item, product: product);
  }
}
