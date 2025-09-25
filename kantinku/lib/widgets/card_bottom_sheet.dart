import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../utils/image_utils.dart';

class CartBottomSheet extends StatelessWidget {
  final List<CartItem> items;
  final List<Product> products;

  const CartBottomSheet({
    super.key,
    required this.items,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return items.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: Text('Keranjang kosong')),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: items.map((item) {
              final product = products.firstWhere(
                (p) => p.id == item.productId,
                orElse: () =>
                    Product(id: 0, namaProduk: 'Unknown', harga: 0, kategoriId: 0),
              );
              final productImage = ImageUtils.decodeBase64(product.gambar);

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: productImage,
                  child: productImage == null
                      ? const Icon(Icons.fastfood)
                      : null,
                ),
                title: Text(product.namaProduk),
                subtitle: Text('Jumlah: ${item.jumlah}'),
                trailing: Text('Rp${product.harga * item.jumlah}'),
              );
            }).toList(),
          );
  }
}
