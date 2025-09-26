// file: widgets/card_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:kantinku/models/cart_item_model.dart';
import 'package:kantinku/models/product_model.dart';
import 'package:kantinku/services/api_service.dart';
import 'package:kantinku/utils/snackbar_utils.dart';
import 'package:kantinku/screens/payment_screen.dart';
import 'dart:async';

class CartBottomSheet extends StatefulWidget {
  final List<CartItem> items;
  final List<Product> products;
  final VoidCallback onCartUpdated;
  

  const CartBottomSheet({
    Key? key,
    required this.items,
    required this.products,
    required this.onCartUpdated,
  }) : super(key: key);

  @override
  _CartBottomSheetState createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet> {
  final ApiService api = ApiService();
  // Using a local copy to manage state changes within the bottom sheet
  List<CartItem> _currentItems = [];

  @override
  void initState() {
    super.initState();
    _currentItems = List.from(widget.items);
  }

  // Ensure local state is updated if parent widget's data changes
  @override
  void didUpdateWidget(covariant CartBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _currentItems = List.from(widget.items);
    }
  }

  double get totalPrice {
    double total = 0.0;
    for (var item in _currentItems) {
      final product = widget.products.firstWhere(
        (p) => p.id == item.productId,
        orElse: () => Product(id: 0, namaProduk: '', harga: 0, kategoriId: 0),
      );
      total += product.harga * item.jumlah;
    }
    return total;
  }

Timer? _debounce;
void _updateLocalQuantity(CartItem item, int newQuantity) {
  final oldQuantity = item.jumlah;

  // ✅ update UI langsung
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

  // ✅ batalkan request sebelumnya kalau ada
  _debounce?.cancel();

  // ✅ tunda request API biar tidak spam
  _debounce = Timer(const Duration(milliseconds: 600), () async {
    try {
      if (newQuantity <= 0) {
        await api.deleteCartItem(item.id);
      } else {
        await api.updateCartItem(item.id, item.productId, newQuantity);
      }
      widget.onCartUpdated();
    } catch (e) {
      // ❌ rollback kalau gagal
      setState(() {
        final index = _currentItems.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _currentItems[index] = CartItem(
            id: item.id,
            userId: item.userId,
            productId: item.productId,
            jumlah: oldQuantity,
          );
        }
      });
      SnackbarUtils.showMessage(context, 'Gagal update keranjang: $e');
    }
  });
}
Future<void> _checkout() async {
  try {
    if (_currentItems.isEmpty) {
      SnackbarUtils.showMessage(context, "Keranjang kosong!");
      return;
    }

    // ✅ Ambil ID cart
    final cartIds = _currentItems.map((item) => item.id).toList();

    // ✅ Minta Snap Token dari backend
    final response = await api.getSnapToken(cartIds);
    final redirectUrl = response["redirect_url"];

    // ✅ Buka PaymentScreen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(redirectUrl: redirectUrl),
      ),
    );

    // ✅ Setelah balik dari PaymentScreen
    if (result == true) {
      SnackbarUtils.showMessage(context, "Pembayaran berhasil!");

      // refresh keranjang dari backend
      await api.fetchCartItems();
      widget.onCartUpdated();

      // Tutup bottom sheet & kembali ke halaman utama
      Navigator.pop(context);
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      SnackbarUtils.showMessage(context, "Pembayaran dibatalkan atau gagal.");
    }
  } catch (e) {
    SnackbarUtils.showMessage(context, "Error saat checkout: $e");
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
          if (_currentItems.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _currentItems.length,
                itemBuilder: (context, index) {
                  final item = _currentItems[index];
                  final product = widget.products.firstWhere(
                    (p) => p.id == item.productId,
                    orElse: () => Product(id: 0, namaProduk: '', harga: 0, kategoriId: 0),
                  );

                  return ListTile(
                    title: Text(product.namaProduk),
                    subtitle: Text('Rp ${product.harga}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (item.jumlah > 0) {
                              _updateLocalQuantity(item, item.jumlah - 1);
                            }
                          },
                        ),
                        Text('${item.jumlah}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _updateLocalQuantity(item, item.jumlah + 1),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Rp ${totalPrice}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                onPressed: _checkout,
                child: const Text('Pesan Sekarang'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}