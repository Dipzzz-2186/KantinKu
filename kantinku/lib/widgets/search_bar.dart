import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final Function(String) onSearch;

  const SearchBarWidget({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onSearch,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: "Cari produk...",
        border: OutlineInputBorder(),
      ),
    );
  }
}
