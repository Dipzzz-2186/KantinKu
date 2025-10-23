// file: widgets/card_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:kantinku/models/cart_item_model.dart';
import 'package:kantinku/models/product_model.dart';
import 'package:kantinku/services/api_service.dart';
import 'package:kantinku/utils/snackbar_utils.dart';
import 'package:kantinku/widgets/product_image_display.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:kantinku/screens/payment_screen.dart';
import 'package:kantinku/models/user_model.dart';
import 'package:kantinku/models/product_user_model.dart';
import 'package:intl/intl.dart';

typedef OnCartSync = void Function(List<CartItem> updatedItems);

class CartBottomSheet extends StatefulWidget {
  final List<CartItem> items;
  final List<User> booths;
  final List<Product> products;
  final OnCartSync onSyncRequested;
  final List<ProductUser> productUsers;
  final String baseUrl;
  

  const CartBottomSheet({
    Key? key,
    required this.items,
    required this.products,
    required this.booths,
    required this.baseUrl,
    required this.productUsers,
    required this.onSyncRequested,
  }) : super(key: key);

  @override
  _CartBottomSheetState createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet> {
  final ApiService api = ApiService();
  List<CartItem> _currentItems = [];
  bool _hasInactiveItems = false;
  bool _showSellerDetails = false;

  @override
  void initState() {
    super.initState();
    _currentItems = List.from(widget.items);
    _checkInactiveStatus();
  }

  static const primaryColor = Color(0xFF5D4037);
  static const backgroundColor = Color(0xFFFFFBF5);
  static const textColor = Color(0xFF3E2723);
  static const accentColor = Color(0xFFE65100);

  @override
  void didUpdateWidget(covariant CartBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _currentItems = List.from(widget.items);
      _checkInactiveStatus();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  // === FUNGSI PERHITUNGAN YANG SAMA DENGAN BACKEND ===
  // Menggunakan metode invers seperti di hitung_harga_jual (backend)
  double hitungHargaJual(double subtotal, double biayaTetap, double feeQris, double ppnPersen) {
    // Formula: harga_jual = ceil((subtotal + biaya_tetap) / (1 - fee_qris * (1 + ppn/100)))
    double denominator = 1 - (feeQris / 100 * (1 + ppnPersen / 100));
    double hargaJual = (subtotal + biayaTetap) / denominator;
    return hargaJual.ceilToDouble(); // Pembulatan ke atas seperti di backend
  }

  // Hitung subtotal dari semua item di cart
  double get subtotal {
    double total = 0.0;
    for (var item in _currentItems) {
      final product = widget.products.firstWhere(
        (p) => p.id == item.productId,
        orElse: () => Product(id: 0, namaProduk: '', harga: 0, kategoriId: 0),
      );
      if (product.id != 0) {
        total += product.harga * item.jumlah;
      }
    }
    return total;
  }

  int get totalItems {
    return _currentItems.fold(0, (sum, item) => sum + item.jumlah);
  }

  Timer? _debounce;

  void _updateLocalQuantity(CartItem item, int newQuantity) {
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

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        if (newQuantity <= 0) {
          await api.deleteCartItem(item.id!);
        } else {
          await api.updateCartItem(item.id!, item.productId, newQuantity);
        }
        widget.onSyncRequested([]);
      } catch (e) {
        SnackbarUtils.showMessage(
          context,
          'Gagal update keranjang: ${e.toString()}',
        );
        widget.onSyncRequested([]);
      }
    });
  }

  void _checkInactiveStatus() {
    final activeProductIds = widget.products.map((p) => p.id).toSet();
    final hasInvalidItem = _currentItems.any(
      (item) => !activeProductIds.contains(item.productId),
    );

    setState(() {
      _hasInactiveItems = hasInvalidItem;
    });
  }

  Future<void> _checkout() async {
    if (_currentItems.isEmpty) {
      SnackbarUtils.showMessage(context, 'Keranjang Anda kosong.');
      return;
    }

    if (_hasInactiveItems) {
      SnackbarUtils.showMessage(
        context,
        'Gagal: Beberapa produk sudah tidak aktif.',
      );
      return;
    }

    try {
      final cartIds = _currentItems
          .where((e) => e.id != null)
          .map((e) => e.id!)
          .toList();
      final userId = _currentItems.isNotEmpty ? _currentItems.first.userId : 0;

      final snapData = await api.getSnapTokenForOrder(
        orderId: 0,
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
          await api.createOrder();
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
    return Container(
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          if (_hasInactiveItems) _buildWarningBanner(),
          Expanded(
            child: _currentItems.isEmpty
                ? _buildEmptyCart()
                : _buildCartList(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Keranjang Belanja',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (_currentItems.isNotEmpty)
                      Text(
                        '$totalItems item dipilih',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (_currentItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accentColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_currentItems.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade100,
            Colors.red.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Beberapa item sudah tidak tersedia dan tidak dapat dipesan.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: primaryColor.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Keranjang Masih Kosong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yuk, mulai belanja sekarang!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        return _buildCartItem(item, product, isActive);
      },
    );
  }

  Widget _buildFooter() {
    // === PERHITUNGAN YANG SAMA DENGAN BACKEND ===
    const double feeQris = 0.7;        // 0.7%
    const double biayaTetap = 500;     // Rp 500
    const double ppnPersen = 11;       // 11%

    final double subtotalHargaAwal = subtotal;
    
    // Gunakan fungsi yang sama dengan backend
    final double hargaJualAkhir = hitungHargaJual(
      subtotalHargaAwal, 
      biayaTetap, 
      feeQris, 
      ppnPersen
    );

    // Biaya layanan total = selisih antara harga jual dan subtotal
    final double biayaLayananTotal = hargaJualAkhir - subtotalHargaAwal;

    // === BREAKDOWN UNTUK DITAMPILKAN (ESTIMASI) ===
    // Ini hanya untuk visualisasi, angka sebenarnya sudah benar dari hitungHargaJual
    final double estimasiFeeQris = hargaJualAkhir * (feeQris / 100);
    final double estimasiPpn = estimasiFeeQris * (ppnPersen / 100);
    
    // === PERHITUNGAN PENERIMAAN PENJUAL ===
    final double potonganMidtrans = hargaJualAkhir * (feeQris / 100);
    final double penerimaanPenjual = hargaJualAkhir - potonganMidtrans - biayaTetap;

    Widget buildFeeRow(String label, double value, {bool isBold = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isBold ? 14 : 13,
                  color: isBold ? textColor : Colors.grey[600],
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Text(
              formatCurrency(value),
              style: TextStyle(
                fontSize: isBold ? 14 : 13,
                color: isBold
                    ? textColor
                    : (value < 0 ? Colors.red.shade700 : Colors.grey[800]),
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [

          // === TOMBOL SHOW/HIDE RINCIAN PENJUAL ===
          InkWell(
            onTap: () {
              setState(() {
                _showSellerDetails = !_showSellerDetails;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Rincian Pembayaran',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showSellerDetails ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.grey[700],
                  ),
                ],
              ),
            ),
          ),

          // === RINCIAN PENJUAL (COLLAPSIBLE) ===
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: !_showSellerDetails
                ? const SizedBox.shrink()
                :   Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rincian Pembayaran',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                buildFeeRow('Subtotal Produk', subtotalHargaAwal),
                buildFeeRow('Biaya Admin', biayaTetap),
                buildFeeRow('Biaya Layanan & Pajak', biayaLayananTotal),
                const Divider(height: 16),
                buildFeeRow('Total Pembayaran', hargaJualAkhir, isBold: true),
              ],
            ),
          ),
          ),

          // === TOMBOL CHECKOUT ===
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _hasInactiveItems || _currentItems.isEmpty
                  ? null
                  : _checkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _hasInactiveItems || _currentItems.isEmpty ? 0 : 2,
                shadowColor: primaryColor.withOpacity(0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _currentItems.isEmpty
                        ? 'Keranjang Kosong'
                        : _hasInactiveItems
                            ? 'Ada Item Tidak Aktif'
                            : 'Bayar ${formatCurrency(hargaJualAkhir)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, Product product, bool isActive) {
    final productUserRelation = widget.productUsers.firstWhere(
      (pu) => pu.productId == product.id,
      orElse: () => ProductUser(id: 0, userId: 0, productId: 0),
    );

    final boothId = productUserRelation.userId;
    final booth = widget.booths.firstWhere(
      (b) => b.id == boothId,
      orElse: () =>
          User(id: 0, namaPengguna: 'Booth tidak diketahui', role: ''),
    );

    String? fullImageUrl;
    if (product.gambar != null && product.gambar!.isNotEmpty) {
      fullImageUrl = product.gambar;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Colors.grey.shade200
              : Colors.red.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? primaryColor.withOpacity(0.05)
                : Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ProductImageDisplay(
                  imageString: fullImageUrl,
                  width: 80,
                  height: 80,
                  iconSize: 40,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.namaProduk,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isActive ? textColor : Colors.grey,
                      decoration: isActive
                          ? TextDecoration.none
                          : TextDecoration.lineThrough,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.store,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          booth.namaPengguna,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrency(product.harga.toDouble()),
                    style: const TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isActive)
              Container(
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.remove,
                          color: item.jumlah > 1
                              ? const Color(0xFFC62828)
                              : Colors.grey,
                          size: 18,
                        ),
                        onPressed: () =>
                            _updateLocalQuantity(item, item.jumlah - 1),
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 28),
                      alignment: Alignment.center,
                      child: Text(
                        item.jumlah.toString(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.add,
                          color: Color(0xFF2E7D32),
                          size: 18,
                        ),
                        onPressed: () =>
                            _updateLocalQuantity(item, item.jumlah + 1),
                      ),
                    ),
                  ],
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _updateLocalQuantity(item, 0),
                tooltip: 'Hapus item',
              ),
          ],
        ),
      ),
    );
  }
}