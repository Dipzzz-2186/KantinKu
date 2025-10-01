import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// import semua model
import '../models/user_model.dart';
import '../models/category_model.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import 'dart:io' as io; // Gunakan prefix 'io' untuk File (di mobile)
// import 'dart:html' as html; // Dihapus karena tidak digunakan secara langsung
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/payment_model.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'dart:typed_data';

class ApiService {
  final String baseUrl =
      "http://127.0.0.1:8000"; // ganti sesuai server FastAPI kamu
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
      "ngrok-skip-browser-warning": "true", // FIX: Aktifkan header ini
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
    final headers = await getAuthHeaders();
    headers.remove("Content-Type"); // GET request tidak butuh Content-Type JSON

    final response = await http.get(
      Uri.parse("$baseUrl/users/"),
      headers: headers,
    );
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
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "ngrok-skip-browser-warning": "true", // FIX: Tambahkan header
      },
      body: {"username": nama, "password": password},
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

  Future<User> createUser(
    String nama,
    String noTelp,
    String role,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/"),
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true", // FIX: Tambahkan header
      },
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
      // FIX: Berikan pesan error yang lebih spesifik dari backend
      try {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? "Gagal membuat pengguna");
      } catch (_) {
        throw Exception(
          "Gagal membuat pengguna. Status: ${response.statusCode}",
        );
      }
    }
  }

  Future<void> deleteUser(int id) async {
    final headers = await getAuthHeaders();
    headers.remove("Content-Type");

    final response = await http.delete(
      Uri.parse("$baseUrl/users/$id"),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to delete user");
    }
  }

  Future<User> registerUser(String nama, String phone, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"), // Ubah endpoint register
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true", // FIX: Tambahkan header
      },
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
      // FIX: Berikan pesan error yang lebih spesifik dari backend
      try {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? "Gagal mendaftar");
      } catch (_) {
        throw Exception("Gagal mendaftar. Status: ${response.statusCode}");
      }
    }
  }

  // Fetch user profile using the token
  Future<User> getUserProfile(String token) async {
    final response = await http.get(
      Uri.parse("$baseUrl/auth/profile"),
      headers: {
        "Authorization": "Bearer $token",
        "ngrok-skip-browser-warning": "true", // FIX: Tambahkan header
      },
    );
    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception("Gagal mengambil profil pengguna: ${response.body}");
    }
  }

  Future<List<Product>> fetchStaffProducts(
    int staffId, {
    Map<String, dynamic>? filters,
  }) async {
    final headers = await getAuthHeaders();
    headers.remove("Content-Type");

    // Bangun URL dengan filter is_active
    // FIX 1: Bangun query string dari map filters
    String filterQuery = '';
    if (filters != null) {
      filters.forEach((key, value) {
        filterQuery += '&$key=$value';
      });
    }

    // Endpoint ini sekarang dapat disaring berdasarkan kepemilikan dan is_active
    final response = await http.get(
      Uri.parse(
        "$baseUrl/products/filter-by-user?user_id=$staffId$filterQuery",
      ),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load staff products: ${response.body}");
    }
  }

  // Menambahkan atau mengupdate produk (perlu endpoint yang menerima Product object)
  Future<Product> saveProduct(Product product, int staffId) async {
    // Tentukan method dan endpoint
    final isUpdate = product.id != 0;
    final url = Uri.parse("$baseUrl/products/${isUpdate ? product.id : ''}");
    final method = isUpdate ? 'PUT' : 'POST';

    // FIX 1: Gunakan MultipartRequest
    final request = http.MultipartRequest(method, url);

    // FIX 2: Tambahkan Authorization Header
    final token = await getAuthToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // FIX 3: Tambahkan field sebagai fields (string)
    request.fields['nama_produk'] = product.namaProduk;
    request.fields['harga'] = product.harga.toString();
    request.fields['kategori_id'] = product.kategoriId.toString();

    // Tambahkan staffId jika diperlukan oleh backend Anda untuk verifikasi
    // Walaupun get_current_user sudah memverifikasi user, terkadang field ini diperlukan
    // request.fields['staff_user_id'] = staffId.toString();

    // FIX 4: Tambahkan gambar Base64 sebagai Form field (jika gambar dikirim sebagai string)
    if (product.gambar != null && product.gambar!.isNotEmpty) {
      request.fields['gambar'] = product.gambar!;
    }

    // Kirim request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception(
        "Gagal ${isUpdate ? 'update' : 'menambah'} produk. Status: ${response.statusCode}. Body: ${response.body}",
      );
    }
  }

  Future<Product> saveProductWithFile({
    required String namaProduk,
    required int harga,
    required int kategoriId,
    required XFile? gambar,
    required Uint8List? imageBytes,
    required String? existingImageUrl,
    required int staffId,
    required bool isUpdate,
    required int productId,
    required bool isActive, // <--- FIX: Tambahkan parameter ini
  }) async {
    String? base64String;

    // 1. Konversi Gambar ke Base64 (jika ada file baru)
    if (gambar != null) {
      Uint8List bytes;
      if (kIsWeb && imageBytes != null) {
        bytes = imageBytes;
      } else if (!kIsWeb) {
        bytes = await io.File(gambar.path).readAsBytes();
      } else {
        throw Exception("File bytes not available for upload.");
      }
      base64String = base64Encode(bytes);
    }

    // Tentukan URL dan method
    final url = Uri.parse("$baseUrl/products/${isUpdate ? productId : ''}");
    final method = isUpdate ? 'PUT' : 'POST';

    // Siapkan payload
    final payload = {
      "nama_produk": namaProduk,
      "harga": harga,
      "kategori_id": kategoriId,
      "gambar": base64String ?? existingImageUrl,
      "is_active": isActive, // <--- FIX: Sertakan isActive di payload
    };

    // Panggil API
    final headers = await getAuthHeaders();
    final response = await (method == 'POST'
        ? http.post(
            url,
            headers: headers,
            body: json.encode(payload..['user_id'] = staffId),
          )
        : http.put(url, headers: headers, body: json.encode(payload)));

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception(
        "Gagal menyimpan produk. Status: ${response.statusCode}. Body: ${response.body}",
      );
    }
  }

  // ================== STAFF ORDER INBOX ==================

  // Mengambil pesanan yang berstatus 'processed' (yang perlu disiapkan staff)
  // Anda harus membuat endpoint baru di FastAPI: GET /orders/staff/inbox
  Future<List<Order>> fetchStaffOrderInbox(int staffId) async {
    final headers = await getAuthHeaders();
    // Backend akan menggunakan token untuk mengidentifikasi staff, jadi staffId tidak perlu dikirim.
    // Cukup panggil endpoint dengan parameter include_items.
    final response = await http.get(
      Uri.parse("$baseUrl/orders/staff/inbox?include_items=true"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception("Gagal memuat inbox pesanan: ${response.body}");
    }
  }

  // Memperbarui status pesanan
  Future<Order> updateOrderStatus(int orderId, String newStatus) async {
    final headers = await getAuthHeaders();
    final response = await http.put(
      Uri.parse("$baseUrl/orders/$orderId/status"),
      headers: headers,
      body: json.encode({"status": newStatus}),
    );

    if (response.statusCode == 200) {
      return Order.fromJson(json.decode(response.body));
    } else {
      throw Exception("Gagal memperbarui status pesanan: ${response.body}");
    }
  }

  // ================== CATEGORIES ==================
  Future<List<Category>> fetchCategories() async {
    final headers = await getAuthHeaders();
    headers.remove("Content-Type");

    final response = await http.get(
      Uri.parse("$baseUrl/categories/"),
      headers: headers,
    );
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
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true", // FIX: Tambahkan header
      },
      body: json.encode({"kategori": kategori}),
    );
    if (response.statusCode == 200) {
      return Category.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to create category");
    }
  }

  // ================== PRODUCTS ==================
  Future<List<Product>> fetchProducts({Map<String, dynamic>? filters}) async {
    final headers = await getAuthHeaders();
    headers.remove("Content-Type");

    String filterQuery = '';
    if (filters != null && filters.isNotEmpty) {
      filterQuery =
          '?' + filters.entries.map((e) => '${e.key}=${e.value}').join('&');
    }

    final response = await http.get(
      // FIX: Tambahkan filter query ke URL
      Uri.parse("$baseUrl/products/$filterQuery"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      try {
        List data = json.decode(response.body);
        return data.map((e) => Product.fromJson(e)).toList();
      } catch (e) {
        throw Exception(
          "Gagal parse JSON pada fetchProducts. Respons: ${response.body.substring(0, 50)}...",
        );
      }
    } else {
      throw Exception(
        "Failed to load products. Status: ${response.statusCode}. Body: ${response.body}",
      );
    }
  }

  Future<List<Product>> fetchProductsByUser(int userId) async {
    final headers = await getAuthHeaders();
    headers.remove("Content-Type");
    final response = await http.get(
      Uri.parse("$baseUrl/products/filter-by-user?user_id=$userId"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Failed to filter products by user");
    }
  }

  Future<Product> createProduct(
    String nama,
    int harga,
    int kategoriId, {
    String? gambar,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/products/"),
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true", // FIX: Tambahkan header
      },
      body: json.encode({
        "nama_produk": nama,
        "harga": harga,
        "kategori_id": kategoriId,
        "gambar": gambar,
      }),
    );
    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to create product");
    }
  }

  Future<void> deleteProduct(int productId) async {
    final headers = await getAuthHeaders();
    final response = await http.delete(
      Uri.parse("$baseUrl/products/$productId"),
      headers: headers,
    );
    if (response.statusCode != 200) {
      // FIX 3: Tambahkan body error untuk debugging
      throw Exception(
        "Gagal menghapus produk. Status: ${response.statusCode}. Body: ${response.body}",
      );
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
    headers.remove("Content-Type");
    final response = await http.get(
      Uri.parse("$baseUrl/carts/"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      try {
        List data = json.decode(response.body);
        return data.map((e) => CartItem.fromJson(e)).toList();
      } catch (e) {
        throw Exception(
          "Gagal parse JSON pada fetchCartItems. Respons: ${response.body.substring(0, 50)}...",
        );
      }
    } else {
      throw Exception(
        "Gagal memuat item keranjang. Status: ${response.statusCode}. Body: ${response.body}",
      );
    }
  }

  Future<void> updateCartItem(
    int cartItemId,
    int productId,
    int newQuantity,
  ) async {
    final headers = await getAuthHeaders();
    final response = await http.put(
      Uri.parse("$baseUrl/carts/$cartItemId"),
      headers: headers,
      body: json.encode({"product_id": productId, "jumlah": newQuantity}),
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
  Future<List<Order>> fetchOrders({bool includeItems = false}) async {
    // includeItems tetap ada, tapi defaultnya false
    final headers = await getAuthHeaders(); // Mengambil token Bearer
    headers.remove("Content-Type");

    // Panggil endpoint /orders/ yang dilindungi oleh token, dengan parameter include_items.
    final url = Uri.parse("$baseUrl/orders?include_items=$includeItems");
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      // Tambahkan detail body untuk debugging yang lebih baik
      throw Exception("Failed to load orders: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getSnapTokenForOrder({
    required int orderId,
    required List<int> cartIds,
    required int userId,
  }) async {
    final headers = await getAuthHeaders();

    final response = await http.post(
      Uri.parse("$baseUrl/payments/snap-token"),
      headers: headers,
      body: json.encode({
        "order_id_exists": orderId, // FIX: Kirim Order ID yang sudah ada
        "cart_ids": cartIds,
        "user_id": userId, // Tetap kirim userId
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        "Gagal mendapatkan Snap Token. Status: ${response.statusCode}. Body: ${response.body}",
      );
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

  Future<Payment> createPayment(
    int orderId,
    String metode,
    double jumlah,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/payments/"),
      headers: {
        "Content-Type": "application/json",
        "ngrok-skip-browser-warning": "true", // FIX: Tambahkan header
      },
      body: json.encode({
        "order_id": orderId,
        "metode_pembayaran": metode,
        "jumlah_pembayaran": jumlah,
        "status_pembayaran": "pending",
      }),
    );
    if (response.statusCode == 200) {
      return Payment.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to create payment");
    }
  }

  Future<List<OrderItem>> fetchOrderItemsByOrderId(int orderId) async {
    final headers = await getAuthHeaders();
    headers.remove("Content-Type");
    final response = await http.get(
      Uri.parse("$baseUrl/orders/$orderId/items"),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => OrderItem.fromJson(e)).toList();
    } else {
      throw Exception("Gagal memuat item pesanan: ${response.body}");
    }
  }

  // ================== PAYMENTS ==================

  Future<Map<String, dynamic>> getSnapToken(List<int> cartIds) async {
    final headers = await getAuthHeaders();
    if (_currentUserId == null) {
      _currentUserId = await getUserId();
    }
    final response = await http.post(
      Uri.parse("$baseUrl/payments/snap-token"),
      headers: headers,
      body: json.encode({"user_id": _currentUserId, "cart_ids": cartIds}),
    );

    if (response.statusCode == 200) {
      try {
        return json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw Exception(
          "Gagal parse SNAP token JSON. Respons: ${response.body.substring(0, 50)}...",
        );
      }
    } else {
      throw Exception(
        "Gagal mendapatkan snap token. Status: ${response.statusCode}. Body: ${response.body}",
      );
    }
  }

  Future<List<Payment>> fetchPaymentsByOrderId(int orderId) async {
    final headers = await getAuthHeaders();
    headers.remove("Content-Type");
    final response = await http.get(
      // FIX: Panggil endpoint yang benar untuk mengambil pembayaran berdasarkan ID pesanan.
      Uri.parse("$baseUrl/payments/by-order/$orderId"),
      headers: headers,
    );
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => Payment.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load payments");
    }
  }
}
