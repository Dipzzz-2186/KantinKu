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
  final VoidCallback onDelete;

  const 
  StaffProductManagementTile({
    super.key,
    required this.product,
    required this.categories,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final category = categories.firstWhere(
      (c) => c.id == product.kategoriId,
      orElse: () => Category(id: 0, kategori: 'Tidak diketahui'),
    );

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: product.isActive ? Colors.white : Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // Gambar produk
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ProductImageDisplay(
                imageString: product.gambar,
                width: 70,
                height: 70,
                iconSize: 50,
              ),
            ),
            const SizedBox(width: 14),

            // Informasi produk
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.namaProduk,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          product.isActive ? Colors.black87 : Colors.redAccent,
                      decoration: product.isActive
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                  ),
                  if (product.deskripsi != null &&
                      product.deskripsi!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        product.deskripsi!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${product.harga}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kategori: ${category.kategori}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildStatusBadge(product.isActive),
                ],
              ),
            ),

            // Tombol aksi
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    product.isActive ? Icons.toggle_on : Icons.toggle_off,
                    color: product.isActive ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  onPressed: onToggleStatus,
                  tooltip: product.isActive ? 'Nonaktifkan Produk' : 'Aktifkan Produk',
                ),
                const SizedBox(width: 6),
                if (product.isActive)
                  _buildActionButton(
                    icon: Icons.edit,
                    color: Colors.blue,
                    tooltip: 'Edit Produk',
                    onTap: onEdit,
                  ),
                if (!product.isActive)
                  _buildActionButton(
                    icon: Icons.delete_forever,
                    color: Colors.grey,
                    tooltip: 'Hapus Produk',
                    onTap: onDelete,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'AKTIF' : 'NON-AKTIF',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.green.shade800 : Colors.red.shade800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
