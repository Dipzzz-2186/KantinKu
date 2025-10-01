// file: lib/widgets/order_item_tile.dart

import 'package:flutter/material.dart';
import '../models/order_item_model.dart';
import '../models/product_model.dart';

class OrderItemTile extends StatelessWidget {
  final OrderItem item;
  final Product product;

  const OrderItemTile({super.key, required this.item, required this.product});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: product.gambar != null && product.gambar!.isNotEmpty
          ? Image.network(
              product.gambar!,
              width: 50,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => const Icon(Icons.fastfood, size: 40),
            )
          : const Icon(Icons.fastfood, size: 40),
      title: Text(product.namaProduk),
      subtitle: Text('Rp ${item.hargaUnit.toStringAsFixed(0)}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'x${item.jumlah}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Subtotal: Rp ${item.subtotal.toStringAsFixed(0)}'),
        ],
      ),
    );
  }
}
