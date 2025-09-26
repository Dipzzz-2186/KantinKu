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
    });
    await fetchCartItems();
    SnackbarUtils.showMessage(context, "Selamat datang kembali, ${user.namaPengguna}!");
   } catch (e) {
    await api.clearAuthData();
    setState(() {
     isLoggedIn = false;
     userId = null;
    });
    print("Invalid token, please login again.");
   }
  }
 }

 Future<void> showLogin() async {
  if (!isLoggedIn) {
   final user = await DialogUtils.showLoginDialog(context, api);
   if (user != null) {
    setState(() {
     isLoggedIn = true;
     userId = user.id;
    });
    await fetchCartItems();
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
  });
  SnackbarUtils.showMessage(context, "Anda telah logout");
 }

 Future<void> fetchBooths() async {
  final allUsers = await api.fetchUsers();
  booths = allUsers.where((u) => u.role == "staff").toList();
  setState(() {});
 }

 Future<void> fetchProducts() async {
  products = await api.fetchProducts();
  quantities = {for (var p in products) p.id: 0};
  setState(() {});
 }

 Future<void> fetchCartItems() async {
  try {
   final items = await api.fetchCartItems();
   setState(() {
    cartItems = items;
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
   .where((p) => p.namaProduk.toLowerCase().contains(searchQuery.toLowerCase()))
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
      orElse: () => CartItem(id: -1, userId: userId!, productId: product.id, jumlah: 0),
    );

    if (existingItem.id != -1) {
      // Update jumlah di backend
      await api.updateCartItem(existingItem.id, product.id, existingItem.jumlah + qty);
    } else {
      // Tambah baru
      await api.addToCart(product.id, qty);
    }

    await fetchCartItems();
    setState(() {
      quantities[product.id] = 0;
    });

    SnackbarUtils.showMessage(context, '${product.namaProduk} ditambahkan ke keranjang');
  } catch (e) {
    SnackbarUtils.showMessage(context, 'Gagal menambahkan ke keranjang: ${e.toString()}');
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
  
  await showModalBottomSheet(
   context: context,
   isScrollControlled: true,
   builder: (context) => CartBottomSheet(
    items: cartItems, 
    products: products,
    onCartUpdated: () async {
     await fetchCartItems();
    },
   ),
  );
  
  await fetchCartItems();
 }

 @override
 Widget build(BuildContext context) {
    return Scaffold(
   appBar: AppBar(
    title: const Text('Kantinku'),
    actions: [
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
          child: Text('$cartCount', style: const TextStyle(fontSize: 12, color: Colors.white)),
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
      child: SearchBarWidget(onSearch: (val) {
       setState(() {
        searchQuery = val;
       });
      }),
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
         ...booths.map((booth) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
           label: Text(booth.namaPengguna),
           selected: selectedBoothId == booth.id,
           onSelected: (_) async {
            setState(() {
             selectedBoothId = booth.id;
            });
            products = await api.fetchProductsByUser(booth.id);
            quantities = {for (var p in products) p.id: 0};
            setState(() {});
           },
          ),
         )),
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
  );
 }
}