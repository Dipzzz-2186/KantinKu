// file: screens/staff_product_management_view.dart (Versi Diperbarui)

import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import 'dart:convert'; // Diperlukan untuk base64Decode
import 'dart:typed_data';
import '../utils/snackbar_utils.dart';
import '../widgets/product_form.dart'; // Import form yang baru dibuat
import '../widgets/staff_product_management_tile.dart'; // Import tile yang baru dibuat

class StaffProductManagementView extends StatefulWidget {
  final int staffId;

  const StaffProductManagementView({super.key, required this.staffId});

  @override
  _StaffProductManagementViewState createState() =>
      _StaffProductManagementViewState();
}

class _StaffProductManagementViewState
    extends State<StaffProductManagementView> {
  final ApiService api = ApiService();
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // FIX: Tentukan filters yang akan dikirim
      // Jika _showInactive TRUE, kirim filters=null (ambil semua).
      // Jika _showInactive FALSE, kirim filters={"is_active": true} (ambil hanya yang aktif).
      final Map<String, dynamic>? filters = _showInactive
          ? null
          : {"is_active": true};

      // FIX: Panggil API dengan filters
      final products = await api.fetchStaffProducts(
        widget.staffId,
        filters: filters,
      );
      final categories = await api.fetchCategories();

      setState(() {
        _products = products;
        _categories = categories;
      });
    } catch (e) {
      SnackbarUtils.showMessage(context, 'Gagal memuat data: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleProductStatus(Product product) async {
    try {
      final newStatus = !product.isActive;
      final action = newStatus ? 'mengaktifkan' : 'menonaktifkan';

      // Asumsi: saveProductWithFile (atau API PUT Anda) dapat menerima isActive
      await api.saveProductWithFile(
        namaProduk: product.namaProduk,
        harga: product.harga,
        kategoriId: product.kategoriId,
        gambar: null,
        imageBytes: null,
        existingImageUrl: product.gambar,
        staffId: widget.staffId,
        isUpdate: true,
        productId: product.id,
        isActive: newStatus,
      );

      SnackbarUtils.showMessage(
        context,
        'Produk ${product.namaProduk} berhasil $action.',
      );
      _loadData();
    } catch (e) {
      SnackbarUtils.showMessage(
        context,
        'Gagal mengubah status: ${e.toString()}',
      );
    }
  }

  Future<void> _deleteProduct(int productId) async {
    try {
      await api.deleteProduct(productId);
      SnackbarUtils.showMessage(context, 'Produk berhasil dihapus');
      _loadData();
    } catch (e) {
      SnackbarUtils.showMessage(
        context,
        'Gagal menghapus produk: ${e.toString()}',
      );
    }
  }

  void _showProductForm(BuildContext context, {Product? product}) {
    if (_categories.isEmpty) {
      SnackbarUtils.showMessage(context, 'Gagal memuat kategori. Coba lagi.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Agar keyboard tidak menutupi input
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ProductForm(
            productToEdit: product,
            categories: _categories,
            staffId: widget.staffId,
            onSubmitted:
                _loadData, // Callback untuk memuat ulang daftar setelah submit
          ),
        );
      },
    );
  }

  Widget _getLeadingImage(String? imageString) {
    if (imageString == null || imageString.isEmpty) {
      return const Icon(Icons.fastfood, size: 40);
    }

    // Asumsi: Jika string terlalu panjang, itu adalah Base64
    // Atau jika string memiliki prefix Base64
    final isBase64 =
        imageString.length > 100 || imageString.startsWith('data:image');

    if (isBase64) {
      try {
        String cleanBase64 = imageString
            .split(',')
            .last; // Hapus header jika ada
        Uint8List bytes = base64Decode(cleanBase64);

        return Image.memory(
          bytes,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 40),
        );
      } catch (e) {
        // Jika gagal decode, berarti bukan Base64 yang valid
        return const Icon(Icons.error_outline, size: 40, color: Colors.red);
      }
    } else {
      // Jika string pendek, anggap itu adalah URL
      return Image.network(
        imageString,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image_not_supported, size: 40),
      );
    }
  }

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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Penting di dalam TabBarView
        title: Text(_showInactive ? 'Semua Produk' : 'Produk Aktif Saya'),
        actions: [
          // FIX: Toggle Switch untuk Filter Produk Non-aktif
          Row(
            children: [
              Text(
                'Tampilkan Non-Aktif',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              Switch(
                value: _showInactive,
                onChanged: (val) {
                  setState(() {
                    _showInactive = val;
                  });
                  _loadData();
                },
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(context),
        label: const Text('Tambah Produk'),
        icon: const Icon(Icons.add),
      ),
      body: _products.isEmpty
          ? Center(
              child: Text(
                _showInactive
                    ? "Tidak ada produk terdaftar."
                    : "Semua produk sudah non-aktif.",
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return StaffProductManagementTile(
                  product: product,
                  categories: _categories,
                  onEdit: () => _showProductForm(context, product: product),
                  onToggleStatus: () => _toggleProductStatus(product),
                  onDelete: () => SnackbarUtils.showMessage(
                    context,
                    'Hapus permanen hanya setelah penarikan item dari semua cart.',
                  ),
                );
              },
            ),
    );
  }
}
