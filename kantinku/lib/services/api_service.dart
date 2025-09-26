import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// import semua model
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/payment_model.dart';

class ApiService {
  final String baseUrl = "https://3dc3814244d8.ngrok-free.app"; // ganti sesuai server FastAPI kamu
   String? _authToken;
  int? _currentUserId;

  // ================== AUTH TOKEN ==================
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

    Future<void> saveAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

   Future<Map<String, String>> getAuthHeaders() async {
    if (_authToken == null) {
      _authToken = await getAuthToken();
    }
    return {
      "Content-Type": "application/json",
      if (_authToken != null) "Authorization": "Bearer $_authToken",
    };
  }

  // Fungsi untuk mendapatkan user ID yang tersimpan
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // Fungsi untuk menyimpan token dan user ID
  Future<void> saveAuthData(String token, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setInt('user_id', userId);
    _authToken = token;
    _currentUserId = userId;
  }

  // Fungsi untuk menghapus data otentikasi saat logout
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    _authToken = null;
    _currentUserId = null;
  }

    Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ================== USERS ==================
   Future<List<User>> fetchUsers() async {
    final response = await http.get(Uri.parse("$baseUrl/users/"));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => User.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load users");
    }
  }

   // Perbarui fungsi loginUser untuk menyimpan token dan user ID
 Future<User> loginUser(String nama, String password) async {
  final response = await http.post(
    Uri.parse("$baseUrl/auth/login"),
    headers: {"Content-Type": "application/x-www-form-urlencoded"},
    body: {
      "username": nama,
      "password": password,
    },
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final token = data['access_token'];
    await saveAuthToken(token);

    final user = await getUserProfile(token);

    // ✅ simpan user_id
    await saveAuthData(token, user.id);

    return user;
  } else {
    throw Exception("Gagal login: ${response.body}");
  }
}

  Future<User> createUser(String nama, String noTelp, String role, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "nama_pengguna": nama,
        "nomor_telepon": noTelp,
        "role": role,
        "password": password,
      }),
    );
    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to create user");
    }
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/users/$id"));
    if (response.statusCode != 200) {
      throw Exception("Failed to delete user");
    }
  }

   Future<User> registerUser(String nama, String phone, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"), // Ubah endpoint register
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "nama_pengguna": nama,
        "nomor_telepon": phone,
        "role": "customer",
        "password": password,
      }),
    );
    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception("Gagal mendaftar: ${response.body}");
    }
  }

  // Fetch user profile using the token
Future<User> getUserProfile(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/auth/profile"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception("Gagal mengambil profil pengguna: ${response.body}");
    }
  }

  // ================== CATEGORIES ==================
  Future<List<Category>> fetchCategories() async {
    final response = await http.get(Uri.parse("$baseUrl/categories/"));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Category.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load categories");
    }
  }

  Future<Category> createCategory(String kategori) async {
    final response = await http.post(
      Uri.parse("$baseUrl/categories/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"kategori": kategori}),
    );
    if (response.statusCode == 200) {
      return Category.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to create category");
    }
  }

  // ================== PRODUCTS ==================
  Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse("$baseUrl/products/"));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load products");
    }
  }

    Future<List<Product>> fetchProductsByUser(int userId) async {
      final response = await http.get(Uri.parse("$baseUrl/products/filter-by-user?user_id=$userId"));
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        return data.map((e) => Product.fromJson(e)).toList();
      } else {
        throw Exception("Failed to filter products by user");
      }
  }

  Future<Product> createProduct(String nama, int harga, int kategoriId, {String? gambar}) async {
    final response = await http.post(
      Uri.parse("$baseUrl/products/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "nama_produk": nama,
        "harga": harga,
        "kategori_id": kategoriId,
        "gambar": gambar
      }),
    );
    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to create product");
    }
  }

  // ================== CART ITEMS ==================
 
  Future<CartItem> addToCart(int productId, int jumlah) async {
    final headers = await getAuthHeaders();
    final response = await http.post(
      Uri.parse("$baseUrl/carts/"),
      headers: headers,
      body: json.encode({"product_id": productId, "jumlah": jumlah}),
    );
    if (response.statusCode == 200) {
      return CartItem.fromJson(json.decode(response.body));
    } else {
      throw Exception("Gagal menambahkan ke keranjang: ${response.body}");
    }
  }

  // Perbarui semua metode API yang memerlukan otentikasi
  Future<List<CartItem>> fetchCartItems() async {
    final headers = await getAuthHeaders();
    final response = await http.get(Uri.parse("$baseUrl/carts/"), headers: headers);
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => CartItem.fromJson(e)).toList();
    } else {
      throw Exception("Gagal memuat item keranjang: ${response.body}");
    }
  }
  Future<void> updateCartItem(int cartItemId, int productId, int newQuantity) async {
    final headers = await getAuthHeaders();
    final response = await http.put(
      Uri.parse("$baseUrl/carts/$cartItemId"),
      headers: headers,
      body: json.encode({
        "product_id": productId,
        "jumlah": newQuantity,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Gagal update item keranjang: ${response.body}");
    }
  }

// Delete a specific cart item
Future<void> deleteCartItem(int cartItemId) async {
  final headers = await getAuthHeaders();
  final response = await http.delete(
    Uri.parse("$baseUrl/carts/$cartItemId"),
    headers: headers,
  );
  if (response.statusCode != 200) {
    throw Exception("Gagal menghapus item keranjang: ${response.body}");
  }
}

  // ================== ORDERS ==================
  Future<List<Order>> fetchOrders(int userId) async {
    final response = await http.get(Uri.parse("$baseUrl/orders/$userId"));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load orders");
    }
  }

  Future<Order> createOrder() async {
  final headers = await getAuthHeaders();
  final response = await http.post(
    Uri.parse("$baseUrl/orders/"),
    headers: headers,
    // Tidak perlu mengirim body, karena backend akan mengambil dari keranjang
  );
  if (response.statusCode == 200) {
    return Order.fromJson(json.decode(response.body));
  } else {
    throw Exception("Gagal membuat pesanan: ${response.body}");
  }
}

  // ================== ORDER ITEMS ================== // Fungsi untuk membuat item pesanan
  Future<OrderItem> createOrderItem(int orderId, int productId, int jumlah, double hargaUnit) async {
    final headers = await getAuthHeaders();
    final response = await http.post(
      Uri.parse("$baseUrl/order_items/"),
      headers: headers,
      body: json.encode({
        "order_id": orderId,
        "product_id": productId,
        "jumlah": jumlah,
        "harga_unit": hargaUnit,
        "subtotal": jumlah * hargaUnit,
      }),
    );
    if (response.statusCode == 200) {
      return OrderItem.fromJson(json.decode(response.body));
    } else {
      throw Exception("Gagal membuat item pesanan: ${response.body}");
    }
  }

  // ================== PAYMENTS ==================

Future<Map<String, dynamic>> getSnapToken(List<int> cartIds) async {
  final headers = await getAuthHeaders();

  // ✅ pastikan _currentUserId tidak null
  if (_currentUserId == null) {
    _currentUserId = await getUserId();
  }

  final response = await http.post(
    Uri.parse("$baseUrl/payments/snap-token"),
    headers: headers,
    body: json.encode({
      "user_id": _currentUserId,
      "cart_ids": cartIds,
    }),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception("Gagal mendapatkan snap token: ${response.body}");
  }
}


  Future<Payment> createPayment(int orderId, String metode, double jumlah) async {
    final response = await http.post(
      Uri.parse("$baseUrl/payments/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "order_id": orderId,
        "metode_pembayaran": metode,
        "jumlah_pembayaran": jumlah,
        "status_pembayaran": "pending"
      }),
    );
    if (response.statusCode == 200) {
      return Payment.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to create payment");
    }
  }

  Future<List<Payment>> fetchPayments(int orderId) async {
    final response = await http.get(Uri.parse("$baseUrl/payments/$orderId"));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Payment.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load payments");
    }
  }
}
