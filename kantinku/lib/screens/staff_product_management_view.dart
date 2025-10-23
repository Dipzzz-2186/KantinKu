import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/product_form.dart';
import '../widgets/staff_product_management_tile.dart';

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
      final Map<String, dynamic>? filters = _showInactive
          ? null
          : {"is_active": true};

      final products = await api.fetchStaffProducts(
        widget.staffId,
        filters: filters,
      );
      final categories = await api.fetchCategories();

      if (mounted) {
        setState(() {
          _products = products;
          _categories = categories;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showMessage(context, 'Gagal memuat data: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleProductStatus(Product product) async {
    try {
      final newStatus = !product.isActive;
      final action = newStatus ? 'mengaktifkan' : 'menonaktifkan';

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

  // --- PERUBAHAN 1: Perbarui _deleteProduct untuk menangani error dari backend ---
  Future<void> _deleteProduct(int productId) async {
    try {
      await api.deleteProduct(productId);
      SnackbarUtils.showMessage(context, 'Produk berhasil dihapus');
      _loadData();
    } catch (e) {
      // Ini akan menampilkan pesan error spesifik dari backend
      // seperti "Produk tidak dapat dihapus karena masih ada di keranjang pengguna."
      SnackbarUtils.showMessage(
        context,
        'Gagal menghapus: ${e.toString()}',
      );
    }
  }

  // --- PERUBAHAN 2: Tambahkan dialog konfirmasi untuk UX yang lebih baik ---
  void _showDeleteConfirmationDialog(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Produk?'),
          content: Text(
              'Apakah Anda yakin ingin menghapus "${product.namaProduk}" secara permanen? Tindakan ini tidak dapat dibatalkan.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct(product.id);
              },
            ),
          ],
        );
      },
    );
  }

  void _showProductForm(BuildContext context, {Product? product}) {
    if (_categories.isEmpty) {
      SnackbarUtils.showMessage(context, 'Gagal memuat kategori. Coba lagi.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ProductForm(
              productToEdit: product,
              categories: _categories,
              staffId: widget.staffId,
              onSubmitted: _loadData,
            ),
          ),
        );
      },
    );
  }

  // ... Sisa kode dari _buildStatusIndicator hingga akhir build() tidak berubah ...
  // ... (Saya sertakan lagi di bawah agar lengkap)

  Widget _buildStatusIndicator(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'AKTIF' : 'NON-AKTIF',
            style: TextStyle(
              color: isActive ? Colors.green.shade700 : Colors.red.shade700,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.brown[700],
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Memuat produk...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final activeCount = _products.where((p) => p.isActive).length;
    final inactiveCount = _products.length - activeCount;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Stats Header Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.brown[700]!,
                  Colors.brown[600]!,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Manajemen Produk',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_products.length} Total',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Aktif',
                        activeCount,
                        Icons.check_circle_rounded,
                        Colors.greenAccent[400]!,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatItem(
                        'Non-Aktif',
                        inactiveCount,
                        Icons.cancel_rounded,
                        Colors.redAccent[200]!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Toggle Filter Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  _showInactive
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: Colors.brown[700],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tampilkan Produk Non-Aktif',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Switch(
                  value: _showInactive,
                  activeColor: Colors.brown[700],
                  onChanged: (val) {
                    setState(() {
                      _showInactive = val;
                    });
                    _loadData();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Product List
          Expanded(
            child: _products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _showInactive
                              ? "Tidak ada produk terdaftar"
                              : "Semua produk non-aktif",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _showInactive
                              ? "Mulai tambahkan produk baru"
                              : "Aktifkan produk untuk ditampilkan",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return StaffProductManagementTile(
                        product: product,
                        categories: _categories,
                        onEdit: () =>
                            _showProductForm(context, product: product),
                        onToggleStatus: () => _toggleProductStatus(product),
                        // --- PERUBAHAN 3: Hubungkan tombol hapus ke dialog konfirmasi ---
                        onDelete: () => _showDeleteConfirmationDialog(product),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(context),
        backgroundColor: Colors.brown[700],
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 24, color: Colors.white),
        label: const Text(
          'Tambah Produk',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}