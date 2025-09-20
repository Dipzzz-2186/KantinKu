import 'dart:convert';
import 'package:http/http.dart' as http;

// import semua model
import '../models/user_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';
import '../models/payment_model.dart';

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000"; // ganti sesuai server FastAPI kamu

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

  Future<User> createUser(String nama, String noTelp, String role, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "nama_pengguna": nama,
        "nomor_telepon": noTelp,
        "role": role,
        "password": password
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
  Future<List<CartItem>> fetchCartItems(int userId) async {
    final response = await http.get(Uri.parse("$baseUrl/carts/$userId"));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((e) => CartItem.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load cart items");
    }
  }

  Future<CartItem> addToCart(int userId, int productId, int jumlah) async {
    final response = await http.post(
      Uri.parse("$baseUrl/carts/$userId"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"product_id": productId, "jumlah": jumlah}),
    );
    if (response.statusCode == 200) {
      return CartItem.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to add to cart");
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

  Future<Order> createOrder(int userId, double totalHarga) async {
    final response = await http.post(
      Uri.parse("$baseUrl/orders/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"user_id": userId, "status": "pending", "total_harga": totalHarga}),
    );
    if (response.statusCode == 200) {
      return Order.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to create order");
    }
  }

  // ================== ORDER ITEMS ==================
  Future<OrderItem> createOrderItem(int orderId, int productId, int jumlah, double hargaUnit) async {
    final response = await http.post(
      Uri.parse("$baseUrl/order_items/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "order_id": orderId,
        "product_id": productId,
        "jumlah": jumlah,
        "harga_unit": hargaUnit,
        "subtotal": jumlah * hargaUnit
      }),
    );
    if (response.statusCode == 200) {
      return OrderItem.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to create order item");
    }
  }

  // ================== PAYMENTS ==================
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
