// file: lib/widgets/staff_product_management_tile.dart

import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import 'product_image_display.dart';

class StaffProductManagementTile extends StatelessWidget {
  final Product product;
  final List<Category> categories;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete; // For inactive products

  const StaffProductManagementTile({
    super.key,
    required this.product,
    required this.categories,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  Widget _buildStatusIndicator(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'AKTIF' : 'NON-AKTIF',
        style: TextStyle(
          color: isActive ? Colors.green.shade800 : Colors.red.shade800,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = categories.firstWhere(
      (c) => c.id == product.kategoriId,
      orElse: () => Category(id: 0, kategori: 'N/A'),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: ProductImageDisplay(
          imageString: product.gambar,
          width: 50,
          height: 50,
          iconSize: 40,
        ),
        title: Text(
          product.namaProduk,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rp ${product.harga} | Kategori: ${category.kategori}'),
            _buildStatusIndicator(product.isActive),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                product.isActive ? Icons.toggle_on : Icons.toggle_off,
                color: product.isActive ? Colors.green : Colors.red,
              ),
              onPressed: onToggleStatus,
              tooltip: product.isActive ? 'Non-aktifkan' : 'Aktifkan',
            ),
            if (product.isActive)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
              ),
            if (!product.isActive)
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.grey),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
