// file: lib/widgets/search_bar.dart

import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final Function(String) onSearch;

  const SearchBarWidget({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    // 1. Bungkus dengan Container untuk memberikan bayangan (shadow) dan radius
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Warna dasar search bar
        borderRadius: BorderRadius.circular(30.0), // Radius untuk bentuk kapsul
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 50,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        onChanged: onSearch,
        decoration: InputDecoration(
          // 2. Atur padding internal agar tidak terlalu tinggi
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),

          // 3. Ikon pencarian di sebelah kiri
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          
          // 4. Teks placeholder
          hintText: "Cari produk...",
          hintStyle: const TextStyle(color: Colors.grey),

          // 5. Hilangkan semua border agar terlihat menyatu
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
      ),
    );
  }
}