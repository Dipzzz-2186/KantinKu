// file: widgets/order_card.dart (Versi diperbarui)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../utils/snackbar_utils.dart';
import '../screens/order_detail_screen.dart';
import '../models/product_model.dart'; // Diperlukan untuk navigasi

class OrderCard extends StatelessWidget {
  final Order order;
  final List<Product> allProducts;
  final VoidCallback? onReorder;
  final VoidCallback? onTap; // <-- Tambahkan callback ini

  const OrderCard({
    super.key,
    required this.order,
    this.onReorder,
    required this.allProducts,
    this.onTap, // <-- Perlu ditambahkan di konstruktor
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'settlement':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
      case 'failure':
        return Colors.red;
      case 'processed':
        return Colors.blue;
      case 'cooking':
        return Colors.orange.shade700;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'settlement':
        return 'Selesai Dibayar';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'cancelled':
      case 'failure':
        return 'Dibatalkan/Gagal';
      case 'cooking':
        return 'Sedang Dimasak';
      case 'ready_for_pickup':
        return 'Siap Diambil';
      case 'completed':
        return 'Selesai / Telah Diambil';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Tanggal tidak tersedia';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pesanan #${order.id}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Total: Rp ${order.totalHarga.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _getStatusText(order.status),
            style: TextStyle(
              color: _getStatusColor(order.status),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isFinal =
        order.status.toLowerCase() == 'paid' ||
        order.status.toLowerCase() == 'settlement' ||
        order.status.toLowerCase() == 'cancelled' ||
        order.status.toLowerCase() == 'failure';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Tombol Pesan Lagi
        if (isFinal && onReorder != null)
          ElevatedButton.icon(
            onPressed: onReorder,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Pesan Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          )
        else
          const SizedBox(), // Spacer agar tombol detail tetap di kanan
        // Tombol Lihat Detail
        TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.receipt_long, size: 18),
          label: const Text('Lihat Detail'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayDate = _formatDate(order.tanggalPesanan);
    final isFinal =
        order.status.toLowerCase() == 'paid' ||
        order.status.toLowerCase() == 'settlement' ||
        order.status.toLowerCase() == 'cancelled' ||
        order.status.toLowerCase() == 'failure';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap, // <-- Panggil callback onTap
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Divider(height: 20, color: Colors.grey),
              // Detail Waktu
              Text(
                'Waktu Pesan: ${_formatDate(order.tanggalPesanan)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              _buildActionButtons(context), // <-- Panggil action buttons
            ],
          ),
        ),
      ),
    );
  }
}
