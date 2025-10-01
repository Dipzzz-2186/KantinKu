// file: screens/product_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/cart_item_model.dart';
import '../widgets/product_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/card_bottom_sheet.dart';
import '../utils/snackbar_utils.dart';
import '../utils/dialog_utils.dart';
import 'order_history_screen.dart';
import 'staff_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final ApiService api = ApiService();
  List<Product> products = [];
  List<User> booths = [];
  String searchQuery = '';
  int? selectedBoothId;
  Map<int, int> quantities = {};
  List<CartItem> cartItems = [];
  int cartCount = 0;
  bool isLoggedIn = false;
  int? userId;
  User?
  _loggedInUser; // Tambahkan variabel untuk menyimpan objek user yang login
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    fetchBooths();
    fetchProducts();
  }

  Future<void> checkLoginStatus() async {
    final token = await api.getAuthToken();
    if (token != null) {
      try {
        final user = await api.getUserProfile(token);
        setState(() {
          isLoggedIn = true;
          userId = user.id;
          _loggedInUser = user; // Simpan objek user yang login
        });
        await fetchCartItems();
        SnackbarUtils.showMessage(
          context,
          "Selamat datang kembali, ${user.namaPengguna}!",
        );
      } catch (e) {
        await api.clearAuthData();
        setState(() {
          isLoggedIn = false;
          userId = null;
          _loggedInUser = null; // Hapus objek user saat token tidak valid
        });
        print("Invalid token, please login again.");
      }
    }
  }

  Future<void> showLogin() async {
    if (!isLoggedIn) {
      // Hanya tampilkan dialog login jika belum login
      final user = await DialogUtils.showLoginDialog(
        context,
        api,
      ); // Tampilkan dialog login

      if (user != null && user.id != 0) {
        // Jika login berhasil
        setState(() {
          // Update state untuk semua role (customer atau staff)
          isLoggedIn = true;
          userId = user.id;
          _loggedInUser = user; // Simpan objek user yang login
        });
        // FIX: Tampilkan notifikasi sukses login di sini
        SnackbarUtils.showMessage(
          context, "Login berhasil, selamat datang ${user.namaPengguna}!",
        );
        await fetchCartItems(); // Ambil item keranjang setelah login
      }
    }
  }

  Future<void> logout() async {
    await api.clearAuthData();
    setState(() {
      isLoggedIn = false;
      userId = null;
      cartCount = 0;
      cartItems = [];
      quantities = {for (var p in products) p.id: 0};
      _loggedInUser = null; // Hapus objek user saat logout
    });
    SnackbarUtils.showMessage(context, "Anda telah logout");
  }

  Future<void> fetchBooths() async {
    final allUsers = await api.fetchUsers();
    booths = allUsers.where((u) => u.role == "staff").toList();
    setState(() {});
  }

  Future<void> fetchProducts() async {
    // FIX: Panggil fetchProducts dengan filter is_active: true
    // Endpoint ini akan mengambil semua produk yang aktif dari semua staff.
    final newProducts = await api.fetchProducts(filters: {"is_active": true});
    products = newProducts;
    for (var p in products) {
      quantities.putIfAbsent(p.id, () => 0);
    }
    setState(() {});
  }

  Future<void> fetchCartItems() async {
    try {
      final items = await api.fetchCartItems();

      // Logika Penanganan: Filter item keranjang yang produknya sudah tidak ada
      // Kita perlu daftar ID produk yang aktif saat ini.
      final activeProductIds = products.map((p) => p.id).toSet();

      final validCartItems = items.where((item) {
        // Cek apakah product_id dari cart item ada dalam daftar produk aktif
        return activeProductIds.contains(item.productId);
      }).toList();

      // DEBUGGING: Tambahkan logic untuk memberi tahu user jika ada item yang hilang
      if (validCartItems.length < items.length) {
        // Jangan tampilkan pesan error yang keras, hanya notifikasi
        print(
          "Warning: Some cart items were filtered because the product is inactive.",
        );
      }

      setState(() {
        cartItems = validCartItems;
        cartCount = cartItems.fold(0, (sum, item) => sum + item.jumlah);
      });
    } catch (e) {
      print('Gagal memuat keranjang: $e');
      setState(() {
        cartItems = [];
        cartCount = 0;
      });
    }
  }

  List<Product> get filteredProducts => products
      .where(
        (p) => p.namaProduk.toLowerCase().contains(searchQuery.toLowerCase()),
      )
      .toList();

  Future<void> addToCart(Product product) async {
    if (!isLoggedIn || userId == null) {
      await showLogin();
      if (!isLoggedIn || userId == null) return;
    }

    final qty = quantities[product.id] ?? 0;
    if (qty == 0) {
      SnackbarUtils.showMessage(context, 'Quantity harus lebih dari 0');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Cek apakah produk sudah ada di cart
      final existingItem = cartItems.firstWhere(
        (item) => item.productId == product.id,
        orElse: () =>
            CartItem(id: -1, userId: userId!, productId: product.id, jumlah: 0),
      );

      if (existingItem.id != null && existingItem.id != -1) {
        // Update jumlah di backend
        await api.updateCartItem(
          existingItem.id!, // Gunakan '!' karena sudah dipastikan tidak null
          product.id,
          existingItem.jumlah + qty,
        );
      } else {
        // Tambah baru
        await api.addToCart(product.id, qty);
      }

      await fetchCartItems();
      setState(() {
        quantities[product.id] = 0;
      });

      SnackbarUtils.showMessage(
        context,
        '${product.namaProduk} ditambahkan ke keranjang',
      );
    } catch (e) {
      SnackbarUtils.showMessage(
        context,
        'Gagal menambahkan ke keranjang: ${e.toString()}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Fungsi baru untuk tombol FAB
  Future<void> addAllToCart() async {
    if (!isLoggedIn || userId == null) {
      await showLogin();
      if (!isLoggedIn || userId == null) return;
    }

    final itemsToAdd = quantities.entries
        .where((entry) => entry.value > 0)
        .toList();

    if (itemsToAdd.isEmpty) {
      SnackbarUtils.showMessage(context, 'Tidak ada produk yang dipilih.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      int successCount = 0;
      for (var entry in itemsToAdd) {
        final productId = entry.key;
        final qty = entry.value;

        await api.addToCart(productId, qty);
        successCount++;
        // Reset kuantitas lokal setelah berhasil ditambahkan
        setState(() {
          quantities[productId] = 0;
        });
      }

      await fetchCartItems(); // Sinkronkan keranjang
      SnackbarUtils.showMessage(
        context,
        '$successCount jenis produk berhasil ditambahkan ke keranjang!',
      );
    } catch (e) {
      SnackbarUtils.showMessage(context, 'Gagal: ${e.toString()}');
      await fetchCartItems(); // Tetap sinkronkan jika ada error di tengah jalan
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> showCartPopup() async {
    if (!isLoggedIn || userId == null) {
      await showLogin();
      if (!isLoggedIn || userId == null) return;
    }

    await fetchCartItems();

    // FIX: Ubah dari BottomSheet menjadi Dialog yang mengambang
    final checkoutSuccess = await showDialog<bool>(
      context: context,
      builder: (context) {
        // Dialog memberikan efek mengambang
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500, // Lebar maksimum dialog
              maxHeight:
                  MediaQuery.of(context).size.height * 0.75, // Tinggi maksimum
            ),
            child: CartBottomSheet(
              items: cartItems,
              products: products,
              onSyncRequested: (List<CartItem> updatedItems) async {
                await fetchCartItems();
              },
            ),
          ),
        );
      },
    );

    // Final sync (setelah bottom sheet ditutup)
    await fetchCartItems();

    // Jika checkout berhasil (dari Navigator.pop(context, true)),
    // reset kuantitas lokal agar tidak muncul FAB lagi.
    if (checkoutSuccess == true) {
      setState(() {
        quantities = {for (var p in products) p.id: 0};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cek kondisi untuk menampilkan FAB
    final itemsWithQuantity = quantities.values.where((qty) => qty > 0).length;
    final showFab = _loggedInUser?.role != 'staff' && itemsWithQuantity > 1;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Kantinku'),
        actions: [
          if (isLoggedIn &&
              _loggedInUser != null) // Pastikan _loggedInUser tidak null
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderHistoryScreen(
                      // Teruskan objek user yang sebenarnya
                      user: _loggedInUser!,
                    ),
                  ),
                );
              },
              tooltip: 'Riwayat Pesanan',
            ),

          // Tombol untuk ke halaman Staff (hanya muncul jika user adalah staff)
          if (isLoggedIn &&
              _loggedInUser != null &&
              _loggedInUser!.role.toLowerCase() == 'staff')
            IconButton(
              icon: const Icon(
                Icons.store_mall_directory,
              ), // Ikon untuk halaman staff
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StaffScreen(
                      staffUser: _loggedInUser!,
                      onLogout: logout,
                    ),
                  ),
                );
              },
              tooltip: 'Halaman Staff',
            ),

          // ... (Tombol Login/Logout dan Keranjang tetap sama)
          if (!isLoggedIn)
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: showLogin,
              tooltip: 'Login',
            ),
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: logout,
              tooltip: 'Logout',
            ),
          // FIX: Sembunyikan keranjang jika user adalah staff
          if (_loggedInUser?.role != 'staff')
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: showCartPopup,
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SearchBarWidget(
              onSearch: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
            ),
          ),
          SizedBox(
            height: 50,
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('Semua Booth'),
                    selected: selectedBoothId == null,
                    onSelected: (_) async {
                      setState(() {
                        selectedBoothId = null;
                      });
                      await fetchProducts();
                    },
                  ),
                  ...booths.map(
                    (booth) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(booth.namaPengguna),
                        selected: selectedBoothId == booth.id,
                        onSelected: (_) async {
                          setState(() {
                            selectedBoothId = booth.id;
                          });
                          // FIX: Panggil fetchStaffProducts dengan filter is_active: true
                          final newProducts = await api.fetchStaffProducts(
                            booth.id,
                            filters: {"is_active": true},
                          );
                          products = newProducts;
                          for (var p in products) {
                            quantities.putIfAbsent(p.id, () => 0);
                          }
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(child: Text('Produk tidak ditemukan'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 3;
                      double width = constraints.maxWidth;
                      if (width > 1200) crossAxisCount = 5;
                      if (width < 1200) crossAxisCount = 4;
                      if (width < 1000) crossAxisCount = 3;
                      if (width < 700) crossAxisCount = 2;
                      if (width < 400) crossAxisCount = 1;
                      return GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, idx) {
                          final product = filteredProducts[idx];
                          final qty = quantities[product.id] ?? 0;
                          return ProductCard(
                            // FIX: Jangan tampilkan kontrol jika user adalah staff
                            showControls: _loggedInUser?.role != 'staff',
                            product: product,
                            quantity: qty,
                            onAdd: () {
                              setState(() {
                                quantities[product.id] = qty + 1;
                              });
                            },
                            onRemove: () {
                              setState(() {
                                if (qty > 0) quantities[product.id] = qty - 1;
                              });
                            },
                            onAddToCart: () => addToCart(product),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : addAllToCart,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.shopping_cart_checkout),
              label: const Text('Pesan Semua'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
