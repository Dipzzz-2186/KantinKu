// file: lib/widgets/cart_item_tile.dart

import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final Product product;
  final bool isActive;
  final ValueChanged<int> onQuantityChanged;

  const CartItemTile({
    super.key,
    required this.item,
    required this.product,
    required this.isActive,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: isActive ? null : Colors.grey.shade200,
      title: Text(
        product.namaProduk,
        style: TextStyle(
          decoration: isActive ? null : TextDecoration.lineThrough,
          color: isActive ? Colors.black : Colors.red,
        ),
      ),
      subtitle: Text('Rp ${product.harga}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive) ...[
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                if (item.jumlah > 0) {
                  onQuantityChanged(item.jumlah - 1);
                }
              },
            ),
            SizedBox(
              width: 20,
              child: Center(
                child: Text(
                  '${item.jumlah}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => onQuantityChanged(item.jumlah + 1),
            ),
          ] else ...[
            const Text('Tidak Aktif', style: TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}
