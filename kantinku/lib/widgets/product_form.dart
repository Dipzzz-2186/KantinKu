// file: widgets/product_form.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../utils/snackbar_utils.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'dart:typed_data';
import 'dart:async';
import 'package:intl/intl.dart';

// Conditional imports
import 'dart:io'
    if (dart.library.html) 'package:kantinku/utils/stub_io.dart'
    as io;

import 'dart:html'
    if (dart.library.io) 'package:kantinku/utils/stub_html.dart'
    as html;

class ProductForm extends StatefulWidget {
  final Product? productToEdit;
  final List<Category> categories;
  final int staffId;
  final VoidCallback onSubmitted;

  const ProductForm({
    super.key,
    this.productToEdit,
    required this.categories,
    required this.staffId,
    required this.onSubmitted,
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService api = ApiService();
  final ImagePicker _picker = ImagePicker();
  
  final _namaProdukController = TextEditingController();
  final _hargaController = TextEditingController();
  final _deskripsiController = TextEditingController();

  Uint8List? _imageBytes;
  String? _currentImageUrl;
  bool _isActive = true;
  bool _isSubmitting = false;

  late String _namaProduk;
  late int _harga;
  late String? _deskripsi;
  late int? _kategoriId;
  XFile? _selectedImage;

  static const primaryColor = Color(0xFF5D4037);
  static const secondaryColor = Color(0xFF8D6E63);
  static const backgroundColor = Color(0xFFFFFBF5);
  static const accentColor = Color(0xFFE65100);

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _namaProduk = p?.namaProduk ?? '';
    _harga = p?.harga ?? 0;
    _deskripsi = p?.deskripsi;
    _kategoriId = p?.kategoriId;
    _currentImageUrl = p?.gambar;
    _isActive = p?.isActive ?? true;
    
    _namaProdukController.text = _namaProduk;
    _hargaController.text = _harga == 0 ? '' : _harga.toString();
    _deskripsiController.text = _deskripsi ?? '';
  }

  @override
  void dispose() {
    _namaProdukController.dispose();
    _hargaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      await uploadInput.onChange.first;
      if (uploadInput.files!.isNotEmpty) {
        final file = uploadInput.files![0];
        final reader = html.FileReader();

        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;

        _imageBytes = reader.result as Uint8List;
        setState(() {
          _selectedImage = XFile(file.name);
        });
      }
    } else {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    }
  }

  Future<String?> _convertImageToBase64(XFile? file) async {
    if (file == null) return null;

    Uint8List? bytes;
    if (kIsWeb && _imageBytes != null) {
      bytes = _imageBytes;
    } else if (!kIsWeb && file.path.isNotEmpty) {
      bytes = await io.File(file.path).readAsBytes();
    }

    if (bytes != null) return base64Encode(bytes);
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_kategoriId == null) {
      SnackbarUtils.showMessage(context, 'Kategori harus dipilih.');
      return;
    }

    setState(() => _isSubmitting = true);

    final imageBase64String = await _convertImageToBase64(_selectedImage);
    final newProduct = Product(
      id: widget.productToEdit?.id ?? 0,
      namaProduk: _namaProduk,
      harga: _harga,
      kategoriId: _kategoriId!,
      gambar: imageBase64String ?? _currentImageUrl,
      isActive: _isActive,
      deskripsi: _deskripsi, // ✅ Tambahkan deskripsi
    );

    try {
      await api.saveProductWithFile(
        namaProduk: newProduct.namaProduk,
        harga: newProduct.harga,
        kategoriId: newProduct.kategoriId,
        gambar: _selectedImage,
        imageBytes: _imageBytes,
        existingImageUrl: _currentImageUrl,
        staffId: widget.staffId,
        isUpdate:
            widget.productToEdit?.id != null && widget.productToEdit!.id != 0,
        productId: newProduct.id,
        isActive: _isActive,
        deskripsi: _deskripsi, // ✅ Pass deskripsi ke API
      );

      final action = widget.productToEdit == null ? 'ditambahkan' : 'diperbarui';
      SnackbarUtils.showMessage(context, 'Produk berhasil $action!');
      widget.onSubmitted();
      Navigator.of(context).pop();
    } catch (e) {
      SnackbarUtils.showMessage(context, 'Gagal menyimpan produk: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildImagePicker() {
    final hasImage =
        _selectedImage != null ||
        (_currentImageUrl != null && _currentImageUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.image_rounded,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Gambar Produk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E2723),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasImage ? accentColor.withOpacity(0.3) : Colors.grey.shade300,
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: hasImage
                        ? accentColor.withOpacity(0.1)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasImage ? Icons.check_circle : Icons.upload_file_rounded,
                    color: hasImage ? accentColor : Colors.grey.shade600,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedImage != null
                      ? _selectedImage!.name
                      : hasImage
                          ? "Gambar sudah ada"
                          : "Ketuk untuk memilih gambar",
                  style: TextStyle(
                    color: hasImage ? primaryColor : Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: hasImage ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!hasImage)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '(Opsional)',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (hasImage)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _imageBytes = null;
                    _currentImageUrl = null;
                  });
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                label: const Text(
                  'Hapus Gambar',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;

    return Container(
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor,
                  secondaryColor,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_rounded : Icons.add_circle_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Produk' : 'Tambah Produk Baru',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEditing
                            ? 'Perbarui informasi produk'
                            : 'Lengkapi data produk baru',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Form Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nama Produk
                    TextFormField(
                      controller: _namaProdukController,
                      decoration: InputDecoration(
                        labelText: 'Nama Produk',
                        hintText: 'Contoh: Nasi Goreng Spesial',
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.fastfood_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Nama produk wajib diisi' : null,
                      onSaved: (val) => _namaProduk = val!,
                    ),
                    const SizedBox(height: 18),

                    // Deskripsi Produk (BARU)
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 3,
                      maxLength: 150,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi Produk (Opsional)',
                        hintText: 'Contoh: Nasi goreng dengan bumbu spesial, telur, dan sayuran',
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9C27B0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.description_rounded,
                            color: Color(0xFF9C27B0),
                            size: 20,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        helperText: 'Maksimal 150 karakter',
                        helperStyle: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      onSaved: (val) => _deskripsi = val?.trim().isEmpty == true ? null : val?.trim(),
                    ),
                    const SizedBox(height: 18),

                    // Harga Produk
                    TextFormField(
                      controller: _hargaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Harga Produk',
                        hintText: '15000',
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.payments_rounded,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) {
                        final n = int.tryParse(val ?? '');
                        if (n == null || n <= 0) return 'Harga harus angka positif';
                        return null;
                      },
                      onSaved: (val) => _harga = int.parse(val!),
                    ),
                    const SizedBox(height: 18),

                    // Dropdown Kategori
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF66BB6A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.category_rounded,
                            color: Color(0xFF66BB6A),
                            size: 20,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      value: _kategoriId,
                      items: widget.categories
                          .map((cat) => DropdownMenuItem(
                                value: cat.id,
                                child: Text(cat.kategori),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _kategoriId = val),
                      validator: (val) => val == null ? 'Pilih kategori' : null,
                    ),
                    const SizedBox(height: 24),

                    // Upload Gambar
                    _buildImagePicker(),
                    const SizedBox(height: 24),

                    // Status Aktif (hanya saat edit)
                    if (isEditing)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _isActive
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _isActive ? Icons.check_circle : Icons.cancel,
                                color: _isActive ? Colors.green : Colors.grey,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Status Produk',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3E2723),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isActive
                                        ? 'Produk aktif dan dapat dipesan'
                                        : 'Produk tidak aktif',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _isActive,
                              activeColor: Colors.green,
                              onChanged: (v) => setState(() => _isActive = v),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isEditing ? Icons.save_rounded : Icons.add_circle_rounded,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isEditing ? 'SIMPAN PERUBAHAN' : 'TAMBAH PRODUK',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}