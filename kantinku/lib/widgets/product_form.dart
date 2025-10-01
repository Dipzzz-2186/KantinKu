// file: widgets/product_form.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import '../utils/snackbar_utils.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'dart:async';
import 'dart:typed_data';

// =======================================================
// PERBAIKAN CONDITIONAL IMPORTS: SATU ALIAS PER PLATFORM
// =======================================================

// Alias 'io' untuk File (di mobile/desktop)
import 'dart:io'
    if (dart.library.html) 'package:kantinku/utils/stub_io.dart'
    as io;

// Alias 'html' untuk FileUploadInputElement (di web)
import 'dart:html'
    if (dart.library.io) 'package:kantinku/utils/stub_html.dart'
    as html;

import 'package:kantinku/widgets/product_image_display.dart';
import '../utils/image_picker_utils.dart'; // <-- Tambahkan import ini

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

  Uint8List? _imageBytes; // Menyimpan bytes gambar untuk preview di Web
  String? _currentImageUrl; // Menambahkan ini untuk melacak URL gambar jika ada
  bool _isActive = true;

  late String _namaProduk;
  late int _harga;
  late int? _kategoriId;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _namaProduk = p?.namaProduk ?? '';
    _harga = p?.harga ?? 0;
    _kategoriId = p?.kategoriId;
    _currentImageUrl = p?.gambar;
    _isActive = p?.isActive ?? true;
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Menggunakan alias 'html'
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      await uploadInput.onChange.first;

      if (uploadInput.files!.isNotEmpty) {
        final file = uploadInput.files![0];
        // Menggunakan alias 'html'
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
      // Menggunakan alias 'io'
      bytes = await io.File(file.path).readAsBytes();
    }

    if (bytes != null) {
      return base64Encode(bytes);
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_kategoriId == null) {
      SnackbarUtils.showMessage(context, 'Kategori harus dipilih.');
      return;
    }

    final imageBase64String = await _convertImageToBase64(_selectedImage);

    final newProduct = Product(
      id: widget.productToEdit?.id ?? 0,
      namaProduk: _namaProduk,
      harga: _harga,
      kategoriId: _kategoriId!,
      gambar: imageBase64String ?? _currentImageUrl,
      isActive: _isActive,
    );

    try {
      await api.saveProductWithFile(
        namaProduk: newProduct.namaProduk,
        harga: newProduct.harga,
        kategoriId: newProduct.kategoriId,
        gambar: _selectedImage, // XFile
        imageBytes: _imageBytes, // Bytes for web
        existingImageUrl: _currentImageUrl,
        staffId: widget.staffId,
        isUpdate:
            widget.productToEdit?.id != null && widget.productToEdit!.id != 0,
        productId: newProduct.id,
        isActive: _isActive,
      );

      final action = widget.productToEdit == null
          ? 'ditambahkan'
          : 'diperbarui';
      SnackbarUtils.showMessage(context, 'Produk berhasil $action!');

      widget.onSubmitted();
      Navigator.of(context).pop();
    } catch (e) {
      SnackbarUtils.showMessage(
        context,
        'Gagal menyimpan produk: ${e.toString()}',
      );
    }
  }

  Widget _buildImagePreview() {
    // Jika ada gambar baru yang dipilih
    if (_selectedImage != null) {
      return buildImagePreviewWidget(_selectedImage!.path);
    }
    // Jika tidak ada gambar baru, tampilkan gambar yang sudah ada (dari URL)
    return ProductImageDisplay(
      imageString: _currentImageUrl,
      width: 100,
      height: 100,
      iconSize: 80,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom:
              MediaQuery.of(context).viewInsets.bottom +
              16.0, // Agar keyboard tidak menutupi
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.productToEdit == null
                    ? 'Tambah Produk Baru'
                    : 'Edit Produk',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              TextFormField(
                initialValue: _namaProduk,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
                validator: (val) =>
                    val!.isEmpty ? 'Nama produk wajib diisi' : null,
                onSaved: (val) => _namaProduk = val!,
              ),
              const SizedBox(height: 10),

              TextFormField(
                initialValue: _harga == 0 ? '' : _harga.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga (Rp)'),
                validator: (val) =>
                    (val == null ||
                        int.tryParse(val) == null ||
                        int.parse(val) <= 0)
                    ? 'Harga harus angka positif'
                    : null,
                onSaved: (val) => _harga = int.parse(val!),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Kategori'),
                value: _kategoriId,
                items: widget.categories
                    .map(
                      (cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.kategori),
                      ),
                    )
                    .toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _kategoriId = newValue;
                  });
                },
                validator: (val) => val == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 20),

              _buildImagePicker(context),
              const SizedBox(height: 30),

              if (widget.productToEdit != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status Aktif:', style: TextStyle(fontSize: 16)),
                    Switch(
                      value: _isActive,
                      onChanged: (bool value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.productToEdit == null
                      ? 'TAMBAH PRODUK'
                      : 'SIMPAN PERUBAHAN',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    // Cek apakah ada gambar yang sedang dipilih atau sudah ada dari server
    final hasImage =
        _selectedImage != null ||
        (_currentImageUrl != null && _currentImageUrl!.isNotEmpty);

    Widget imagePreviewWidget = _buildImagePreview(); // Gunakan fungsi preview

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gambar Produk:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imagePreviewWidget, // Tampilkan widget preview
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: Text(hasImage ? 'Ganti Gambar' : 'Pilih Gambar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        if (hasImage)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedImage = null; // Hapus gambar yang baru dipilih
                _imageBytes = null; // Hapus bytes untuk web
                _currentImageUrl = null; // Hapus gambar dari server
              });
            },
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            label: const Text(
              'Hapus Gambar',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}
