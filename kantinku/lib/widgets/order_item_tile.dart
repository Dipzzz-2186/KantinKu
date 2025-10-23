// file: lib/widgets/order_item_tile.dart
import 'package:flutter/material.dart';
import '../models/order_item_model.dart';
import '../models/product_model.dart';

/// Widget untuk menampilkan satu item pesanan dalam daftar.
/// Menampilkan gambar produk, nama, harga satuan, jumlah, dan subtotal.
class OrderItemTile extends StatelessWidget {
  final OrderItem item;
  final Product product;

  const OrderItemTile({
    super.key,
    required this.item,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Asumsi: product.gambar adalah URL lengkap (mis. https://xxxx.ngrok-free.app/files/produk.jpg)
    final imageUrl = product.gambar?.trim() ?? '';

    // ✅ Header wajib untuk akses file dari server ngrok agar lolos browser warning
    const ngrokHeaders = {
      "ngrok-skip-browser-warning": "true",
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ✅ Gambar produk
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    headers: ngrokHeaders,
                    errorBuilder: (context, error, stackTrace) =>
                        const _PlaceholderImage(),
                  )
                : const _PlaceholderImage(),
          ),

          const SizedBox(width: 12),

          // ✅ Info produk
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.namaProduk,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp ${item.hargaUnit.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'x${item.jumlah}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ✅ Subtotal
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              Text(
                'Rp ${item.subtotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget placeholder icon jika gambar gagal dimuat
class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.fastfood,
        color: Colors.grey,
        size: 32,
      ),
    );
  }
}
