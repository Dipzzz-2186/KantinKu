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
import '../widgets/custom_app_bar.dart';
import 'staff_screen.dart';
import '../models/product_user_model.dart';
import '../services/notification_service.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final ApiService api = ApiService();
  List<Product> products = [];
  List<User> booths = [];
  List<ProductUser> productUsers = [];
  String searchQuery = '';
  int? selectedBoothId;
  Map<int, int> quantities = {};
  List<CartItem> cartItems = [];
  int cartCount = 0;
  bool isLoggedIn = false;
  int staffOrderCount = 0;
  int? userId;
  User? _loggedInUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    fetchBooths();
    fetchProducts();
    fetchProductUsers();
  }

  Future<void> fetchProductUsers() async {
    try {
      final relations = await api.fetchProductUsers();
      if (mounted) setState(() => productUsers = relations);
    } catch (e) {
      // Silent fail - relasi produk-user tidak kritis untuk tampilan utama
      if (mounted) setState(() => productUsers = []);
      debugPrint("Info: Relasi produk-user tidak tersedia: $e");
    }
  }

  // HANYA BAGIAN YANG BERUBAH - Sisanya tetap sama

// Di bagian checkLoginStatus(), tambahkan setelah setState:
Future<void> checkLoginStatus() async {
  final token = await api.getAuthToken();
  if (token != null) {
    try {
      final user = await api.getUserProfile(token);
      setState(() {
        isLoggedIn = true;
        userId = user.id;
        _loggedInUser = user;
        if (user.role.toLowerCase() == 'staff') {
          fetchStaffOrders();
        }
      });
      
      // ✅ UPDATE: Set current user di NotificationService
      final notificationService = NotificationService();
      notificationService.setCurrentUser(user);
      
      await fetchCartItems();
      await _handleFcmTokenRegistration();
      
      SnackbarUtils.showMessage(
        context,
        "Selamat datang kembali, ${user.namaPengguna}!",
      );
    } catch (e) {
      await api.clearAuthData();
      setState(() {
        isLoggedIn = false;
        userId = null;
        _loggedInUser = null;
      });
      print("Invalid token, please login again.");
    }
  }
}

// Di bagian showLogin(), tambahkan setelah setState:
Future<void> showLogin() async {
  if (!isLoggedIn) {
    if (!mounted) return;

    final user = await DialogUtils.showLoginDialog(context, api);

    if (user != null && user.id != 0) {
      if (!mounted) return;

      setState(() {
        isLoggedIn = true;
        userId = user.id;
        _loggedInUser = user;
        if (user.role.toLowerCase() == 'staff') {
          fetchStaffOrders();
        }
      });
      
      // ✅ UPDATE: Set current user di NotificationService
      final notificationService = NotificationService();
      notificationService.setCurrentUser(user);
      
      SnackbarUtils.showMessage(
        context,
        "Login berhasil, selamat datang ${user.namaPengguna}!",
      );
      await fetchCartItems();
      await _handleFcmTokenRegistration();
    }
  }
}

// Di bagian logout(), tambahkan di awal:
Future<void> logout() async {
  // ✅ UPDATE: Clear user dari NotificationService
  final notificationService = NotificationService();
  final fcmToken = await notificationService.getFCMToken();
  
   if (fcmToken != null) {
      await api.deleteFcmToken(fcmToken);
    }
  notificationService.setCurrentUser(null);
  await api.clearAuthData();
  setState(() {
    isLoggedIn = false;
    userId = null;
    cartCount = 0;
    cartItems = [];
    staffOrderCount = 0;
    quantities = {for (var p in products) p.id: 0};
    _loggedInUser = null;
  });
  SnackbarUtils.showMessage(context, "Anda telah logout");
}

// _handleFcmTokenRegistration tetap sama seperti kode Anda
Future<void> _handleFcmTokenRegistration() async {
  if (userId == null) return;

  try {
    final notificationService = NotificationService();
    String? fcmToken = await notificationService.getFCMToken();

    if (fcmToken != null) {
      await api.sendFcmToken(userId: userId!, token: fcmToken);
      print('✅ FCM Token sent to backend');
      
      // ✅ TAMBAHAN: Listen to token refresh
      notificationService.listenToTokenRefresh((newToken) async {
        try {
          await api.sendFcmToken(userId: userId!, token: newToken);
          print('✅ Refreshed FCM Token sent to backend');
        } catch (e) {
          print('❌ Failed to send refreshed token: $e');
        }
      });
    }
  } catch (e) {
    print('❌ Failed to send FCM token: $e');
  }
}

  Future<void> fetchBooths() async {
    final allUsers = await api.fetchUsers();
    booths = allUsers.where((u) => u.role == "staff").toList();
    setState(() {});
  }

  Future<void> fetchProducts() async {
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
      final activeProductIds = products.map((p) => p.id).toSet();

      final validCartItems = items.where((item) {
        return activeProductIds.contains(item.productId);
      }).toList();

      // Hanya tampilkan notifikasi jika ada perbedaan signifikan dan user perlu tahu
      if (validCartItems.length < items.length && items.isNotEmpty) {
        final removedCount = items.length - validCartItems.length;
        debugPrint("Info: $removedCount item keranjang difilter karena produk tidak aktif");
        
        // Opsional: Tampilkan snackbar jika ada item yang dihapus
        if (mounted && removedCount > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              SnackbarUtils.showMessage(
                context,
                'Beberapa produk di keranjang tidak tersedia lagi',
              );
            }
          });
        }
      }

      setState(() {
        cartItems = validCartItems;
        cartCount = cartItems.fold(0, (sum, item) => sum + item.jumlah);
      });
    } catch (e) {
      debugPrint('Info: Gagal memuat keranjang: $e');
      setState(() {
        cartItems = [];
        cartCount = 0;
      });
    }
  }

  Future<void> fetchStaffOrders() async {
    if (_loggedInUser?.role.toLowerCase() != 'staff' || userId == null) return;
    try {
      final orders = await api.fetchStaffOrderInbox(userId!);
      if (mounted) {
        final activeOrders = orders
            .where((order) => order.status.toLowerCase() != 'completed')
            .toList();
        setState(() => staffOrderCount = activeOrders.length);
      }
    } catch (e) {
      debugPrint("Info: Gagal memuat pesanan staff: $e");
      if (mounted) setState(() => staffOrderCount = 0);
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
      final existingItem = cartItems.firstWhere(
        (item) => item.productId == product.id,
        orElse: () =>
            CartItem(id: -1, userId: userId!, productId: product.id, jumlah: 0),
      );

      if (existingItem.id != null && existingItem.id != -1) {
        await api.updateCartItem(
          existingItem.id!,
          product.id,
          existingItem.jumlah + qty,
        );
      } else {
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
        setState(() {
          quantities[productId] = 0;
        });
      }

      await fetchCartItems();
      SnackbarUtils.showMessage(
        context,
        '$successCount jenis produk berhasil ditambahkan ke keranjang!',
      );
    } catch (e) {
      SnackbarUtils.showMessage(context, 'Gagal: ${e.toString()}');
      await fetchCartItems();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> showCartPopup() async {
    if (!isLoggedIn || userId == null) {
      await showLogin();
      if (!isLoggedIn || userId == null) return;
    }

    await Future.wait([fetchCartItems(), fetchProducts(), fetchProductUsers()]);

    final checkoutSuccess = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: CartBottomSheet(
              items: cartItems,
              products: products,
              booths: booths,
              productUsers: productUsers,
              baseUrl: api.baseUrl,
              onSyncRequested: (List<CartItem> updatedItems) async {
                await fetchCartItems();
              },
            ),
          ),
        );
      },
    );

    await fetchCartItems();

    if (checkoutSuccess == true) {
      setState(() {
        quantities = {for (var p in products) p.id: 0};
      });
    }
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Warna yang lebih modern dan elegan
    const primaryColor = Color(0xFF5D4037); // Dark brown yang lebih rich
    const secondaryColor = Color(0xFF8D6E63); // Medium brown
    const accentColor = Color(0xFFD7CCC8); // Light brown/cream
    const backgroundColorStart = Color(0xFFFFFBF5);
    const backgroundColorEnd = Color(0xFFF5F0E8);
    final itemsWithQuantity = quantities.values.where((qty) => qty > 0).length;
    final showFab = _loggedInUser?.role != 'staff' && itemsWithQuantity > 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        backgroundColor: primaryColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kantinku',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Pesan makanan favoritmu',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (isLoggedIn && _loggedInUser != null)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(Icons.history, color: Colors.white, size: 22),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        OrderHistoryScreen(user: _loggedInUser!),
                  ),
                );
              },
              tooltip: 'Riwayat Pesanan',
            ),
          if (isLoggedIn && _loggedInUser?.role.toLowerCase() == 'staff')
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.store_mall_directory,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StaffScreen(
                            staffUser: _loggedInUser!,
                            onLogout: logout,
                          ),
                        ),
                      );
                      fetchStaffOrders();
                    },
                    tooltip: 'Halaman Staff',
                  ),
                  if (staffOrderCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: _buildBadge(staffOrderCount),
                    ),
                ],
              ),
            ),
          if (!isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(Icons.login, color: Colors.white, size: 22),
                ),
                onPressed: showLogin,
                tooltip: 'Login',
              ),
            ),
          if (isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(Icons.logout, color: Colors.white, size: 22),
                ),
                onPressed: logout,
                tooltip: 'Logout',
              ),
            ),
          if (_loggedInUser?.role != 'staff')
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    onPressed: showCartPopup,
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: _buildBadge(cartCount),
                    ),
                ],
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundColorStart, backgroundColorEnd],
          ),
        ),
        child: Column(
          children: [
            // Search Bar dengan shadow yang lebih halus
            Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SearchBarWidget(
                onSearch: (val) {
                  setState(() {
                    searchQuery = val;
                  });
                },
              ),
            ),
            
            // Booth Filter Chips dengan design yang lebih modern
            Container(
              height: 56,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip(
                    label: 'Semua Booth',
                    icon: Icons.grid_view_rounded,
                    isSelected: selectedBoothId == null,
                    onSelected: (_) async {
                      setState(() {
                        selectedBoothId = null;
                        _isLoading = true;
                      });
                      await fetchProducts();
                      setState(() => _isLoading = false);
                    },
                  ),
                  const SizedBox(width: 10),
                  ...booths.map(
                    (booth) => Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: _buildFilterChip(
                        label: booth.namaPengguna,
                        icon: Icons.store,
                        isSelected: selectedBoothId == booth.id,
                        onSelected: (_) async {
                          setState(() {
                            selectedBoothId = booth.id;
                            _isLoading = true;
                          });
                          final newProducts = await api.fetchStaffProducts(
                            booth.id,
                            filters: {"is_active": true},
                          );
                          setState(() {
                            products = newProducts;
                            quantities = {for (var p in newProducts) p.id: 0};
                            _isLoading = false;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Products Grid
            Expanded(
              child: filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 80,
                            color: primaryColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Produk tidak ditemukan',
                            style: TextStyle(
                              fontSize: 16,
                              color: primaryColor.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
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
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, idx) {
                            final product = filteredProducts[idx];
                            final qty = quantities[product.id] ?? 0;
                            return ProductCard(
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
      ),
      floatingActionButton: showFab
          ? Container(
              decoration: BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ).toDecorationBox(),
              child: FloatingActionButton.extended(
                onPressed: _isLoading ? null : addAllToCart,
                backgroundColor: primaryColor,
                elevation: 0,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.shopping_cart_checkout,
                        color: Colors.white,
                      ),
                label: Text(
                  'Pesan Semua ($itemsWithQuantity)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    const primaryColor = Color(0xFF5D4037);
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : primaryColor,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      selectedColor: primaryColor,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? primaryColor : primaryColor.withOpacity(0.2),
        width: 1.5,
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : primaryColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontSize: 14,
      ),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onSelected: onSelected,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: isSelected ? 2 : 0,
      shadowColor: primaryColor.withOpacity(0.2),
    );
  }
}

// Extension helper untuk BoxShadow to BoxDecoration
extension BoxShadowToDecoration on BoxShadow {
  BoxDecoration toDecorationBox() {
    return BoxDecoration(
      boxShadow: [this],
      borderRadius: BorderRadius.circular(16),
    );
  }
}