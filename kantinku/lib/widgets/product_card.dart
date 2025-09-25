import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../utils/image_utils.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    required this.onAddToCart,
  });


@override
  Widget build(BuildContext context) {
    final ImageProvider? productImage = ImageUtils.decodeBase64(product.gambar);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Center(
                child: productImage != null
                    ? Image(
                        image: productImage,
                        fit: BoxFit.contain,
                      )
                    : const Icon(Icons.fastfood, size: 40, color: Colors.grey),
              ),
            ),
          ),
          Expanded( // Tambahkan agar bagian bawah card tidak tenggelam
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    product.namaProduk,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rp ${product.harga.toString()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Spacer(), // Agar tombol selalu di bawah
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: quantity > 0 ? onRemove : null,
                              color: quantity > 0 ? Colors.grey.shade700 : Colors.grey.shade400,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          SizedBox(
                            width: 20,
                            child: Center(
                              child: Text(
                                '$quantity',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: onAdd,
                              color: Colors.green.shade700,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Pesan', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.green.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            elevation: 2,
                          ),
                          onPressed: onAddToCart,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }}