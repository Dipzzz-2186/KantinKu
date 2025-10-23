// file: widgets/order_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../utils/snackbar_utils.dart';
import '../screens/order_detail_screen.dart';
import '../models/product_model.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final List<Product> allProducts;
  final VoidCallback? onReorder;
  final VoidCallback? onContinuePayment;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.onReorder,
    this.onContinuePayment,
    required this.allProducts,
    this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'settlement':
      case 'completed':
        return const Color(0xFF2E7D32); // Dark green
      case 'pending':
        return const Color(0xFFEF6C00); // Dark orange
      case 'cancelled':
      case 'failure':
        return const Color(0xFFC62828); // Dark red
      case 'processed':
        return const Color(0xFF1565C0); // Dark blue
      case 'cooking':
        return const Color(0xFFE65100); // Deep orange
      case 'ready_for_pickup':
        return const Color(0xFF6A1B9A); // Purple
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'settlement':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
      case 'failure':
        return Icons.cancel;
      case 'cooking':
        return Icons.restaurant;
      case 'ready_for_pickup':
        return Icons.shopping_bag;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'settlement':
        return 'Dibayar';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'cancelled':
      case 'failure':
        return 'Dibatalkan';
      case 'cooking':
        return 'Sedang Dimasak';
      case 'ready_for_pickup':
        return 'Siap Diambil';
      case 'completed':
        return 'Selesai';
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

  String _getRelativeTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final dateTime = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Baru saja';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} menit yang lalu';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari yang lalu';
      } else {
        return DateFormat('dd MMM yyyy').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Status Icon dengan gradient background
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getStatusColor(order.status),
                _getStatusColor(order.status).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _getStatusColor(order.status).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            _getStatusIcon(order.status),
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        // Order Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Pesanan #${order.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(order.status).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(order.status),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getRelativeTime(order.tanggalPesanan),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF8E1),
            Color(0xFFFFECB3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD54F).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_long,
                size: 20,
                color: Color(0xFFE65100),
              ),
              SizedBox(width: 8),
              Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6D4C41),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            'Rp ${NumberFormat('#,###', 'id_ID').format(order.totalHarga)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isFinal = order.status.toLowerCase() == 'paid' ||
        order.status.toLowerCase() == 'settlement' ||
        order.status.toLowerCase() == 'cancelled' ||
        order.status.toLowerCase() == 'failure' ||
        order.status.toLowerCase() == 'completed';
    final isPending = order.status.toLowerCase() == 'pending';

    return Row(
      children: [
        // Tombol Pesan Lagi
        if (isFinal && onReorder != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onReorder,
              icon: const Icon(Icons.replay, size: 20),
              label: const Text('Pesan Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                elevation: 0,
              ),
            ),
          ),
        // Tombol Lanjutkan Pembayaran
        if (isPending && onContinuePayment != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onContinuePayment,
              icon: const Icon(Icons.payment, size: 20),
              label: const Text('Bayar Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF6C00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                elevation: 0,
              ),
            ),
          ),
        if ((isFinal && onReorder != null) ||
            (isPending && onContinuePayment != null))
          const SizedBox(width: 10),
        // Tombol Lihat Detail
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Detail'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5D4037),
              side: const BorderSide(
                color: Color(0xFF5D4037),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D4037).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildPriceSection(),
                const SizedBox(height: 16),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}