// file: lib/widgets/custom_app_bar.dart

import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget> actions;
  final Color backgroundColor;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.actions,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: preferredSize.height, // Gunakan tinggi dari preferredSize
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(50),
            bottomRight: Radius.circular(50),
            topRight: Radius.circular(5),
            topLeft: Radius.circular(5)
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
         child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0), // <-- Atur margin di sini
          child: AppBar(
            title: title,
            actions: actions,
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            // 2. Hapus titleSpacing karena sudah diatur oleh Padding di atasnya
            titleSpacing: 0, 
          ),
        ),
      ),
    );
  }


  @override
  // PERBAIKAN 3: Tambah tinggi AppBar agar simetris dengan lengkungan
  Size get preferredSize => const Size.fromHeight(60.0); 
}