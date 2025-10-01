// file: widgets/card_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:kantinku/models/cart_item_model.dart';
import 'package:kantinku/models/product_model.dart';
import 'package:kantinku/services/api_service.dart';
import 'package:kantinku/utils/snackbar_utils.dart';
import 'package:kantinku/screens/payment_screen.dart';
import 'package:kantinku/widgets/cart_item_tile.dart'; // Import widget baru
import 'dart:async';

typedef OnCartSync = void Function(List<CartItem> updatedItems);

class CartBottomSheet extends StatefulWidget {
  final List<CartItem> items;
  final List<Product> products;
  final OnCartSync onSyncRequested;

  const CartBottomSheet({
    Key? key,
    required this.items,
    required this.products,
    required this.onSyncRequested,
  }) : super(key: key);

  @override
  _CartBottomSheetState createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet> {
  final ApiService api = ApiService();
  List<CartItem> _currentItems = [];
  bool _hasInactiveItems = false;

  @override
  void initState() {
    super.initState();
    _currentItems = List.from(widget.items);
  }

  @override
  void didUpdateWidget(covariant CartBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _currentItems = List.from(widget.items);
      _checkInactiveStatus();
    }
  }

  // FIX: Hapus _debounce jika widget dihancurkan
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  double get totalPrice {
    double total = 0.0;
    for (var item in _currentItems) {
      final product = widget.products.firstWhere(
        (p) => p.id == item.productId,
        orElse: () => Product(id: 0, namaProduk: '', harga: 0, kategoriId: 0),
      );
      // FIX: Abaikan harga item yang tidak ditemukan (ID 0)
      if (product.id != 0) {
        total += product.harga * item.jumlah;
      }
    }
    return total;
  }

  Timer? _debounce;

  // FIX: Implementasi debounce untuk API call agar UI tidak lag
  void _updateLocalQuantity(CartItem item, int newQuantity) {
    final oldQuantity = item.jumlah;

    // 1. Update UI secara instan
    setState(() {
      final index = _currentItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        if (newQuantity <= 0) {
          _currentItems.removeAt(index);
        } else {
          _currentItems[index] = CartItem(
            id: item.id,
            userId: item.userId,
            productId: item.productId,
            jumlah: newQuantity,
          );
        }
      }
    });

    // 2. Batalkan request sebelumnya (debounce)
    _debounce?.cancel();

    // 3. Tunda request API
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        if (newQuantity <= 0) {
          await api.deleteCartItem(item.id!);
        } else {
          await api.updateCartItem(item.id!, item.productId, newQuantity);
        }
        widget.onSyncRequested([]); // Panggil sync penuh
      } catch (e) {
        // Rollback state lokal jika gagal
        // Note: Rollback logic is complex, usually just refetching is better.
        // For simplicity, we just notify the failure.
        SnackbarUtils.showMessage(
          context,
          'Gagal update keranjang: ${e.toString()}',
        );
        widget.onSyncRequested(
          [],
        ); // Panggil sync penuh untuk mendapatkan data server yang benar
      }
    });
  }

  void _checkInactiveStatus() {
    // Memeriksa apakah ada item di keranjang yang produknya tidak ditemukan
    final activeProductIds = widget.products.map((p) => p.id).toSet();
    final hasInvalidItem = _currentItems.any(
      (item) => !activeProductIds.contains(item.productId),
    );

    // Asumsi: Jika produk tidak ditemukan di daftar aktif ProductScreen,
    // berarti is_active-nya false (sudah di soft delete).
    setState(() {
      _hasInactiveItems = hasInvalidItem;
    });
  }

  Future<void> _checkout() async {
    if (_currentItems.isEmpty) {
      SnackbarUtils.showMessage(context, 'Keranjang Anda kosong.');
      return;
    }

    // FIX UTAMA: CEK STATUS AKTIF
    if (_hasInactiveItems) {
      SnackbarUtils.showMessage(
        context,
        'Gagal: Beberapa produk sudah tidak aktif.',
      );
      return; // Blokir checkout
    }

    try {
      // FIX: Panggil getSnapToken DULU sebelum membuat order.
      // Ini memastikan keranjang tidak dikosongkan sebelum pembayaran dimulai.
      // Backend perlu disesuaikan untuk menerima cart_ids dan membuat order jika belum ada.
      final cartIds = _currentItems
          .where((e) => e.id != null) // Filter item yang ID-nya tidak null
          .map((e) => e.id!) // Sekarang aman menggunakan '!'
          .toList();
      final userId = _currentItems.isNotEmpty ? _currentItems.first.userId : 0;

      final snapData = await api.getSnapTokenForOrder(
        orderId: 0, // Kirim 0 atau null untuk menandakan order baru
        cartIds: cartIds,
        userId: userId,
      );

      final redirectUrl = snapData['redirect_url'];
      if (redirectUrl != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(redirectUrl: redirectUrl),
          ),
        );

        if (result == true) {
          SnackbarUtils.showMessage(context, 'Pembayaran berhasil!');

          // FIX: Buat pesanan di backend SETELAH pembayaran berhasil.
          // Ini akan mengosongkan keranjang pada saat yang tepat.
          await api.createOrder();

          // FIX: Tutup dialog dan kirim nilai 'true' untuk menandakan sukses
          if (mounted) Navigator.pop(context, true);
        } else {
          SnackbarUtils.showMessage(
            context,
            'Pembayaran dibatalkan atau gagal.',
          );
        }
      } else {
        throw Exception('Redirect URL tidak ditemukan.');
      }
    } catch (e) {
      SnackbarUtils.showMessage(
        context,
        'Gagal membuat pesanan: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Keranjang Anda', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // Tampilkan peringatan jika ada item yang tidak aktif
          if (_hasInactiveItems)
            Card(
              color: Colors.red.shade100,
              margin: const EdgeInsets.only(bottom: 10),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Beberapa item sudah tidak tersedia dan tidak dapat dipesan.',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          if (_currentItems.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _currentItems.length,
                itemBuilder: (context, index) {
                  final item = _currentItems[index];
                  final product = widget.products.firstWhere(
                    (p) => p.id == item.productId,
                    orElse: () => Product(
                      id: 0,
                      namaProduk: '[TIDAK AKTIF]',
                      harga: 0,
                      kategoriId: 0,
                    ),
                  );
                  final isActive = product.id != 0;

                  return CartItemTile(
                    item: item,
                    product: product,
                    isActive: isActive,
                    onQuantityChanged: (newQuantity) =>
                        _updateLocalQuantity(item, newQuantity),
                  );
                },
              ),
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Rp ${totalPrice}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                // Tombol dinonaktifkan jika ada item yang tidak aktif
                onPressed: _hasInactiveItems ? null : _checkout,
                child: const Text('Pesan Sekarang'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
